import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/category_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/reports_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../utils/backup_service.dart';
import '../../widgets/ui_kit/ui_kit.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _busy = false;

  Future<void> _onBackup() async {
    setState(() => _busy = true);
    try {
      await BackupService.backup();
      if (!mounted) return;
      _showSuccess('Backup exported successfully');
    } catch (e) {
      if (!mounted) return;
      _showError('Backup failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onRestore() async {
    final path = await BackupService.pickFile();
    if (path == null || !mounted) return;

    final confirmed = await ShadowConfirmDialog.show(
      context,
      title: 'Restore Backup?',
      message: 'This will replace ALL current data with the backup. '
          'This action cannot be undone.',
      confirmLabel: 'Restore',
      danger: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      final ok = await BackupService.restore(path);
      if (!mounted) return;
      if (!ok) {
        _showError('Invalid backup file');
        return;
      }
      await Future.wait([
        context.read<ProductProvider>().load(),
        context.read<CategoryProvider>().load(),
        context.read<CustomerProvider>().load(),
        context.read<SupplierProvider>().load(),
        context.read<TransactionProvider>().load(),
        context.read<ReportsProvider>().load(),
      ]);
      if (!mounted) return;
      _showSuccess('Data restored successfully');
    } catch (e) {
      if (!mounted) return;
      _showError('Restore failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ShadowColors.destructive,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: ShadowColors.pageBackground),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: ShadowColors.foreground),
          title: Text('Backup & Restore', style: ShadowTextStyles.h4),
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
              const ShadowSectionLabel('Data'),
              const SizedBox(height: 12),
              ShadowCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                child: _ActionTile(
                  icon: Icons.upload_file_rounded,
                  title: 'Backup',
                  subtitle: 'Export your database as a file',
                  busy: _busy,
                  onTap: _busy ? null : _onBackup,
                ),
              ),
              const SizedBox(height: 12),
              ShadowCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                child: _ActionTile(
                  icon: Icons.download_rounded,
                  title: 'Restore',
                  subtitle: 'Import a previous backup — overwrites current data',
                  busy: _busy,
                  onTap: _busy ? null : _onRestore,
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
    required this.busy,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool busy;
  final VoidCallback? onTap;

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
                child: busy
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ShadowColors.primary,
                        ),
                      )
                    : Icon(icon, size: 20, color: ShadowColors.primary),
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
