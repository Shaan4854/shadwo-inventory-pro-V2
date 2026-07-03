import '../database/database_helper.dart';
import '../models/supplier.dart';
import 'supplier_repository.dart';

class SQLiteSupplierRepository implements SupplierRepository {
  SQLiteSupplierRepository({
    DatabaseHelper? databaseHelper,
  }) : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  @override
  Future<List<Supplier>> getSuppliers() async {
    return _databaseHelper.getSuppliers();
  }

  @override
  Future<void> addSupplier(Supplier supplier) async {
    await _databaseHelper.insertSupplier(supplier);
  }

  @override
  Future<void> updateSupplier(Supplier supplier) async {
    await _databaseHelper.updateSupplier(supplier);
  }

  @override
  Future<void> deleteSupplier(String id) async {
    await _databaseHelper.deleteSupplier(id);
  }
}
