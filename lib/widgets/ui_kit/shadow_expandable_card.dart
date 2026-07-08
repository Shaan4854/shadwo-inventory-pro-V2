import 'package:flutter/material.dart';

import '../../theme/app_animations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

class ShadowExpandableCard extends StatelessWidget {
  const ShadowExpandableCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.isExpanded,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget body;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: ShadowColors.cardSurface,
        borderRadius: BorderRadius.circular(ShadowTheme.radiusLg),
        border: Border.all(
          color: ShadowColors.glassHighlight,
          width: 0.8,
        ),
        boxShadow: ShadowColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(ShadowTheme.radiusLg),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onTap,
          child: AnimatedPadding(
            duration: ShadowAnimations.fast,
            padding: EdgeInsets.fromLTRB(
              8,
              6,
              8,
              isExpanded ? 16 : 6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  icon: icon,
                  title: title,
                  subtitle: subtitle,
                  isExpanded: isExpanded,
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                    child: body,
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: ShadowAnimations.scale,
                  sizeCurve: Curves.easeInOut,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isExpanded,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ShadowColors.primary.withValues(alpha: 0.12),
              border: Border.all(
                color: ShadowColors.primary.withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            child: Icon(icon, size: 20, color: ShadowColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: ShadowTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: ShadowTextStyles.bodyMuted.copyWith(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          AnimatedRotation(
            turns: isExpanded ? 0.5 : 0.0,
            duration: ShadowAnimations.scale,
            curve: Curves.easeInOut,
            child: Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: ShadowColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
