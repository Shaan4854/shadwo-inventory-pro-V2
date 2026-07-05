import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/ui_kit/ui_kit.dart';
import 'backup_restore_screen.dart';

/// Settings screen. Currently hosts the appearance (light/dark/system)
/// selector and a Backup & Restore tile under Data.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    return DecoratedBox(
      decoration: BoxDecoration(gradient: ShadowColors.pageBackground),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: ShadowColors.foreground),
          title: Text('Settings', style: ShadowTextStyles.h4),
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(
              ShadowTheme.screenPaddingH,
              8,
              ShadowTheme.screenPaddingH,
              32,
            ),
            children: [
              const ShadowSectionLabel('Appearance'),
              const SizedBox(height: 12),
              ShadowCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                child: Column(
                  children: [
                    _ModeTile(
                      icon: Icons.light_mode_rounded,
                      title: 'Light',
                      subtitle: 'Bright, high-contrast surfaces',
                      selected: controller.mode == AppThemeMode.light,
                      onTap: () => controller.setMode(AppThemeMode.light),
                    ),
                    _ModeTile(
                      icon: Icons.dark_mode_rounded,
                      title: 'Dark',
                      subtitle: 'Deep navy glass — easy on the eyes',
                      selected: controller.mode == AppThemeMode.dark,
                      onTap: () => controller.setMode(AppThemeMode.dark),
                    ),
                    _ModeTile(
                      icon: Icons.brightness_auto_rounded,
                      title: 'System',
                      subtitle: 'Follow your device setting',
                      selected: controller.mode == AppThemeMode.system,
                      onTap: () => controller.setMode(AppThemeMode.system),
                      showDivider: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  controller.mode == AppThemeMode.system
                      ? 'Currently showing ${controller.isDark ? 'dark' : 'light'} to match your device.'
                      : 'You can also tap the sun/moon icon in any screen header to switch instantly.',
                  style: ShadowTextStyles.bodyMuted.copyWith(fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),
              const ShadowSectionLabel('Data'),
              const SizedBox(height: 12),
              ShadowCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                child: _ActionTile(
                  icon: Icons.backup_rounded,
                  title: 'Backup & Restore',
                  subtitle: 'Export or import your database',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BackupRestoreScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: ShadowColors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(ShadowTheme.radiusMd),
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? ShadowColors.primary.withValues(alpha: 0.16)
                          : ShadowColors.muted,
                      border: Border.all(
                        color: selected
                            ? ShadowColors.primary.withValues(alpha: 0.5)
                            : ShadowColors.border,
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: selected
                          ? ShadowColors.primary
                          : ShadowColors.mutedForeground,
                    ),
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
                          style: ShadowTextStyles.bodyMuted.copyWith(
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedScale(
                    scale: selected ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 22,
                      color: ShadowColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: ShadowColors.border.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  }
}
