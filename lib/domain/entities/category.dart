import 'package:equatable/equatable.dart';

enum CategoryKind {
  expense,
  income;

  static CategoryKind fromKey(String? value) {
    return CategoryKind.values.firstWhere(
      (kind) => kind.name == value,
      orElse: () => CategoryKind.expense,
    );
  }
}

class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.kind,
    required this.createdAt,
    required this.updatedAt,
    this.ownerId,
    this.iconKey = 'category',
    this.colorHex = '#E8B84B',
    this.keywords = const [],
    this.isSystem = false,
    this.deletedAt,
  });

  final String id;
  final String? ownerId;
  final String name;
  final CategoryKind kind;
  final String iconKey;
  final String colorHex;
  final List<String> keywords;
  final bool isSystem;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Category copyWith({
    String? id,
    String? ownerId,
    String? name,
    CategoryKind? kind,
    String? iconKey,
    String? colorHex,
    List<String>? keywords,
    bool? isSystem,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Category(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      iconKey: iconKey ?? this.iconKey,
      colorHex: colorHex ?? this.colorHex,
      keywords: keywords ?? this.keywords,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  bool matches(String normalizedQuery) {
    if (normalizedQuery.isEmpty) return true;
    final haystack = [name, ...keywords].join(' ').toLowerCase();
    return haystack.contains(normalizedQuery);
  }

  @override
  List<Object?> get props => [
    id,
    ownerId,
    name,
    kind,
    iconKey,
    colorHex,
    keywords,
    isSystem,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
