import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import 'shadow_divider.dart';

/// Themed modal bottom sheet. Use `ShadowBottomSheet.show(...)` for a
/// simple title + body sheet; use `ShadowBottomSheet.list(...)` for a
/// list of tappable rows (the "More" menu, sort menus, etc.).
class ShadowBottomSheet {
  ShadowBottomSheet._();

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: ShadowColors.card,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ShadowTheme.radiusXl),
        ),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: ShadowTextStyles.h4,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
              ],
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }

  /// Convenience for a bottom sheet listing tappable rows.
  static Future<T?> list<T>({
    required BuildContext context,
    String? title,
    required List<ShadowSheetItem<T>> items,
  }) {
    return show<T>(
      context: context,
      title: title,
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, __) => const ShadowDivider(
          margin: EdgeInsets.symmetric(horizontal: 20),
        ),
        itemBuilder: (context, i) {
          final item = items[i];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context, item.value),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    if (item.icon != null) ...[
                      Icon(
                        item.icon,
                        size: 20,
                        color: item.destructive
                            ? ShadowColors.destructive
                            : ShadowColors.foreground,
                      ),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Text(
                        item.label,
                        style: ShadowTextStyles.body.copyWith(
                          color: item.destructive
                              ? ShadowColors.destructive
                              : ShadowColors.foreground,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.trailing != null) item.trailing!,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A row inside `ShadowBottomSheet.list(...)`.
class ShadowSheetItem<T> {
  const ShadowSheetItem({
    required this.label,
    required this.value,
    this.icon,
    this.destructive = false,
    this.trailing,
  });

  final String label;
  final T value;
  final IconData? icon;
  final bool destructive;
  final Widget? trailing;
}
