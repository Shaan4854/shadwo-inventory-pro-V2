/// Returns "Walk-in" when [entityName] is empty, otherwise the name itself.
String resolveEntityName(String entityName) =>
    entityName.isEmpty ? 'Walk-in' : entityName;
