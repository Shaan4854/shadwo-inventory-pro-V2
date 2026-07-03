import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Mobile equivalent of the reference project's `Modal`: a bottom sheet
/// with a title bar + close button + scrollable body. Use this instead
/// of `showDialog`/raw `showModalBottomSheet` for any modal content.
class ShadowBottomSheet {
  ShadowBottomSheet._();

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: isScrollControlled,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: ShadowColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                child: Row(
                  children: <Widget>[
                    Expanded(child: Text(title, style: ShadowTextStyles.h3)),
                    IconButton(
                      icon: const Icon(Icons.close, color: ShadowColors.mutedForeground),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Divider(color: ShadowColors.border.withValues(alpha: 0.3), height: 1),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: builder(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
