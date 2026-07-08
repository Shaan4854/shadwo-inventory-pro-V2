import 'formatters.dart';

/// Returns "Walk-in" when [entityName] is empty, otherwise the name itself
/// in Title Case.
String resolveEntityName(String entityName) =>
    entityName.isEmpty ? 'Walk-in' : Formatters.titleCase(entityName);
