import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'shadow_button.dart';

/// Confirm/cancel dialog — use for every destructive action (delete
/// product, delete transaction, etc).
class ShadowConfirmDialog extends StatelessWidget {
  const ShadowConfirmDialog({
    super.key,
    required this.title,
    this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.danger = false,
  });

  final String title;
  final String? message;
  final String confirmText;
  final String cancelText;
  final bool danger;

  /// Shows the dialog. Resolves `true` if confirmed, `false`/`null`
  /// otherwise.
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    String? message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool danger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) => ShadowConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        danger: danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ShadowColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: ShadowTextStyles.h3),
            if (message != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                message!,
                style: const TextStyle(fontSize: 14, color: ShadowColors.mutedForeground),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                ShadowButton(
                  label: cancelText,
                  variant: ShadowButtonVariant.ghost,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                const SizedBox(width: 12),
                ShadowButton(
                  label: confirmText,
                  variant: danger ? ShadowButtonVariant.danger : ShadowButtonVariant.primary,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
