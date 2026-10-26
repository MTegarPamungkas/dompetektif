import 'package:dompetektif/domain/entities/money.dart';
import 'package:equatable/equatable.dart';

enum ReceiptStatus {
  draft,
  parsed,
  attached,
  failed;

  static ReceiptStatus fromKey(String? value) {
    return ReceiptStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ReceiptStatus.draft,
    );
  }
}

class ReceiptItem extends Equatable {
  const ReceiptItem({
    required this.name,
    required this.total,
    this.quantity = 1,
  });

  final String name;
  final int quantity;
  final Money total;

  @override
  List<Object?> get props => [name, quantity, total];
}

class Receipt extends Equatable {
  const Receipt({
    required this.id,
    required this.ownerId,
    required this.merchant,
    required this.total,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
    this.walletId,
    this.transactionId,
    this.rawText = '',
    this.items = const [],
    this.imageKey,
    this.remoteImageUrl,
    this.status = ReceiptStatus.draft,
    this.deletedAt,
  });

  final String id;
  final String ownerId;
  final String? walletId;
  final String? transactionId;
  final String merchant;
  final Money total;
  final DateTime occurredAt;
  final String rawText;
  final List<ReceiptItem> items;
  final String? imageKey;
  final String? remoteImageUrl;
  final ReceiptStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Receipt copyWith({
    String? id,
    String? ownerId,
    String? walletId,
    String? transactionId,
    String? merchant,
    Money? total,
    DateTime? occurredAt,
    String? rawText,
    List<ReceiptItem>? items,
    String? imageKey,
    String? remoteImageUrl,
    ReceiptStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Receipt(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      walletId: walletId ?? this.walletId,
      transactionId: transactionId ?? this.transactionId,
      merchant: merchant ?? this.merchant,
      total: total ?? this.total,
      occurredAt: occurredAt ?? this.occurredAt,
      rawText: rawText ?? this.rawText,
      items: items ?? this.items,
      imageKey: imageKey ?? this.imageKey,
      remoteImageUrl: remoteImageUrl ?? this.remoteImageUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  @override
  List<Object?> get props => [
    id,
    ownerId,
    walletId,
    transactionId,
    merchant,
    total,
    occurredAt,
    rawText,
    items,
    imageKey,
    remoteImageUrl,
    status,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}

class OcrResult extends Equatable {
  const OcrResult({
    required this.rawText,
    required this.isSupported,
    this.merchant,
    this.total,
    this.occurredAt,
    this.items = const [],
    this.suggestedCategoryId,
    this.suggestedCategoryName,
    this.confidence = 0,
  });

  const OcrResult.unsupported()
    : rawText = '',
      isSupported = false,
      merchant = null,
      total = null,
      occurredAt = null,
      items = const [],
      suggestedCategoryId = null,
      suggestedCategoryName = null,
      confidence = 0;

  final String rawText;
  final bool isSupported;
  final String? merchant;
  final Money? total;
  final DateTime? occurredAt;
  final List<ReceiptItem> items;
  final String? suggestedCategoryId;
  final String? suggestedCategoryName;
  final double confidence;

  @override
  List<Object?> get props => [
    rawText,
    isSupported,
    merchant,
    total,
    occurredAt,
    items,
    suggestedCategoryId,
    suggestedCategoryName,
    confidence,
  ];
}
