import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit/ui_kit.dart';

class StockAdjustmentScreen extends StatefulWidget {
  const StockAdjustmentScreen({super.key});

  @override
  State<StockAdjustmentScreen> createState() => _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends State<StockAdjustmentScreen> {
  Product? _selected;
  int _delta = 0;
  final _reasonCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickProduct() async {
    final products = context.read<ProductProvider>().all;
    if (products.isEmpty) return;
    final picked = await ShadowBottomSheet.list<Product>(
      context: context,
      title: 'Pick product',
      items: [
        for (final p in products)
          ShadowSheetItem(
            label: '${p.emoji}  ${p.name}  (${p.stock} ${p.unit})',
            value: p,
          ),
      ],
    );
    if (picked != null) setState(() => _selected = picked);
  }

  Future<void> _save() async {
    if (_selected == null || _delta == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a product and set a non-zero delta.')),
      );
      return;
    }

    if (_selected!.stock + _delta < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adjustment would result in negative stock. Clamped to 0.')),
      );
      // We can either clamp here or let the repo throw. 
      // The requirement says "No operation should ever be able to make stock negative 
      // unless it's an explicit stock adjustment set-to-value action."
      // Since this is a delta adjustment, we should probably block it if it goes below 0.
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<ProductProvider>().adjustStock(
            productId: _selected!.id,
            delta: _delta,
            reason: _reasonCtrl.text.trim().isEmpty
                ? 'Manual adjustment'
                : _reasonCtrl.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock adjusted')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: ShadowColors.pageBackground),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: ShadowColors.foreground),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            ShadowTheme.screenPaddingH,
            0,
            ShadowTheme.screenPaddingH,
            24,
          ),
          children: [
            const ShadowPageHeader(
              title: 'Stock Adjustment',
              subtitle: 'Correct on-hand counts (spoilage, miscount, etc.)',
            ),
            const ShadowSectionLabel('Product'),
            const SizedBox(height: 8),
            _ProductPickerField(
              product: _selected,
              onTap: _pickProduct,
            ),
            const SizedBox(height: 20),
            const ShadowSectionLabel('Delta'),
            const SizedBox(height: 8),
            _DeltaCard(
              delta: _delta,
              onChanged: (v) => setState(() => _delta = v),
              currentStock: _selected?.stock ?? 0,
            ),
            const SizedBox(height: 20),
            ShadowInput(
              label: 'Reason (optional)',
              controller: _reasonCtrl,
              hint: 'e.g. Damaged, Recount',
            ),
            const SizedBox(height: 24),
            ShadowButton(
              label: 'Apply adjustment',
              icon: Icons.check_rounded,
              expand: true,
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductPickerField extends StatelessWidget {
  const _ProductPickerField({required this.product, required this.onTap});
  final Product? product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ShadowCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ShadowColors.muted,
              borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
            ),
            child: Text(
              product?.emoji ?? '📦',
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product?.name ?? 'Choose a product',
                  style: ShadowTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: product == null
                        ? ShadowColors.mutedForeground
                        : ShadowColors.foreground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (product != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${product!.stock} ${product!.unit} on hand',
                    style: ShadowTextStyles.bodyMuted.copyWith(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: ShadowColors.mutedForeground),
        ],
      ),
    );
  }
}

class _DeltaCard extends StatefulWidget {
  const _DeltaCard({
    required this.delta,
    required this.onChanged,
    required this.currentStock,
  });
  final int delta;
  final ValueChanged<int> onChanged;
  final int currentStock;

  @override
  State<_DeltaCard> createState() => _DeltaCardState();
}

class _DeltaCardState extends State<_DeltaCard> {
  late final TextEditingController _c;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.delta.toString());
  }

  @override
  void didUpdateWidget(covariant _DeltaCard old) {
    super.didUpdateWidget(old);
    // Only sync from parent if the numeric value actually changed
    // AND the current text isn't a partial input (like just a minus sign).
    final currentVal = int.tryParse(_c.text);
    if (widget.delta != currentVal && _c.text != '-') {
      _c.text = widget.delta.toString();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resulting = widget.currentStock + widget.delta;
    final resultingStr = resulting < 0 ? '0 (clamped)' : '$resulting';
    return ShadowCard(
      child: Column(
        children: [
          Row(
            children: [
              _BumpButton(
                icon: Icons.remove_rounded,
                onTap: () => widget.onChanged(widget.delta - 1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _c,
                  textAlign: TextAlign.center,
                  style: ShadowTextStyles.h2,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                  ],
                  onChanged: (v) {
                    if (v == '-') return;
                    widget.onChanged(int.tryParse(v) ?? 0);
                  },
                  decoration: const InputDecoration(
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _BumpButton(
                icon: Icons.add_rounded,
                onTap: () => widget.onChanged(widget.delta + 1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'New on-hand: $resultingStr',
            style: ShadowTextStyles.bodyMuted,
          ),
        ],
      ),
    );
  }
}

class _BumpButton extends StatelessWidget {
  const _BumpButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ShadowColors.muted,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: ShadowColors.foreground, size: 20),
        ),
      ),
    );
  }
}
