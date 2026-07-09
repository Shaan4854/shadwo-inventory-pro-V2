import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/transaction_type.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';
import 'ui_kit/ui_kit.dart';

class RecordPaymentSheet extends StatefulWidget {
  const RecordPaymentSheet({
    super.key,
    required this.entityId,
    required this.entityName,
    required this.type,
    required this.outstandingBalance,
  });

  final String entityId;
  final String entityName;
  final TransactionType type;
  final double outstandingBalance;

  @override
  State<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<RecordPaymentSheet> {
  final _controller = TextEditingController();
  final _notesController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = _controller.text.trim();
    final amount = double.tryParse(raw);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    final txnProvider = context.read<TransactionProvider>();
    if (amount > widget.outstandingBalance) {
      final proceed = await ShadowConfirmDialog.show(
        context,
        title: 'Amount exceeds balance?',
        message:
            'The outstanding balance is ${Formatters.currency(widget.outstandingBalance)}. '
            'Record this payment anyway?',
        confirmLabel: 'Record Anyway',
      );
      if (!proceed) return;
    }

    setState(() => _saving = true);
    try {
      if (!mounted) return;
      await txnProvider.recordPayment(
            entityId: widget.entityId,
            entityName: widget.entityName,
            amount: amount,
            type: widget.type,
            notes: _notesController.text.trim(),
          );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.type.displayLabel}: ${Formatters.currency(amount)}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ShadowColors.mutedForeground.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.type.displayLabel,
                    style: ShadowTextStyles.h4,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: ShadowColors.mutedForeground,
                  splashRadius: 20,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const ShadowDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              '${widget.entityName} — Outstanding: ${Formatters.currency(widget.outstandingBalance)}',
              style: ShadowTextStyles.bodyMuted,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ShadowInput(
              controller: _controller,
              label: 'Amount',
              hint: '0.00',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              autofocus: true,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ShadowInput(
              controller: _notesController,
              label: 'Notes (optional)',
              hint: 'e.g. partial payment',
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: ShadowButton(
                label: _saving ? 'Recording…' : 'Record Payment',
                variant: ShadowButtonVariant.primary,
                onPressed: _saving ? null : _save,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
