import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';
import 'shadow_button.dart';

/// Themed confirmation dialog. Use with `showDialog<bool>(...)`; returns
/// `true` on confirm, `false` (or null) on cancel.
class ShadowConfirmDialog extends StatelessWidget {
  const ShadowConfirmDialog({
    super.key,
    required this.title,
    this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.danger = false,
  });

  final String title;
  final String? message;
  final String confirmLabel;
  final String cancelLabel;
  final bool danger;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    String? message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool danger = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ShadowConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        danger: danger,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title, style: ShadowTextStyles.h4),
      content: message == null
          ? null
          : Text(message!, style: ShadowTextStyles.body),
      actionsPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      actions: [
        ShadowButton(
          label: cancelLabel,
          variant: ShadowButtonVariant.ghost,
          size: ShadowButtonSize.sm,
          onPressed: () => Navigator.pop(context, false),
        ),
        ShadowButton(
          label: confirmLabel,
          variant: danger
              ? ShadowButtonVariant.danger
              : ShadowButtonVariant.primary,
          size: ShadowButtonSize.sm,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );
  }
}
