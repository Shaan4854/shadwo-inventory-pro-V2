import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../models/product.dart';
import '../../models/transaction_type.dart';
import '../../providers/category_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/ui_kit/ui_kit.dart';
import '../_shared/cart_state.dart';

class _Selected<T> {
  final T value;
  const _Selected(this.value);
}

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> with WidgetsBindingObserver {
  final _cart = CartState();
  final _searchCtrl = TextEditingController();
  String _search = '';
  String? _categoryFilter;

  /// Guards the stagger animation — set to false after first build so
  /// search/filter rebuilds don't replay it.
  bool _firstBuild = true;

  // ─── Scan mode ──────────────────────────────────────────────────────
  bool _scanMode = false;
  MobileScannerController? _scannerCtrl;
  bool _scanFrozen = false;
  bool _scanStarting = false;
  bool _scanPermanentlyDenied = false;
  String? _scanError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerCtrl?.dispose();
    _cart.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _scanMode &&
        (_scanError != null || _scanPermanentlyDenied)) {
      _checkScanPermission();
    }
  }

  void _toggleScanMode() {
    setState(() => _scanMode = !_scanMode);
    if (_scanMode) {
      _scannerCtrl = MobileScannerController(
        autoZoom: true,
        torchEnabled: false,
        returnImage: false,
      );
      _checkScanPermission();
    } else {
      _scannerCtrl?.dispose();
      _scannerCtrl = null;
      _scanError = null;
      _scanPermanentlyDenied = false;
    }
  }

  // Only checks/requests camera permission — the MobileScanner widget
  // auto-starts the controller itself once it's built and attached.
  void _retryScanner() {
    setState(() => _scanStarting = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scannerCtrl?.dispose();
      _scannerCtrl = MobileScannerController(
        autoZoom: true,
        torchEnabled: false,
        returnImage: false,
      );
      _scanError = null;
      _scanPermanentlyDenied = false;
      _checkScanPermission();
    });
  }

  Future<void> _checkScanPermission() async {
    setState(() {
      _scanStarting = true;
      _scanError = null;
      _scanPermanentlyDenied = false;
    });

    final status = await Permission.camera.request();
    if (!mounted) return;

    if (!status.isGranted) {
      setState(() {
        _scanStarting = false;
        _scanPermanentlyDenied = status.isPermanentlyDenied;
        _scanError = status.isPermanentlyDenied
            ? 'Camera permission permanently denied. Enable it in Settings.'
            : 'Camera permission is required to scan barcodes.';
      });
      return;
    }

    setState(() => _scanStarting = false);
  }

  void _onScanDetect(BarcodeCapture capture) {
    if (_scanFrozen) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;
    _scanFrozen = true;
    _handleScannedBarcode(raw);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted && _scanMode) setState(() => _scanFrozen = false);
    });
  }

  Future<void> _handleScannedBarcode(String value) async {
    try {
      final products = context.read<ProductProvider>();
      final match = await products.findByBarcode(value);
      if (!mounted) return;

      if (match == null) {
        _snack('Product not found for barcode $value');
        return;
      }

      final live = products.byId(match.id) ?? match;
      final existing = _cart.line(live.id);
      final next = (existing?.quantity ?? 0) + 1;
      if (next > live.stock) {
        _snack('Only ${live.stock} in stock');
        return;
      }
      HapticFeedback.lightImpact();
      _cart.addOrIncrement(live);
      _showTopToast('Added ${live.name}');
    } catch (e) {
      _snack('Scan lookup failed: $e');
      if (mounted) setState(() => _scanFrozen = false);
    }
  }

  // Floats near the top of the screen instead of the default bottom
  // SnackBar, so it doesn't sit over the scanner/cart while scanning.
  void _showTopToast(String msg) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: ShadowColors.card,
              borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: ShadowColors.accentSage, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    msg,
                    style: ShadowTextStyles.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () {
      entry.remove();
    });
  }

  Iterable<Product> _filter(List<Product> all) {
    Iterable<Product> out = all;
    if (_categoryFilter != null) {
      out = out.where((p) => p.category == _categoryFilter);
    }
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase().trim();
      out = out.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.brand.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q) ||
          p.barcode.toLowerCase().contains(q));
    }
    return out.where((p) => p.isActive && p.stock > 0);
  }

  Future<void> _checkout() async {
    if (_cart.lines.isEmpty) return;
    if (!mounted) return;
    final result = await ShadowBottomSheet.show<_PaymentResult>(
      context: context,
      title: 'Payment',
      child: _PaymentSheet(
        total: _cart.total,
        subtotal: _cart.subtotal,
        initialDiscount: _cart.discount,
        initialTax: _cart.tax,
        customer: _cart.customer,
      ),
    );
    if (result == null || !mounted) return;
    final entityName = result.customer?.name ?? _cart.customerName;
    _cart.setCustomer(result.customer);
    final products = context.read<ProductProvider>();
    final txns = context.read<TransactionProvider>();
    final customers = context.read<CustomerProvider>();
    try {
      for (final l in _cart.lines) {
        final live = products.byId(l.product.id);
        if (live == null) {
          _snack('${l.product.name} no longer available');
          return;
        }
        if (l.quantity > live.stock) {
          _snack('Only ${live.stock} ${live.unit} of ${live.name} in stock');
          return;
        }
      }
      final drafts = [
        for (final l in _cart.lines)
          makeItemDraft(
            productId: l.product.id,
            productName: l.product.name,
            productEmoji: l.product.emoji,
            productImagePath: l.product.imagePath,
            productUnit: l.product.unit,
            quantity: l.quantity,
            priceAtTime: l.unitPrice,
            costPriceAtTime: l.product.buyPrice,
          ),
      ];
      await txns.createTransaction(
            type: TransactionType.sale,
            items: drafts,
            discount: result.discount,
            taxAmount: result.tax,
            paymentMethod: result.method,
            paidAmount: result.paidAmount,
            entityId: result.customer?.id ?? '',
            entityName: entityName.isEmpty ? 'Walk-in' : entityName,
            movementReason: 'Sale',
          );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      await Future.wait([
        products.load(),
        customers.load(),
      ]);
      if (!mounted) return;
      _showSaleComplete(result, entityName);
      _cart.clear();
    } catch (e) {
      if (mounted) _snack('Sale failed: $e');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showSaleComplete(_PaymentResult result, String entityName) {
    final computedTotal =
        (_cart.subtotal - result.discount + result.tax).clamp(0, double.infinity);
    final change = result.paidAmount - computedTotal;
    final receipt = _buildReceiptText(result, entityName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ShadowColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ShadowTheme.radiusLg)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: ShadowColors.accentSage, size: 24),
            const SizedBox(width: 8),
            Text('Sale Complete', style: ShadowTextStyles.h4),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total: ${Formatters.currency(computedTotal)}', style: ShadowTextStyles.h3),
              const SizedBox(height: 4),
              Text(
                change > 0.001
                    ? 'Paid: ${Formatters.currency(result.paidAmount)} · Change: ${Formatters.currency(change)}'
                    : 'Paid: ${Formatters.currency(result.paidAmount)}',
                style: ShadowTextStyles.bodyMuted,
              ),
              const SizedBox(height: 4),
              Text('Payment: ${result.method}', style: ShadowTextStyles.bodyMuted),
              const SizedBox(height: 16),
              ShadowButton(
                label: 'Share on WhatsApp',
                icon: Icons.chat_rounded,
                expand: true,
                onPressed: () => _shareReceipt('whatsapp://send?text=${Uri.encodeComponent(receipt)}'),
              ),
              const SizedBox(height: 8),
              ShadowButton(
                label: 'Share via...',
                icon: Icons.share_rounded,
                variant: ShadowButtonVariant.secondary,
                expand: true,
                onPressed: () => _shareReceipt('share'),
              ),
            ],
          ),
        ),
        actions: [
          ShadowButton(
            label: 'Done',
            variant: ShadowButtonVariant.ghost,
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  String _buildReceiptText(_PaymentResult result, String entityName) {
    final buf = StringBuffer();
    final computedTotal = (_cart.subtotal - result.discount + result.tax)
        .clamp(0, double.infinity);
    buf.writeln('*Shadow Inventory*');
    buf.writeln('${DateTime.now().toLocal()}');
    buf.writeln('---');
    for (final l in _cart.lines) {
      final lineDisc = l.discount > 0 ? ' (disc ${Formatters.currency(l.discount)})' : '';
      buf.writeln('${l.product.emoji} ${l.product.name} × ${l.quantity} = ${Formatters.currency(l.lineTotal)}$lineDisc');
    }
    buf.writeln('---');
    if (result.discount > 0) buf.writeln('Discount: -${Formatters.currency(result.discount)}');
    if (result.tax > 0) buf.writeln('Tax: ${Formatters.currency(result.tax)}');
    buf.writeln('*Total: ${Formatters.currency(computedTotal)}*');
    buf.writeln('Paid: ${Formatters.currency(result.paidAmount)} via ${result.method}');
    final change = result.paidAmount - computedTotal;
    if (change > 0.001) {
      buf.writeln('Change: ${Formatters.currency(change)}');
    }
    buf.writeln('Customer: ${entityName.isEmpty ? "Walk-in" : entityName}');
    return buf.toString();
  }

  void _shareReceipt(String url) async {
    if (url == 'share') {
      final text = _buildReceiptText(
        _PaymentResult(
          discount: _cart.discount,
          tax: _cart.tax,
          method: '',
          paidAmount: _cart.total,
          customer: _cart.customer,
        ),
        _cart.customerName,
      );
      await Clipboard.setData(ClipboardData(text: text));
      _snack('Receipt copied to clipboard');
    } else {
      try {
        await Process.run('start', [url], runInShell: true);
      } catch (_) {
        _snack('Could not open WhatsApp. Receipt copied to clipboard.');
        await Clipboard.setData(ClipboardData(text: _buildReceiptText(
          _PaymentResult(
            discount: _cart.discount,
            tax: _cart.tax,
            method: '',
            paidAmount: _cart.total,
            customer: _cart.customer,
          ),
          _cart.customerName,
        )));
      }
    }
  }

  Future<void> _holdCart() async {
    final snap = _cart.toSnapshot();
    HeldCartStore.hold(snap);
    _cart.clear();
    _snack('Cart held. You can resume it later.');
  }

  Future<void> _resumeCart(int index) async {
    final snap = HeldCartStore.resume(index);
    if (snap == null) return;
    final products = context.read<ProductProvider>().all;
    final customers = context.read<CustomerProvider>().all;
    _cart.restoreFromSnapshot(snap, products, customers: customers);
    _snack('Cart restored');
  }

  void _showHeldCarts() {
    if (HeldCartStore.count == 0) {
      _snack('No held carts');
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ShadowColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ShadowTheme.radiusLg)),
        title: Text('Held Carts', style: ShadowTextStyles.h4),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: HeldCartStore.count,
            itemBuilder: (_, i) {
              final snap = HeldCartStore.all[i];
              final heldAt = snap['_heldAt'] as String? ?? '';
              final lines = (snap['lines'] as List).length;
              return ListTile(
                title: Text('$lines items'),
                subtitle: Text(heldAt.isNotEmpty ? heldAt.substring(0, 16).replaceAll('T', ' ') : ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restore_rounded, size: 20),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _resumeCart(i);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: ShadowColors.destructive,
                      onPressed: () {
                        HeldCartStore.discard(i);
                        Navigator.pop(ctx);
                        _showHeldCarts();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          ShadowButton(
            label: 'Close',
            variant: ShadowButtonVariant.ghost,
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomer() async {
    final customers = context.read<CustomerProvider>().all;
    final selected = await ShadowBottomSheet.list<_Selected<Customer?>>(
      context: context,
      title: 'Customer',
      items: [
        const ShadowSheetItem(
          label: 'Walk-in customer',
          value: _Selected<Customer?>(null),
          icon: Icons.person_outline_rounded,
        ),
        for (final c in customers)
          ShadowSheetItem(
            label: c.name,
            value: _Selected<Customer?>(c),
            icon: Icons.person_rounded,
          ),
      ],
    );
    if (selected == null) return;
    if (!mounted) return;
    _cart.setCustomer(selected.value);
  }

  @override
  Widget build(BuildContext context) {
    final isFirst = _firstBuild;
    if (_firstBuild) _firstBuild = false;

    return Consumer2<ProductProvider, CategoryProvider>(
      builder: (context, products, catProvider, _) {
        final cats = catProvider.all;
        final filtered = _filter(products.all).toList();
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              ShadowPageHeader(
                title: 'Sell',
                subtitle: _scanMode ? 'Scan to add items' : 'Point of sale',
                trailing: IconButton(
                  icon: Icon(
                    _scanMode
                        ? Icons.list_alt_rounded
                        : Icons.qr_code_scanner_rounded,
                    color: ShadowColors.foreground,
                  ),
                  tooltip: _scanMode ? 'Back to list' : 'Scan barcode',
                  splashRadius: 20,
                  onPressed: _toggleScanMode,
                ),
              ),
              if (_scanMode) ...[
                // ─── Scanner (top half) ───────────────────────────────
                Expanded(child: _buildScanner()),
                const SizedBox(height: 8),
                // ─── Scanned items / cart (bottom half) ───────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _CartPanel(
                      cart: _cart,
                      onCheckout: _checkout,
                      onHold: _holdCart,
                      onPickCustomer: _pickCustomer,
                      onShowHeldCarts: _showHeldCarts,
                    ),
                  ),
                ),
              ] else ...[
              // ─── Cart (top) ─────────────────────────────────────────
              _CartPanel(
                cart: _cart,
                onCheckout: _checkout,
                onHold: _holdCart,
                onPickCustomer: _pickCustomer,
                onShowHeldCarts: _showHeldCarts,
              ),
              const SizedBox(height: 8),
              // ─── Product picker (bottom) ─────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ShadowTheme.screenPaddingH,
                ),
                child: ShadowSearchBar(
                  controller: _searchCtrl,
                  hint: 'Search products',
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(height: 10),
              if (cats.isNotEmpty)
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    scrollCacheExtent: ScrollCacheExtent.pixels(500.0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: ShadowTheme.screenPaddingH,
                    ),
                    itemCount: cats.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return ShadowFilterChip(
                          label: 'All',
                          selected: _categoryFilter == null,
                          onTap: () => setState(() => _categoryFilter = null),
                        );
                      }
                      final c = cats[i - 1];
                      return ShadowFilterChip(
                        label: '${c.emoji} ${c.name}',
                        selected: _categoryFilter == c.name,
                        onTap: () => setState(() => _categoryFilter = c.name),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: products.isLoading && products.all.isEmpty
                    ? const SkeletonList.card(count: 4)
                    : filtered.isEmpty
                        ? const ShadowEmptyState(
                            title: 'No products in stock',
                            subtitle:
                                'Nothing available for sale matching your filter.',
                            icon: Icons.storefront_outlined,
                          )
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            scrollCacheExtent: ScrollCacheExtent.pixels(500.0),
                            padding: const EdgeInsets.fromLTRB(
                              ShadowTheme.screenPaddingH,
                              0,
                              ShadowTheme.screenPaddingH,
                              80,
                            ),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final p = filtered[i];
                              final row = RepaintBoundary(
                                child: _PickerRow(
                                  product: p,
                                  inCart: _cart.contains(p.id),
                                  onTap: () {
                                    final live = products.byId(p.id);
                                    if (live == null) return;
                                    final existing = _cart.line(p.id);
                                    final next =
                                        (existing?.quantity ?? 0) + 1;
                                    if (next > live.stock) {
                                      _snack('Only ${live.stock} in stock');
                                      return;
                                    }
                                    _cart.addOrIncrement(p);
                                  },
                                ),
                              );
                              if (!isFirst || i > 8) return row;
                              return ShadowAnimations.staggerItem(index: i, child: row);
                            },
                          ),
              ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildScanner() {
    if (_scanError != null) {
      return _buildScanErrorState();
    }
    if (_scanStarting || _scannerCtrl == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(ShadowTheme.radiusLg),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: ShadowTheme.screenPaddingH,
        ),
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              key: ValueKey(_scannerCtrl),
              controller: _scannerCtrl,
              onDetect: _onScanDetect,
              fit: BoxFit.cover,
              errorBuilder: (context, error) {
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
                            color: Colors.white70, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          error.errorDetails?.message ??
                              error.errorCode.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        if (isRetryable)
                          TextButton.icon(
                            onPressed: _retryScanner,
                            icon: const Icon(Icons.refresh_rounded,
                                color: Colors.white),
                            label: const Text('Retry Scanner',
                                style: TextStyle(color: Colors.white)),
                          ),
                        if (!isRetryable)
                          TextButton(
                            onPressed: _toggleScanMode,
                            child: const Text('Close Scanner',
                                style: TextStyle(color: Colors.white)),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Center(
              child: Container(
                width: 220,
                height: 140,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_scanFrozen)
              Positioned.fill(
                child: Container(
                  color: Colors.black38,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_rounded,
                color: ShadowColors.mutedForeground, size: 40),
            const SizedBox(height: 12),
            Text(
              _scanError ?? 'Unable to start camera.',
              textAlign: TextAlign.center,
              style: ShadowTextStyles.bodyMuted,
            ),
            const SizedBox(height: 16),
            ShadowButton(
              label: _scanPermanentlyDenied
                  ? 'Open Settings'
                  : 'Grant Permission',
              onPressed: _scanPermanentlyDenied
                  ? openAppSettings
                  : _checkScanPermission,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Cart panel ──────────────────────────────────────────────────────

class _CartPanel extends StatefulWidget {
  const _CartPanel({
    required this.cart,
    required this.onCheckout,
    required this.onHold,
    this.onPickCustomer,
    this.onShowHeldCarts,
  });
  final CartState cart;
  final VoidCallback onCheckout;
  final VoidCallback onHold;
  final VoidCallback? onPickCustomer;
  final VoidCallback? onShowHeldCarts;

  @override
  State<_CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<_CartPanel> {
  late final TextEditingController _customerCtrl;

  @override
  void initState() {
    super.initState();
    _customerCtrl = TextEditingController(text: widget.cart.customerName);
    widget.cart.addListener(_onCartChange);
  }

  @override
  void dispose() {
    widget.cart.removeListener(_onCartChange);
    _customerCtrl.dispose();
    super.dispose();
  }

  void _onCartChange() {
    if (_customerCtrl.text != widget.cart.customerName) {
      _customerCtrl.text = widget.cart.customerName;
    }
  }

  void _pickCustomer() => widget.onPickCustomer?.call();

  CartState get cart => widget.cart;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cart,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ShadowTheme.screenPaddingH,
          ),
          child: ShadowCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 18,
                      color: ShadowColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cart · ${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'}',
                      style: ShadowTextStyles.body
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    if (cart.itemCount > 0) ...[
                      TextButton(
                        onPressed: () => widget.onHold(),
                        child: Text(
                          'Hold',
                          style: ShadowTextStyles.body.copyWith(
                            color: ShadowColors.accentWarning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          cart.clear();
                        },
                        child: Text(
                          'Clear',
                          style: ShadowTextStyles.body.copyWith(
                            color: ShadowColors.destructive,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                // Customer selector — type name or pick from list
                SizedBox(
                  height: 36,
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 16,
                        color: ShadowColors.mutedForeground,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _customerCtrl,
                          style:
                              ShadowTextStyles.body.copyWith(fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: 'Walk-in customer',
                            hintStyle: ShadowTextStyles.body.copyWith(
                              fontSize: 13,
                              color: ShadowColors.mutedForeground,
                            ),
                            border: InputBorder.none,
                          ),
                          onChanged: widget.cart.setCustomName,
                        ),
                      ),
                      Material(
                        color:
                            ShadowColors.muted.withValues(alpha: 0.5),
                        borderRadius:
                            BorderRadius.circular(ShadowTheme.radiusSm),
                        child: InkWell(
                          onTap: _pickCustomer,
                          borderRadius:
                              BorderRadius.circular(ShadowTheme.radiusSm),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.arrow_drop_down,
                              size: 18,
                              color: ShadowColors.mutedForeground,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (cart.lines.isEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Add products from the list to start a sale.',
                    style: ShadowTextStyles.bodyMuted,
                  ),
                  if (HeldCartStore.count > 0) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: widget.onShowHeldCarts,
                      icon: const Icon(Icons.restore_rounded, size: 16),
                      label: Text('${HeldCartStore.count} held cart${HeldCartStore.count == 1 ? '' : 's'} — tap to resume'),
                    ),
                  ],
                ] else ...[
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      scrollCacheExtent: ScrollCacheExtent.pixels(500.0),
                      itemCount: cart.lines.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final line = cart.lines[i];
                        return _CartLineRow(
                          line: line,
                          onQty: (v) =>
                              cart.setQuantity(line.product.id, v),
                          onRemove: () => cart.remove(line.product.id),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  const ShadowDivider(),
                  const SizedBox(height: 8),
                  _totalsRow('Subtotal', Formatters.currency(cart.subtotal)),
                  const SizedBox(height: 4),
                  _editableTotalsRow(
                    context,
                    'Discount',
                    cart.discount,
                    cart.setDiscount,
                    isNegative: true,
                  ),
                  const SizedBox(height: 4),
                  _editableTotalsRow(
                    context,
                    'Tax',
                    cart.tax,
                    cart.setTax,
                  ),
                  const SizedBox(height: 6),
                  _totalsRow(
                    'Total',
                    Formatters.currency(cart.total),
                    bold: true,
                  ),
                  const SizedBox(height: 12),
                  ShadowButton(
                    label: 'Checkout',
                    icon: Icons.point_of_sale_rounded,
                    expand: true,
                    onPressed:
                        cart.itemCount == 0 ? null : widget.onCheckout,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _totalsRow(String label, String value, {bool bold = false}) {
    final style = bold
        ? ShadowTextStyles.h4
        : ShadowTextStyles.body
            .copyWith(color: ShadowColors.mutedForeground);
    final valueStyle = bold
        ? ShadowTextStyles.h4.copyWith(color: ShadowColors.primary)
        : ShadowTextStyles.body.copyWith(fontWeight: FontWeight.w600);
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: valueStyle),
      ],
    );
  }

  Widget _editableTotalsRow(
    BuildContext context,
    String label,
    double value,
    ValueChanged<double> onChanged, {
    bool isNegative = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: ShadowTextStyles.body.copyWith(
              color: ShadowColors.mutedForeground,
            ),
          ),
        ),
        GestureDetector(
          onTap: () async {
            final res = await ShadowBottomSheet.show<String>(
              context: context,
              title: 'Edit $label',
              child: _EditValueSheet(
                  initialValue: value, label: label),
            );
            if (res != null) {
              onChanged(double.tryParse(res) ?? 0);
            }
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: ShadowColors.muted,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${isNegative ? '-' : ''}${Formatters.currency(value)}',
              style: ShadowTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: isNegative ? ShadowColors.destructive : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Edit value sheet ─────────────────────────────────────────────────

class _EditValueSheet extends StatefulWidget {
  const _EditValueSheet(
      {required this.initialValue, required this.label});
  final double initialValue;
  final String label;

  @override
  State<_EditValueSheet> createState() => _EditValueSheetState();
}

class _EditValueSheetState extends State<_EditValueSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.initialValue.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShadowInput(
            label: widget.label,
            controller: _ctrl,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
          ),
          const SizedBox(height: 20),
          ShadowButton(
            label: 'Apply',
            expand: true,
            onPressed: () => Navigator.pop(context, _ctrl.text),
          ),
        ],
      ),
    );
  }
}

// ─── Cart line row ────────────────────────────────────────────────────

class _CartLineRow extends StatelessWidget {
  const _CartLineRow({
    required this.line,
    required this.onQty,
    required this.onRemove,
  });
  final CartLine line;
  final ValueChanged<int> onQty;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final live = context.watch<ProductProvider>().byId(line.product.id);
    final maxStock = live?.stock ?? line.product.stock;
    return Row(
      children: [
        line.product.imagePath.isNotEmpty
            ? ClipRRect(
                clipBehavior: Clip.hardEdge,
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  File(line.product.imagePath),
                  width: 28,
                  height: 28,
                  cacheWidth: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Text(line.product.emoji, style: const TextStyle(fontSize: 20)),
                ),
              )
            : Text(line.product.emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                line.product.name,
                style: ShadowTextStyles.body
                    .copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${Formatters.currency(line.unitPrice)} × ${line.quantity}'
                '  =  ${Formatters.currency(line.lineTotal)}',
                style:
                    ShadowTextStyles.bodyMuted.copyWith(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        ShadowQuantityStepper(
          value: line.quantity,
          onChanged: onQty,
          min: 1,
          max: maxStock,
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 18),
          color: ShadowColors.mutedForeground,
          onPressed: onRemove,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

Widget _avatarFallback(Product product) {
  return Container(
    width: 44,
    height: 44,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: ShadowColors.muted,
      borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
    ),
    child: Text(
      product.emoji.isEmpty ? '📦' : product.emoji,
      style: const TextStyle(fontSize: 20),
    ),
  );
}

// ─── Picker row ───────────────────────────────────────────────────────

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.product,
    required this.inCart,
    required this.onTap,
  });
  final Product product;
  final bool inCart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ShadowCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          ClipRRect(
            clipBehavior: Clip.hardEdge,
            borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
            child: product.imagePath.isNotEmpty
                ? Image.file(
                    File(product.imagePath),
                    width: 44,
                    height: 44,
                    cacheWidth: 88,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarFallback(product),
                  )
                : _avatarFallback(product),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  style: ShadowTextStyles.body
                      .copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${Formatters.currency(product.sellPrice)}'
                  '  ·  ${product.stock} ${product.unit}',
                  style:
                      ShadowTextStyles.bodyMuted.copyWith(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (inCart)
            Icon(
              Icons.check_circle_rounded,
              color: ShadowColors.accentSage,
              size: 20,
            )
          else
            Icon(
              Icons.add_circle_outline_rounded,
              color: ShadowColors.primary,
              size: 22,
            ),
        ],
      ),
    );
  }
}

// ─── Payment result + sheet ───────────────────────────────────────────

class _PaymentResult {
  const _PaymentResult({
    required this.method,
    required this.paidAmount,
    required this.discount,
    required this.tax,
    this.customer,
  });
  final String method;
  final double paidAmount;
  final double discount;
  final double tax;
  final Customer? customer;
}

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({
    required this.total,
    required this.subtotal,
    required this.initialDiscount,
    required this.initialTax,
    this.customer,
  });
  final double total;
  final double subtotal;
  final double initialDiscount;
  final double initialTax;
  final Customer? customer;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  late String _method;
  late final TextEditingController _paid;
  late final TextEditingController _discount;
  late final TextEditingController _tax;
  late final ValueNotifier<double> _total;
  Customer? _customer;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    final methods = context.read<SettingsProvider>().settings.paymentMethods;
    _method = methods.isNotEmpty ? methods.first : 'cash';
    _paid =
        TextEditingController(text: widget.total.toStringAsFixed(2));
    _discount = TextEditingController(
        text: widget.initialDiscount.toStringAsFixed(2));
    _tax = TextEditingController(
        text: widget.initialTax.toStringAsFixed(2));
    _total = ValueNotifier(_computeTotal());
    _discount.addListener(_onTotalChanged);
    _tax.addListener(_onTotalChanged);
    _total.addListener(_onTotalChangedForPaid);
  }

  @override
  void dispose() {
    _paid.dispose();
    _discount.removeListener(_onTotalChanged);
    _tax.removeListener(_onTotalChanged);
    _total.removeListener(_onTotalChangedForPaid);
    _discount.dispose();
    _tax.dispose();
    _total.dispose();
    super.dispose();
  }

  double _computeTotal() {
    final d = double.tryParse(_discount.text) ?? 0;
    final t = double.tryParse(_tax.text) ?? 0;
    final res = widget.subtotal - d + t;
    return res < 0 ? 0 : res;
  }

  void _onTotalChanged() {
    _total.value = _computeTotal();
  }

  void _onTotalChangedForPaid() {
    _paid.text = _total.value.toStringAsFixed(2);
  }

  Future<void> _pickCustomer() async {
    final customers = context.read<CustomerProvider>().all;
    final selected = await ShadowBottomSheet.list<_Selected<Customer?>>(
      context: context,
      title: 'Customer',
      items: [
        const ShadowSheetItem(
          label: 'Walk-in customer',
          value: _Selected<Customer?>(null),
          icon: Icons.person_outline_rounded,
        ),
        for (final c in customers)
          ShadowSheetItem(
            label: c.name,
            value: _Selected<Customer?>(c),
            icon: Icons.person_rounded,
          ),
      ],
    );
    if (selected == null) return;
    if (!mounted) return;
    setState(() => _customer = selected.value);
  }

  Widget _buildMethodChip(String m) {
    final selected = _method == m;
    final bg = selected ? ShadowColors.primary : ShadowColors.muted;
    final fg = selected ? ShadowColors.primaryFg : ShadowColors.foreground;
    return GestureDetector(
      onTap: () => setState(() => _method = m),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(ShadowTheme.radiusFull),
          border: Border.all(
            color: selected ? ShadowColors.primary : ShadowColors.border,
            width: 0.5,
          ),
        ),
        child: Text(
          m[0].toUpperCase() + m.substring(1),
          style: ShadowTextStyles.body.copyWith(
            color: fg,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final methods =
        context.watch<SettingsProvider>().settings.paymentMethods;
    final methodsList = methods.isNotEmpty ? methods : ['cash'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<double>(
              valueListenable: _total,
              builder: (_, total, __) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total to pay', style: ShadowTextStyles.caption),
                  Text(
                    Formatters.currency(total),
                    style: ShadowTextStyles.h2
                        .copyWith(color: ShadowColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ShadowInput(
                    label: 'Discount',
                    controller: _discount,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    prefixIcon: Icons.remove_circle_outline_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ShadowInput(
                    label: 'Tax',
                    controller: _tax,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    prefixIcon: Icons.add_circle_outline_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Payment method', style: ShadowTextStyles.caption),
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int i = 0; i < methodsList.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      _buildMethodChip(methodsList[i]),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ShadowInput(
              label: 'Paid amount',
              controller: _paid,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              prefixIcon: Icons.attach_money_rounded,
            ),
            const SizedBox(height: 16),
            Text('Customer', style: ShadowTextStyles.caption),
            const SizedBox(height: 8),
            Material(
              color: ShadowColors.input,
              borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
              child: InkWell(
                onTap: _pickCustomer,
                borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(ShadowTheme.radiusMd),
                    border: Border.all(
                        color: ShadowColors.border, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _customer?.name ?? 'Walk-in customer',
                          style: ShadowTextStyles.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: ShadowColors.mutedForeground,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ShadowButton(
              label: 'Confirm payment',
              expand: true,
              icon: Icons.check_rounded,
              onPressed: () {
                final paid =
                    double.tryParse(_paid.text.trim()) ?? _computeTotal();
                final disc =
                    double.tryParse(_discount.text.trim()) ?? 0;
                final tax = double.tryParse(_tax.text.trim()) ?? 0;
                Navigator.of(context).pop(
                  _PaymentResult(
                    method: _method,
                    paidAmount: paid,
                    discount: disc,
                    tax: tax,
                    customer: _customer,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
