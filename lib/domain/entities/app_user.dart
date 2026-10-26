import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.isDemo = false,
    this.createdAt,
  });

  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final bool isDemo;
  final DateTime? createdAt;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    String initial(String value) =>
        value.isEmpty ? '' : value.substring(0, 1).toUpperCase();
    if (parts.length == 1) return initial(parts.first);
    return '${initial(parts.first)}${initial(parts.last)}';
  }

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    avatarUrl,
    isDemo,
    createdAt,
  ];
}
