import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:http/http.dart' as http;
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
  BarcodeScanner? _scanner;
  CameraController? _cameraController;
  bool _initializing = true;
  bool _processing = false;
  bool _frozen = false;
  Object? _error;
  CameraDescription? _camera;
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  final Map<String, _ProductLookup> _lookupCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanner = BarcodeScanner(formats: [BarcodeFormat.all]);
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanAnimation = Tween<double>(begin: -110, end: 110).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOutSine),
    );
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanController.dispose();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _scanner?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        _initCamera();
      }
    }
  }

  Future<void> _initCamera() async {
    setState(() {
      _initializing = true;
      _error = null;
    });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _initializing = false;
            _error = 'No camera found';
          });
        }
        return;
      }
      _camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(
        _camera!,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      await _cameraController!.startImageStream(_onCameraImage);
      if (mounted) {
        setState(() {
          _initializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initializing = false;
          _error = e.toString();
        });
      }
    }
  }

  void _onCameraImage(CameraImage image) {
    if (_frozen || _processing) return;
    _processing = true;
    _detect(image);
  }

  Future<void> _detect(CameraImage image) async {
    try {
      final inputImage = _buildInputImage(image);
      final scanner = _scanner;
      if (scanner == null) {
        if (mounted) _processing = false;
        return;
      }
      final barcodes = await scanner.processImage(inputImage);
      if (barcodes.isNotEmpty && mounted) {
        final raw = barcodes.first.rawValue;
        if (raw != null && raw.isNotEmpty) {
          _processing = false;
          _onDetected(raw);
          return;
        }
      }
    } catch (e) {
      debugPrint('Barcode detection error: $e');
      if (mounted && _frozen) {
        setState(() {
          _frozen = false;
          _error = 'Scanner error — tap to retry';
        });
        return;
      }
    }
    if (mounted) _processing = false;
  }

  void _onDetected(String value) {
    if (_frozen) return;
    _frozen = true;
    _lookupBarcode(value);
  }

  InputImage _buildInputImage(CameraImage image) {
    final builder = BytesBuilder();
    for (final plane in image.planes) {
      builder.add(plane.bytes);
    }
    final bytes = builder.toBytes();

    final rotation = Platform.isAndroid
        ? (InputImageRotationValue.fromRawValue(_camera!.sensorOrientation) ??
            InputImageRotation.rotation0deg)
        : InputImageRotation.rotation0deg;

    final format =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
            (Platform.isAndroid
                ? InputImageFormat.nv21
                : InputImageFormat.bgra8888);

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  void _unfreezeAndContinue() {
    if (mounted) setState(() => _frozen = false);
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
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ProductFormSheet(prefillBarcode: value),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lookup failed: $e')),
        );
        _unfreezeAndContinue();
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: product.imagePath.isNotEmpty
                            ? Image.file(
                                File(product.imagePath),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _emojiWidget(product.emoji),
                              )
                            : _emojiWidget(product.emoji),
                      ),
                    ),
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
    _unfreezeAndContinue();
  }

  Widget _emojiWidget(String emoji) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ShadowColors.muted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        emoji.isEmpty ? '📦' : emoji,
        style: const TextStyle(fontSize: 22),
      ),
    );
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_initializing) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('Starting camera...',
                style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: ShadowColors.destructive),
              const SizedBox(height: 16),
              const Text('Camera unavailable',
                  style: TextStyle(
                      color: Colors.white, fontSize: 18)),
              const SizedBox(height: 8),
              Text('$_error',
                  style: const TextStyle(color: Colors.white60),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: _initCamera,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Retry',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        CameraPreview(_cameraController!),
        Container(
          color: Colors.black.withValues(alpha: 0.25),
        ),
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
                AnimatedBuilder(
                  animation: _scanAnimation,
                  builder: (_, __) {
                    return Positioned(
                      top: 130 + _scanAnimation.value,
                      left: 2,
                      right: 2,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Colors.transparent,
                            ShadowColors.primary,
                            Colors.transparent,
                          ]),
                        ),
                      ),
                    );
                  },
                ),
                _cornerBracket(Alignment.topLeft),
                _cornerBracket(Alignment.topRight),
                _cornerBracket(Alignment.bottomLeft),
                _cornerBracket(Alignment.bottomRight),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 48,
          left: 0,
          right: 0,
          child: Text(
            'Point camera at a barcode',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ),
      ],
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
