import 'package:equatable/equatable.dart';

/// Product category. Simple lookup table — Products reference by name
/// (matching the React model's `category: string` field), but a separate
/// table makes filtering + rename operations sane.
class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.emoji,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String emoji;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'created_at': createdAt.toIso8601String(),
      };

  factory Category.fromMap(Map<String, Object?> m) => Category(
        id: m['id'] as String,
        name: m['name'] as String,
        emoji: (m['emoji'] as String?) ?? '🏷️',
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  @override
  List<Object?> get props => [id, name, emoji, createdAt];
}
