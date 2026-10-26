import 'package:dompetektif/domain/entities/money.dart';
import 'package:equatable/equatable.dart';

enum WalletType {
  cash,
  bank,
  ewallet;

  static WalletType fromKey(String? value) {
    return WalletType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => WalletType.cash,
    );
  }
}

enum WalletRole {
  owner,
  editor,
  viewer;

  static WalletRole fromKey(String? value) {
    return WalletRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => WalletRole.viewer,
    );
  }

  bool get canEdit => this == owner || this == editor;

  bool get canManage => this == owner;
}

class Wallet extends Equatable {
  const Wallet({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.type,
    required this.openingBalance,
    required this.createdAt,
    required this.updatedAt,
    this.colorHex = '#E8B84B',
    this.iconKey = 'wallet',
    this.isShared = false,
    this.deletedAt,
  });

  final String id;
  final String ownerId;
  final String name;
  final WalletType type;
  final Money openingBalance;
  final String colorHex;
  final String iconKey;
  final bool isShared;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Wallet copyWith({
    String? id,
    String? ownerId,
    String? name,
    WalletType? type,
    Money? openingBalance,
    String? colorHex,
    String? iconKey,
    bool? isShared,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Wallet(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      type: type ?? this.type,
      openingBalance: openingBalance ?? this.openingBalance,
      colorHex: colorHex ?? this.colorHex,
      iconKey: iconKey ?? this.iconKey,
      isShared: isShared ?? this.isShared,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  @override
  List<Object?> get props => [
    id,
    ownerId,
    name,
    type,
    openingBalance,
    colorHex,
    iconKey,
    isShared,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}

class WalletBalance extends Equatable {
  const WalletBalance({
    required this.wallet,
    required this.balance,
    required this.monthIncome,
    required this.monthExpense,
    this.role = WalletRole.owner,
  });

  final Wallet wallet;
  final Money balance;
  final Money monthIncome;
  final Money monthExpense;
  final WalletRole role;

  @override
  List<Object?> get props => [wallet, balance, monthIncome, monthExpense, role];
}

class WalletMember extends Equatable {
  const WalletMember({
    required this.walletId,
    required this.userId,
    required this.role,
    required this.displayName,
    required this.email,
    this.id = '',
    this.avatarUrl,
    this.joinedAt,
    this.isOnline = false,
  });

  final String id;
  final String walletId;
  final String userId;
  final WalletRole role;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final DateTime? joinedAt;
  final bool isOnline;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    String initial(String value) =>
        value.isEmpty ? '' : value.substring(0, 1).toUpperCase();
    if (parts.length == 1) return initial(parts.first);
    return '${initial(parts.first)}${initial(parts.last)}';
  }

  WalletMember copyWith({bool? isOnline}) {
    return WalletMember(
      id: id,
      walletId: walletId,
      userId: userId,
      role: role,
      displayName: displayName,
      email: email,
      avatarUrl: avatarUrl,
      joinedAt: joinedAt,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  List<Object?> get props => [
    id,
    walletId,
    userId,
    role,
    displayName,
    email,
    avatarUrl,
    joinedAt,
    isOnline,
  ];
}
