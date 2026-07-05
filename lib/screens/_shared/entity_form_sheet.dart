import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../models/supplier.dart';
import '../../providers/customer_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit/ui_kit.dart';

enum EntityKind { customer, supplier }

/// Add/edit form for a customer OR supplier. Same fields either way,
/// distinguished by `kind` — cheaper than shipping two nearly-identical
/// screens.
class EntityFormSheet extends StatefulWidget {
  const EntityFormSheet({
    super.key,
    required this.kind,
    this.customer,
    this.supplier,
  });
  final EntityKind kind;
  final Customer? customer;
  final Supplier? supplier;

  bool get isEdit => customer != null || supplier != null;

  @override
  State<EntityFormSheet> createState() => _EntityFormSheetState();
}

class _EntityFormSheetState extends State<EntityFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _contactPerson; // supplier only
  late final TextEditingController _mobile;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _gstVat;
  late final TextEditingController _notes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    final s = widget.supplier;
    _name = TextEditingController(text: c?.name ?? s?.name ?? '');
    _contactPerson = TextEditingController(text: s?.contactPerson ?? '');
    _mobile = TextEditingController(text: c?.mobile ?? s?.mobile ?? '');
    _email = TextEditingController(text: c?.email ?? s?.email ?? '');
    _address = TextEditingController(text: c?.address ?? s?.address ?? '');
    _gstVat = TextEditingController(text: c?.gstVat ?? s?.gstVat ?? '');
    _notes = TextEditingController(text: c?.notes ?? s?.notes ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _contactPerson.dispose();
    _mobile.dispose();
    _email.dispose();
    _address.dispose();
    _gstVat.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (widget.kind == EntityKind.customer) {
        final provider = context.read<CustomerProvider>();
        if (widget.customer == null) {
          await provider.addCustomer(
            name: _name.text.trim(),
            mobile: _mobile.text.trim(),
            email: _email.text.trim(),
            address: _address.text.trim(),
            gstVat: _gstVat.text.trim(),
            notes: _notes.text.trim(),
          );
        } else {
          await provider.updateCustomer(
            widget.customer!.copyWith(
              name: _name.text.trim(),
              mobile: _mobile.text.trim(),
              email: _email.text.trim(),
              address: _address.text.trim(),
              gstVat: _gstVat.text.trim(),
              notes: _notes.text.trim(),
              updatedAt: DateTime.now(),
            ),
          );
        }
      } else {
        final provider = context.read<SupplierProvider>();
        if (widget.supplier == null) {
          await provider.addSupplier(
            name: _name.text.trim(),
            contactPerson: _contactPerson.text.trim(),
            mobile: _mobile.text.trim(),
            email: _email.text.trim(),
            address: _address.text.trim(),
            gstVat: _gstVat.text.trim(),
            notes: _notes.text.trim(),
          );
        } else {
          await provider.updateSupplier(
            widget.supplier!.copyWith(
              name: _name.text.trim(),
              contactPerson: _contactPerson.text.trim(),
              mobile: _mobile.text.trim(),
              email: _email.text.trim(),
              address: _address.text.trim(),
              gstVat: _gstVat.text.trim(),
              notes: _notes.text.trim(),
              updatedAt: DateTime.now(),
            ),
          );
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSupplier = widget.kind == EntityKind.supplier;
    final title = isSupplier
        ? (widget.isEdit ? 'Edit supplier' : 'Add supplier')
        : (widget.isEdit ? 'Edit customer' : 'Add customer');
    return DecoratedBox(
      decoration: BoxDecoration(gradient: ShadowColors.pageBackground),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: ShadowColors.foreground),
          title: Text(title),
          titleTextStyle: ShadowTextStyles.h4,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              ShadowTheme.screenPaddingH,
              8,
              ShadowTheme.screenPaddingH,
              120,
            ),
            children: [
              ShadowInput(
                label: 'Name',
                controller: _name,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              if (isSupplier) ...[
                const SizedBox(height: 14),
                ShadowInput(
                  label: 'Contact person',
                  controller: _contactPerson,
                ),
              ],
              const SizedBox(height: 14),
              ShadowInput(
                label: 'Mobile',
                controller: _mobile,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_rounded,
              ),
              const SizedBox(height: 14),
              ShadowInput(
                label: 'Email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 14),
              ShadowInput(
                label: 'Address',
                controller: _address,
                maxLines: 2,
                minLines: 1,
              ),
              const SizedBox(height: 14),
              ShadowInput(label: 'GST / VAT', controller: _gstVat),
              const SizedBox(height: 14),
              ShadowInput(
                label: 'Notes',
                controller: _notes,
                maxLines: 4,
                minLines: 2,
              ),
              const SizedBox(height: 20),
              ShadowButton(
                label: widget.isEdit ? 'Save changes' : 'Add',
                loading: _saving,
                expand: true,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
