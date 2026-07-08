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
              const SizedBox(height: 12),
              ShadowCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      ShadowButton(
                        label: 'Export Backup',
                        icon: Icons.upload_file_rounded,
                        expand: true,
                        loading: _busy,
                        onPressed: _busy ? null : _onBackup,
                      ),
                      const SizedBox(height: 12),
                      ShadowButton(
                        label: 'Restore Backup',
                        icon: Icons.download_rounded,
                        variant: ShadowButtonVariant.outline,
                        expand: true,
                        loading: _busy,
                        onPressed: _busy ? null : _onRestore,
                      ),
                    ],
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
