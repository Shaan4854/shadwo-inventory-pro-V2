import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/ui_kit/ui_kit.dart';
import 'product_form_sheet.dart';

// ponytail: default self-hosted URL, change to your server address
const _selfHostedBaseUrl = 'http://localhost:8000';

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _ProductLookup {
  final String name;
  final String brand;
  final String? imageUrl;
  _ProductLookup({
    required this.name,
    required this.brand,
    this.imageUrl,
  });
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late MobileScannerController _scannerCtrl;
  bool _frozen = false;
  bool _starting = true;
  bool _permanentlyDenied = false;
  String? _startError;
  bool _cameraFailed = false;
  final Map<String, _ProductLookup> _lookupCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initController();
    _checkPermission();
  }

  void _initController() {
    _scannerCtrl = MobileScannerController(
      autoZoom: false, // Disabled for better compatibility
      torchEnabled: false,
      returnImage: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.code93,
        BarcodeFormat.qrCode,
        BarcodeFormat.dataMatrix,
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _scannerCtrl.stop();
    } else if (state == AppLifecycleState.resumed) {
      if (_cameraFailed || _startError != null || _permanentlyDenied) {
        _checkPermission();
      } else {
        _scannerCtrl.start();
      }
    }
  }

  // Only checks/requests camera permission here. The MobileScanner widget
  // below (built once permission is granted) starts the controller itself
  // once it attaches - calling controller.start() before that throws.
  Future<void> _checkPermission() async {
    setState(() {
      _starting = true;
      _startError = null;
      _permanentlyDenied = false;
    });

    final status = await Permission.camera.request();
    if (!mounted) return;

    if (!status.isGranted) {
      setState(() {
        _starting = false;
        _permanentlyDenied = status.isPermanentlyDenied;
        _startError = status.isPermanentlyDenied
            ? 'Camera permission permanently denied. Enable it in Settings.'
            : 'Camera permission is required to scan barcodes.';
      });
      return;
    }

    setState(() => _starting = false);
  }

  void _retryCamera() async {
    setState(() {
      _cameraFailed = false;
      _starting = true;
    });
    
    // Small delay to ensure native cleanup
    await Future.delayed(const Duration(milliseconds: 500));
    
    try {
      await _scannerCtrl.dispose();
    } catch (_) {}
    
    _initController();
    _checkPermission();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_frozen) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;
    _frozen = true;
    _lookupBarcode(raw);
  }

  Future<void> _lookupBarcode(String value) async {
    try {
      final provider = context.read<ProductProvider>();
      final match = await provider.findByBarcode(value);
      if (!mounted) return;

      if (match != null) {
        await _showRestockSheet(match, value);
        return;
      }

      final lookup = await _lookupOnline(value);
      if (!mounted) return;

      if (lookup != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ProductFormSheet(
              prefillBarcode: value,
              prefillName: lookup.name,
              prefillBrand: lookup.brand,
              prefillImageUrl: lookup.imageUrl,
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ProductFormSheet(
              prefillBarcode: value,
              noOnlineMatch: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lookup failed: $e')),
        );
        _frozen = false;
        if (mounted) setState(() {});
      }
    }
  }

  Future<_ProductLookup?> _lookupOnline(String barcode) async {
    if (_lookupCache.containsKey(barcode)) return _lookupCache[barcode];

    try {
      final results = await Future.wait([
        _lookupSelfHosted(barcode),
        _lookupOpenFoodFacts(barcode),
        _lookupUpcitemdb(barcode),
      ], eagerError: false);

      for (final r in results) {
        if (r != null) {
          _lookupCache[barcode] = r;
          return r;
        }
      }
    } catch (_) {
    }
    return null;
  }

  Future<_ProductLookup?> _lookupOpenFoodFacts(String barcode) async {
    try {
      final url = Uri.parse(
        'https://world.openfoodfacts.org/api/v2/product/$barcode.json',
      );
      final response =
          await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map?;
      if (json == null || json['status'] != 1) return null;
      final product = json['product'] as Map?;
      if (product == null) return null;
      final name = product['product_name'] as String?;
      if (name == null || name.isEmpty) return null;
      return _ProductLookup(
        name: name,
        brand: (product['brands'] as String?) ?? '',
        imageUrl: product['image_url'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<_ProductLookup?> _lookupUpcitemdb(String barcode) async {
    try {
      final url = Uri.parse(
        'https://api.upcitemdb.com/prod/trial/lookup?upc=$barcode',
      );
      final response =
          await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map?;
      if (json == null || json['code'] != 'OK') return null;
      final items = json['items'] as List?;
      if (items == null || items.isEmpty) return null;
      final item = items.first as Map;
      final title = item['title'] as String?;
      if (title == null || title.isEmpty) return null;
      final images = item['images'] as List?;
      final imageUrl = (images != null && images.isNotEmpty)
          ? images.first as String?
          : null;
      return _ProductLookup(
        name: title,
        brand: (item['brand'] as String?) ?? '',
        imageUrl: imageUrl,
      );
    } catch (_) {
      return null;
    }
  }

  Future<_ProductLookup?> _lookupSelfHosted(String barcode) async {
    try {
      final url = Uri.parse('$_selfHostedBaseUrl/name/$barcode');
      final response =
          await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map?;
      if (json == null) return null;
      final name = json['name'] as String?;
      if (name == null || name.isEmpty) return null;
      return _ProductLookup(name: name, brand: '');
    } catch (_) {
      return null;
    }
  }

  Future<void> _showManualEntry() async {
    if (_frozen) return;
    _frozen = true;
    final ctrl = TextEditingController();
    final result = await ShadowBottomSheet.show<String>(
      context: context,
      title: 'Enter Barcode',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShadowInput(
              label: 'Barcode',
              controller: ctrl,
              autofocus: true,
              hint: 'Type or paste barcode',
            ),
            const SizedBox(height: 20),
            ShadowButton(
              label: 'Look up',
              expand: true,
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
    if (result != null && result.isNotEmpty && mounted) {
      _lookupBarcode(result);
    } else {
      _frozen = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _showRestockSheet(Product product, String barcode) async {
    final provider = context.read<ProductProvider>();
    int quantity = 1;

    final result = await ShadowBottomSheet.show<bool>(
      context: context,
      title: 'Product Found',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(product.emoji.isEmpty ? '📦' : product.emoji,
                        style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            product.name,
                            style: ShadowTextStyles.h4,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Current stock: ${product.stock} ${product.unit}',
                            style: ShadowTextStyles.bodyMuted,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Barcode: $barcode',
                  style: ShadowTextStyles.bodyMuted.copyWith(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text('Restock quantity',
                          style: ShadowTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 12),
                    ShadowQuantityStepper(
                      value: quantity,
                      min: 1,
                      onChanged: (v) =>
                          setSheetState(() => quantity = v),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ShadowButton(
                  label: 'Confirm restock',
                  expand: true,
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (result == true && mounted) {
      try {
        await provider.restock(product.id, quantity);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Restocked ${product.name} (+$quantity)'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Restock failed: $e')),
          );
        }
      }
    }
    _frozen = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.3),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: ShadowColors.foreground),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Scan Barcode',
            style: TextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          if (_startError != null)
            _buildErrorState()
          else if (_starting)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            MobileScanner(
              key: ValueKey(_scannerCtrl.hashCode),
              controller: _scannerCtrl,
              onDetect: _onDetect,
              fit: BoxFit.cover,
              errorBuilder: (context, error) {
                _cameraFailed = true;
                final isRetryable =
                    error.errorCode != MobileScannerErrorCode.permissionDenied &&
                    error.errorCode != MobileScannerErrorCode.unsupported;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.videocam_off_rounded,
                            color: Colors.white70, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          error.errorDetails?.message ??
                              error.errorCode.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 20),
                        if (isRetryable)
                          TextButton.icon(
                            onPressed: _retryCamera,
                            icon: const Icon(Icons.refresh_rounded,
                                color: Colors.white),
                            label: const Text('Retry Camera',
                                style: TextStyle(color: Colors.white)),
                          ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _showManualEntry,
                          icon: Icon(Icons.keyboard_rounded,
                              color: Colors.white.withValues(alpha: 0.7),
                              size: 18),
                          label: Text('Enter barcode manually',
                              style: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.7))),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          if (_startError == null && !_starting)
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  _cornerBracket(Alignment.topLeft),
                  _cornerBracket(Alignment.topRight),
                  _cornerBracket(Alignment.bottomLeft),
                  _cornerBracket(Alignment.bottomRight),
                ],
              ),
            ),
          ),
          if (_startError == null && !_starting)
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Point camera at a barcode',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _showManualEntry,
                  icon: Icon(Icons.keyboard_rounded,
                      color: Colors.white.withValues(alpha: 0.7), size: 18),
                  label: Text(
                    'Enter barcode manually',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ),
              ],
            ),
          ),
          if (_frozen)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_rounded,
                color: Colors.white70, size: 48),
            const SizedBox(height: 16),
            Text(
              _startError ?? 'Unable to start camera.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            ShadowButton(
              label: _permanentlyDenied ? 'Open Settings' : 'Grant Permission',
              onPressed:
                  _permanentlyDenied ? openAppSettings : _checkPermission,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _showManualEntry,
              icon: Icon(Icons.keyboard_rounded,
                  color: Colors.white.withValues(alpha: 0.7), size: 18),
              label: Text(
                'Enter barcode manually',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cornerBracket(Alignment alignment) {
    final isTop = alignment == Alignment.topLeft ||
        alignment == Alignment.topRight;
    final isLeft = alignment == Alignment.topLeft ||
        alignment == Alignment.bottomLeft;
    return Positioned(
      top: isTop ? -2 : null,
      bottom: isTop ? null : -2,
      left: isLeft ? -2 : null,
      right: isLeft ? null : -2,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: Colors.white, width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
