import 'formatters.dart';
import '../models/transaction.dart';

/// Returns "Walk-in" when [entityName] is empty, otherwise the name itself
/// in Title Case.
String resolveEntityName(String entityName) =>
    entityName.isEmpty ? 'Walk-in' : Formatters.titleCase(entityName);

/// Balance effect of a sales/purchase return on the entity's outstanding
/// balance. Mirrors the logic used when persisting the transaction so that
/// statements and running balances reconcile with the stored balance.
///
/// A return reverses the original receivable/payable: it reduces the balance
/// by the return value, capped at what the original transaction still owed.
/// This prevents a cash refund on a credit sale from being double-counted
/// (cash given back is a separate settlement, not extra balance relief).
double returnBalanceDelta(Transaction ret, Transaction? original) {
  final originalUnpaid = original == null
      ? ret.totalAmount
      : (original.totalAmount - original.paidAmount).clamp(0, double.infinity).toDouble();
  return -(ret.totalAmount.clamp(0, originalUnpaid).toDouble());
}
