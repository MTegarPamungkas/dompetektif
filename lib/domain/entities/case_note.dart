import 'package:equatable/equatable.dart';

class CaseNote extends Equatable {
  const CaseNote({
    required this.id,
    required this.walletId,
    required this.userId,
    required this.authorName,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.transactionId,
    this.avatarUrl,
    this.deletedAt,
    this.isPending = false,
  });

  final String id;
  final String walletId;
  final String? transactionId;
  final String userId;
  final String authorName;
  final String? avatarUrl;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool isPending;

  bool get isDeleted => deletedAt != null;

  String get initials {
    final parts = authorName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    String initial(String value) =>
        value.isEmpty ? '' : value.substring(0, 1).toUpperCase();
    if (parts.length == 1) return initial(parts.first);
    return '${initial(parts.first)}${initial(parts.last)}';
  }

  CaseNote copyWith({
    String? id,
    String? walletId,
    String? transactionId,
    String? userId,
    String? authorName,
    String? avatarUrl,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    bool? isPending,
  }) {
    return CaseNote(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      transactionId: transactionId ?? this.transactionId,
      userId: userId ?? this.userId,
      authorName: authorName ?? this.authorName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      isPending: isPending ?? this.isPending,
    );
  }

  @override
  List<Object?> get props => [
    id,
    walletId,
    transactionId,
    userId,
    authorName,
    avatarUrl,
    body,
    createdAt,
    updatedAt,
    deletedAt,
    isPending,
  ];
}

class OnlineMember extends Equatable {
  const OnlineMember({
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.isCurrentUser = false,
  });

  final String userId;
  final String name;
  final String? avatarUrl;
  final bool isCurrentUser;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    String initial(String value) =>
        value.isEmpty ? '' : value.substring(0, 1).toUpperCase();
    if (parts.length == 1) return initial(parts.first);
    return '${initial(parts.first)}${initial(parts.last)}';
  }

  @override
  List<Object?> get props => [userId, name, avatarUrl, isCurrentUser];
}
