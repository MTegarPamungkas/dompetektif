import 'package:dompetektif/domain/entities/receipt.dart';
import 'package:equatable/equatable.dart';

enum EvidenceFailure { load, scan, parse, save, delete }

class EvidenceState extends Equatable {
  const EvidenceState({
    this.receipts = const [],
    this.loading = true,
    this.processing = false,
    this.saving = false,
    this.deleting = false,
    this.failure,
  });

  final List<Receipt> receipts;
  final bool loading;
  final bool processing;
  final bool saving;
  final bool deleting;
  final EvidenceFailure? failure;

  EvidenceState copyWith({
    List<Receipt>? receipts,
    bool? loading,
    bool? processing,
    bool? saving,
    bool? deleting,
    EvidenceFailure? failure,
    bool clearFailure = false,
  }) {
    return EvidenceState(
      receipts: receipts ?? this.receipts,
      loading: loading ?? this.loading,
      processing: processing ?? this.processing,
      saving: saving ?? this.saving,
      deleting: deleting ?? this.deleting,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    receipts,
    loading,
    processing,
    saving,
    deleting,
    failure,
  ];
}
