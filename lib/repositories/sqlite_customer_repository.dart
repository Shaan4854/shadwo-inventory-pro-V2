import '../database/database_helper.dart';
import '../models/customer.dart';
import 'customer_repository.dart';

class SQLiteCustomerRepository implements CustomerRepository {
  SQLiteCustomerRepository({
    DatabaseHelper? databaseHelper,
  }) : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  @override
  Future<List<Customer>> getCustomers() async {
    return _databaseHelper.getCustomers();
  }

  @override
  Future<void> addCustomer(Customer customer) async {
    await _databaseHelper.insertCustomer(customer);
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    await _databaseHelper.updateCustomer(customer);
  }

  @override
  Future<void> deleteCustomer(String id) async {
    await _databaseHelper.deleteCustomer(id);
  }
}
