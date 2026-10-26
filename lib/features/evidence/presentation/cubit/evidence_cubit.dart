import 'dart:async';
import 'dart:typed_data';

import 'package:dompetektif/domain/entities/receipt.dart';
import 'package:dompetektif/domain/usecases/ledger_usecases.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

class EvidenceCubit extends Cubit<EvidenceState> {
  EvidenceCubit(
    this._watch,
    this._scan,
    this._parseText,
    this._save,
    this._delete,
    this._loadImage,
  ) : super(const EvidenceState()) {
    _subscription = _watch().listen(
      (receipts) => emit(
        state.copyWith(receipts: receipts, loading: false, clearFailure: true),
      ),
      onError: (_) =>
          emit(state.copyWith(loading: false, failure: EvidenceFailure.load)),
    );
  }

  final WatchReceipts _watch;
  final ScanReceipt _scan;
  final ParseReceiptText _parseText;
  final SaveReceipt _save;
  final DeleteReceipt _delete;
  final LoadReceiptImage _loadImage;

  StreamSubscription<List<Receipt>>? _subscription;

  bool get isScannerSupported => _scan.isSupported;

  Future<OcrResult?> scanImage(Uint8List imageBytes) async {
    if (state.processing) return null;
    emit(state.copyWith(processing: true, clearFailure: true));
    try {
      final result = await _scan(imageBytes);
      emit(state.copyWith(processing: false));
      return result;
    } catch (_) {
      emit(state.copyWith(processing: false, failure: EvidenceFailure.scan));
      return null;
    }
  }

  Future<OcrResult?> analyzeText(String text) async {
    if (state.processing) return null;
    emit(state.copyWith(processing: true, clearFailure: true));
    try {
      final result = await _parseText(text);
      emit(state.copyWith(processing: false));
      return result;
    } catch (_) {
      emit(state.copyWith(processing: false, failure: EvidenceFailure.parse));
      return null;
    }
  }

  Future<bool> saveReceipt(Receipt receipt, {Uint8List? imageBytes}) async {
    if (state.saving) return false;
    emit(state.copyWith(saving: true, clearFailure: true));
    try {
      await _save(receipt, imageBytes: imageBytes);
      emit(state.copyWith(saving: false));
      return true;
    } catch (_) {
      emit(state.copyWith(saving: false, failure: EvidenceFailure.save));
      return false;
    }
  }

  Future<bool> deleteReceipt(String id) async {
    if (state.deleting) return false;
    emit(state.copyWith(deleting: true, clearFailure: true));
    try {
      await _delete(id);
      emit(state.copyWith(deleting: false));
      return true;
    } catch (_) {
      emit(state.copyWith(deleting: false, failure: EvidenceFailure.delete));
      return false;
    }
  }

  Future<Uint8List?> imageFor(String id) => _loadImage(id);

  void clearFailure() => emit(state.copyWith(clearFailure: true));

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
