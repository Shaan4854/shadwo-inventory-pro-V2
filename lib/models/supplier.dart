import 'package:equatable/equatable.dart';

class Supplier extends Equatable {
  const Supplier({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.mobile,
    required this.createdAt,
    required this.updatedAt,
    this.email = '',
    this.address = '',
    this.gstVat = '',
    this.notes = '',
    this.outstandingBalance = 0.0,
  });

  final String id;
  final String name;
  final String contactPerson;
  final String mobile;
  final String email;
  final String address;
  final String gstVat;
  final String notes;
  final double outstandingBalance;
  final DateTime createdAt;
  final DateTime updatedAt;

  Supplier copyWith({
    String? id,
    String? name,
    String? contactPerson,
    String? mobile,
    String? email,
    String? address,
    String? gstVat,
    String? notes,
    double? outstandingBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
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

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'contact_person': contactPerson,
      'mobile': mobile,
      'email': email,
      'address': address,
      'gst_vat': gstVat,
      'notes': notes,
      'outstanding_balance': outstandingBalance,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Supplier.fromMap(Map<String, Object?> map) {
    return Supplier(
      id: map['id'] as String,
      name: map['name'] as String,
      contactPerson: map['contact_person'] as String? ?? '',
      mobile: map['mobile'] as String,
      email: map['email'] as String? ?? '',
      address: map['address'] as String? ?? '',
      gstVat: map['gst_vat'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      outstandingBalance: (map['outstanding_balance'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        contactPerson,
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
