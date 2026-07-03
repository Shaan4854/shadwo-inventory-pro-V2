import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

/// Rounded search input. Fires `onChanged` on every keystroke and shows a
/// clear-button when non-empty.
class ShadowSearchBar extends StatefulWidget {
  const ShadowSearchBar({
    super.key,
    this.controller,
    this.hint = 'Search',
    this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  State<ShadowSearchBar> createState() => _ShadowSearchBarState();
}

class _ShadowSearchBarState extends State<ShadowSearchBar> {
  late final TextEditingController _c =
      widget.controller ?? TextEditingController();
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _c.addListener(_onText);
  }

  void _onText() {
    setState(() {});
  }

  @override
  void dispose() {
    _c.removeListener(_onText);
    if (_ownsController) _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ShadowColors.input,
        borderRadius: BorderRadius.circular(ShadowTheme.radiusFull),
        border: Border.all(color: ShadowColors.border, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: ShadowColors.mutedForeground),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _c,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              style: ShadowTextStyles.body,
              cursorColor: ShadowColors.primary,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: ShadowTextStyles.bodyMuted,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_c.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              color: ShadowColors.mutedForeground,
              splashRadius: 18,
              onPressed: () {
                _c.clear();
                widget.onChanged?.call('');
              },
            ),
        ],
      ),
    );
  }
}
