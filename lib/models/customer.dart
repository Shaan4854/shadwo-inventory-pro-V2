import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  const Customer({
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
    required this.address,
    required this.gstVat,
    required this.notes,
    required this.outstandingBalance,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String mobile;
  final String email;
  final String address;
  final String gstVat;
  final String notes;
  final double outstandingBalance;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer copyWith({
    String? id,
    String? name,
    String? mobile,
    String? email,
    String? address,
    String? gstVat,
    String? notes,
    double? outstandingBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      address: address ?? this.address,
      gstVat: gstVat ?? this.gstVat,
      notes: notes ?? this.notes,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'mobile': mobile,
        'email': email,
        'address': address,
        'gst_vat': gstVat,
        'notes': notes,
        'outstanding_balance': outstandingBalance,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Customer.fromMap(Map<String, Object?> m) => Customer(
        id: m['id'] as String,
        name: m['name'] as String,
        mobile: (m['mobile'] as String?) ?? '',
        email: (m['email'] as String?) ?? '',
        address: (m['address'] as String?) ?? '',
        gstVat: (m['gst_vat'] as String?) ?? '',
        notes: (m['notes'] as String?) ?? '',
        outstandingBalance:
            ((m['outstanding_balance'] as num?) ?? 0).toDouble(),
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );

  @override
  List<Object?> get props => [
        id,
        name,
        mobile,
        email,
        address,
        gstVat,
        notes,
        outstandingBalance,
        createdAt,
        updatedAt,
      ];
}
