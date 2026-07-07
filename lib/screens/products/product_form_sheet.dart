import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';
import '../../screens/products/barcode_scan_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../widgets/ui_kit/ui_kit.dart';

/// Add-or-edit product form. Pushed as a full-page route despite the
/// "sheet" name — spec's field count doesn't fit inside a bottom sheet.
///
/// [prefillBarcode] sets the barcode field on launch (from scanner),
/// only meaningful when [editing] is null (add mode).
///
/// [prefillName] and [prefillBrand] are set when the barcode scanner
/// resolved an online lookup so the user doesn't retype them.
class ProductFormSheet extends StatefulWidget {
  const ProductFormSheet({
    super.key,
    this.editing,
    this.prefillBarcode,
    this.prefillName,
    this.prefillBrand,
  });
  final Product? editing;
  final String? prefillBarcode;
  final String? prefillName;
  final String? prefillBrand;

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _emoji;
  late final TextEditingController _brand;
  String _unit = AppConstants.defaultUnit;
  late final TextEditingController _sku;
  late final TextEditingController _barcode;
  late final TextEditingController _notes;
  late final TextEditingController _buyPrice;
  late final TextEditingController _sellPrice;
  late final TextEditingController _stock;
  late final TextEditingController _alertThreshold;
  String? _category;
  String _imagePath = '';
  bool _saving = false;

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final p = widget.editing;
    _name = TextEditingController(
      text: p?.name ?? widget.prefillName ?? '',
    );
    _emoji = TextEditingController(text: p?.emoji ?? '📦');
    _brand = TextEditingController(
      text: p?.brand ?? widget.prefillBrand ?? '',
    );
    _unit = p?.unit ?? AppConstants.defaultUnit;
    _sku = TextEditingController(text: p?.sku ?? '');
    _barcode = TextEditingController(
      text: p?.barcode ?? widget.prefillBarcode ?? '',
    );
    _notes = TextEditingController(text: p?.notes ?? '');
    _buyPrice =
        TextEditingController(text: p == null ? '' : p.buyPrice.toString());
    _sellPrice =
        TextEditingController(text: p == null ? '' : p.sellPrice.toString());
    _stock = TextEditingController(text: p == null ? '' : p.stock.toString());
    _alertThreshold = TextEditingController(
      text: (p?.alertThreshold ?? AppConstants.defaultAlertThreshold)
          .toString(),
    );
    _category = p?.category;
    _imagePath = p?.imagePath ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _emoji.dispose();
    _brand.dispose();
    _sku.dispose();
    _barcode.dispose();
    _notes.dispose();
    _buyPrice.dispose();
    _sellPrice.dispose();
    _stock.dispose();
    _alertThreshold.dispose();
    super.dispose();
  }

  double _asDouble(String s) => double.tryParse(s.trim()) ?? 0;
  int _asInt(String s) => int.tryParse(s.trim()) ?? 0;

  Future<void> _pickUnit() async {
    final result = await ShadowBottomSheet.list<String>(
      context: context,
      title: 'Unit',
      items: [
        for (final u in AppConstants.units)
          ShadowSheetItem(
            label: u,
            value: u,
            icon: _unit == u ? Icons.check_rounded : null,
          ),
        const ShadowSheetItem(
          label: 'Custom…',
          value: 'CUSTOM',
          icon: Icons.edit_outlined,
        ),
      ],
    );
    if (result == 'CUSTOM') {
      if (!mounted) return;
      final custom = await _showAddUnitDialog();
      if (custom != null && custom.isNotEmpty) {
        setState(() => _unit = custom);
      }
    } else if (result != null) {
      setState(() => _unit = result);
    }
  }

  Future<String?> _showAddUnitDialog() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Unit'),
        content: ShadowInput(
          label: 'Unit',
          controller: ctrl,
          autofocus: true,
          hint: 'e.g. dozen',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    ).whenComplete(() => ctrl.dispose());
  }

  void _openScan() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BarcodeScanScreen()),
    );
  }

  Future<void> _showImageSourcePicker() async {
    final source = await ShadowBottomSheet.list<ImageSource>(
      context: context,
      title: 'Product Photo',
      items: const [
        ShadowSheetItem(
          label: 'Take Photo',
          value: ImageSource.camera,
          icon: Icons.camera_alt_outlined,
        ),
        ShadowSheetItem(
          label: 'Choose from Gallery',
          value: ImageSource.gallery,
          icon: Icons.photo_library_outlined,
        ),
      ],
    );
    if (source != null) await _pickImage(source);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _imagePath = picked.path);
      }
    } catch (_) {
      // Silently handle — camera/gallery unavailable or permission denied
    }
  }

  Widget _emojiFallback() {
    return Container(
      width: 100,
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ShadowColors.muted,
        borderRadius: BorderRadius.circular(ShadowTheme.radiusLg),
      ),
      child: Text(
        _emoji.text.trim().isEmpty ? '📦' : _emoji.text.trim(),
        style: const TextStyle(fontSize: 40),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final provider = context.read<ProductProvider>();
      if (_isEdit) {
        final p = widget.editing!.copyWith(
          name: _name.text.trim(),
          emoji: _emoji.text.trim().isEmpty ? '📦' : _emoji.text.trim(),
          brand: _brand.text.trim(),
          unit: _unit,
          sku: _sku.text.trim(),
          barcode: _barcode.text.trim(),
          notes: _notes.text.trim(),
          buyPrice: _asDouble(_buyPrice.text),
          sellPrice: _asDouble(_sellPrice.text),
          alertThreshold: _asInt(_alertThreshold.text),
          category: _category ?? '',
          imagePath: _imagePath,
          updatedAt: DateTime.now(),
        );
        if (p.sellPrice < p.buyPrice) {
          throw Exception('Sell price must be greater than or equal to buy price');
        }
        await provider.updateProduct(p);
        // Stock changes go through adjustStock so the audit log stays honest.
        final live = provider.byId(p.id);
        final liveStock = live?.stock ?? widget.editing!.stock;
        final newStock = _asInt(_stock.text);
        if (newStock != liveStock) {
          await provider.adjustStock(
            productId: p.id,
            delta: newStock - liveStock,
            reason: 'Manual edit',
          );
        }
      } else {
        final buyPrice = _asDouble(_buyPrice.text);
        final sellPrice = _asDouble(_sellPrice.text);
        if (sellPrice < buyPrice) {
          throw Exception('Sell price must be greater than or equal to buy price');
        }
        await provider.addProduct(
          name: _name.text.trim(),
          buyPrice: buyPrice,
          sellPrice: sellPrice,
          stock: _asInt(_stock.text),
          alertThreshold: _asInt(_alertThreshold.text),
          emoji: _emoji.text.trim().isEmpty ? '📦' : _emoji.text.trim(),
          category: _category ?? '',
          brand: _brand.text.trim(),
          unit: _unit.isEmpty ? AppConstants.defaultUnit : _unit,
          sku: _sku.text.trim(),
          barcode: _barcode.text.trim(),
          notes: _notes.text.trim(),
          imagePath: _imagePath,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickCategory() async {
    final categoryProvider = context.read<CategoryProvider>();
    final categories = categoryProvider.all;
    final result = await ShadowBottomSheet.list<String>(
      context: context,
      title: 'Category',
      items: [
        const ShadowSheetItem(
          label: 'Add New Category...',
          value: 'ADD_NEW',
          icon: Icons.add_circle_outline_rounded,
        ),
        for (final c in categories)
          ShadowSheetItem(
            label: '${c.emoji}  ${c.name}',
            value: c.name,
            icon: _category == c.name ? Icons.check_rounded : null,
          ),
      ],
    );

    if (result == 'ADD_NEW') {
      if (!mounted) return;
      final name = await _showAddCategoryDialog();
      if (name != null && name.isNotEmpty) {
        try {
          await categoryProvider.add(name: name);
          setState(() => _category = name);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
          );
        }
      }
    } else if (result != null) {
      setState(() => _category = result);
    }
  }

  Future<String?> _showAddCategoryDialog() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: ShadowInput(
          label: 'Category Name',
          controller: ctrl,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    ).whenComplete(() => ctrl.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration:
          BoxDecoration(gradient: ShadowColors.pageBackground),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: ShadowColors.foreground),
          title: Text(_isEdit ? 'Edit Product' : 'Add Product'),
          titleTextStyle: ShadowTextStyles.h4,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              ShadowTheme.screenPaddingH,
              8,
              ShadowTheme.screenPaddingH,
              120,
            ),
            children: [
              // Product photo — tappable with camera/gallery picker
              GestureDetector(
                onTap: _showImageSourcePicker,
                child: Center(
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(ShadowTheme.radiusLg),
                          child: _imagePath.isNotEmpty
                              ? Image.file(
                                  File(_imagePath),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _emojiFallback(),
                                )
                              : _emojiFallback(),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: ShadowColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: ShadowColors.foreground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ShadowInput(
                label: 'Name',
                controller: _name,
                hint: 'e.g. Wireless Earbuds',
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ShadowInput(
                      label: 'Emoji',
                      controller: _emoji,
                      hint: '📦',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ShadowInput(
                      label: 'Brand',
                      controller: _brand,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _CategoryField(
                value: _category,
                onTap: _pickCategory,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ShadowInput(
                      label: 'Buy price',
                      controller: _buyPrice,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.]'),
                        ),
                      ],
                      prefixIcon: Icons.attach_money_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final val = double.tryParse(v);
                        if (val == null) return 'Invalid';
                        if (val < 0) return 'Min 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShadowInput(
                      label: 'Sell price',
                      controller: _sellPrice,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.]'),
                        ),
                      ],
                      prefixIcon: Icons.attach_money_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final val = double.tryParse(v);
                        if (val == null) return 'Invalid';
                        if (val < 0) return 'Min 0';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ShadowInput(
                      label: 'Stock',
                      controller: _stock,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final val = int.tryParse(v);
                        if (val == null) return 'Invalid';
                        if (val < 0) return 'Min 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShadowInput(
                      label: 'Alert threshold',
                      controller: _alertThreshold,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final n = int.tryParse(v);
                        if (n == null || n < 1) return 'Min 1';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _UnitField(
                      value: _unit,
                      onTap: _pickUnit,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ShadowInput(
                      label: 'SKU',
                      controller: _sku,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShadowInput(
                      label: 'Barcode',
                      controller: _barcode,
                      suffixIcon: IconButton(
                        icon: Icon(Icons.qr_code_scanner_rounded,
                            size: 20,
                            color: ShadowColors.foreground),
                        tooltip: 'Scan barcode',
                        splashRadius: 18,
                        onPressed: _openScan,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ShadowInput(
                label: 'Notes',
                controller: _notes,
                maxLines: 4,
                minLines: 2,
              ),
              const SizedBox(height: 24),
              ShadowButton(
                label: _isEdit ? 'Save changes' : 'Add product',
                loading: _saving,
                expand: true,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnitField extends StatelessWidget {
  const _UnitField({required this.value, required this.onTap});
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Unit', style: ShadowTextStyles.caption),
        const SizedBox(height: 6),
        Material(
          color: ShadowColors.input,
          borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(ShadowTheme.radiusMd),
                border: Border.all(
                  color: ShadowColors.border,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
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
      ],
    );
  }
}

class _CategoryField extends StatelessWidget {
  const _CategoryField({required this.value, required this.onTap});
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style: ShadowTextStyles.caption),
        const SizedBox(height: 6),
        Material(
          color: ShadowColors.input,
          borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(ShadowTheme.radiusMd),
                border: Border.all(
                  color: ShadowColors.border,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value == null || value!.isEmpty
                          ? 'Select a category'
                          : value!,
                      style: value == null || value!.isEmpty
                          ? ShadowTextStyles.bodyMuted
                          : ShadowTextStyles.body,
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
      ],
    );
  }
}
