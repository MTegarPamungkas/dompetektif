import 'dart:async';
import 'dart:typed_data';

import 'package:dompetektif/domain/entities/receipt.dart';
import 'package:dompetektif/domain/usecases/ledger_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'evidence_event.dart';
import 'evidence_state.dart';

export 'evidence_event.dart';
export 'evidence_state.dart';

class EvidenceBloc extends Bloc<EvidenceEvent, EvidenceState> {
  EvidenceBloc(
    this._watch,
    this._scan,
    this._parseText,
    this._save,
    this._delete,
    this._loadImage,
  ) : super(const EvidenceState()) {
    on<EvidenceStarted>(_onStarted);
    on<EvidenceChanged>(_onChanged);
    on<EvidenceLoadFailed>(_onLoadFailed);
    on<EvidenceScanRequested>(_onScanRequested);
    on<EvidenceTextParseRequested>(_onTextParseRequested);
    on<EvidenceSaveRequested>(_onSaveRequested);
    on<EvidenceDeleteRequested>(_onDeleteRequested);
    on<EvidenceFailureCleared>(_onFailureCleared);
    add(const EvidenceStarted());
  }

  final WatchReceipts _watch;
  final ScanReceipt _scan;
  final ParseReceiptText _parseText;
  final SaveReceipt _save;
  final DeleteReceipt _delete;
  final LoadReceiptImage _loadImage;

  StreamSubscription<List<Receipt>>? _subscription;

  bool get isScannerSupported => _scan.isSupported;

  Future<void> _onStarted(
    EvidenceStarted event,
    Emitter<EvidenceState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = _watch().listen(
      (receipts) => add(EvidenceChanged(receipts)),
      onError: (_) => add(const EvidenceLoadFailed()),
    );
  }

  void _onChanged(EvidenceChanged event, Emitter<EvidenceState> emit) {
    emit(
      state.copyWith(
        receipts: event.receipts,
        loading: false,
        clearFailure: true,
      ),
    );
  }

  void _onLoadFailed(EvidenceLoadFailed event, Emitter<EvidenceState> emit) {
    emit(state.copyWith(loading: false, failure: EvidenceFailure.load));
  }

  Future<void> _onScanRequested(
    EvidenceScanRequested event,
    Emitter<EvidenceState> emit,
  ) async {
    if (state.processing) {
      event.completer.complete(null);
      return;
    }
    emit(state.copyWith(processing: true, clearFailure: true));
    try {
      final result = await _scan(event.imageBytes);
      emit(state.copyWith(processing: false));
      event.completer.complete(result);
    } catch (_) {
      emit(state.copyWith(processing: false, failure: EvidenceFailure.scan));
      event.completer.complete(null);
    }
  }

  Future<void> _onTextParseRequested(
    EvidenceTextParseRequested event,
    Emitter<EvidenceState> emit,
  ) async {
    if (state.processing) {
      event.completer.complete(null);
      return;
    }
    emit(state.copyWith(processing: true, clearFailure: true));
    try {
      final result = await _parseText(event.text);
      emit(state.copyWith(processing: false));
      event.completer.complete(result);
    } catch (_) {
      emit(state.copyWith(processing: false, failure: EvidenceFailure.parse));
      event.completer.complete(null);
    }
  }

  Future<void> _onSaveRequested(
    EvidenceSaveRequested event,
    Emitter<EvidenceState> emit,
  ) async {
    if (state.saving) {
      event.completer.complete(false);
      return;
    }
    emit(state.copyWith(saving: true, clearFailure: true));
    try {
      await _save(event.receipt, imageBytes: event.imageBytes);
      emit(state.copyWith(saving: false));
      event.completer.complete(true);
    } catch (_) {
      emit(state.copyWith(saving: false, failure: EvidenceFailure.save));
      event.completer.complete(false);
    }
  }

  Future<void> _onDeleteRequested(
    EvidenceDeleteRequested event,
    Emitter<EvidenceState> emit,
  ) async {
    if (state.deleting) {
      event.completer.complete(false);
      return;
    }
    emit(state.copyWith(deleting: true, clearFailure: true));
    try {
      await _delete(event.id);
      emit(state.copyWith(deleting: false));
      event.completer.complete(true);
    } catch (_) {
      emit(state.copyWith(deleting: false, failure: EvidenceFailure.delete));
      event.completer.complete(false);
    }
  }

  void _onFailureCleared(
    EvidenceFailureCleared event,
    Emitter<EvidenceState> emit,
  ) {
    emit(state.copyWith(clearFailure: true));
  }

  Future<OcrResult?> scanImage(Uint8List imageBytes) async {
    final completer = Completer<OcrResult?>();
    add(EvidenceScanRequested(imageBytes, completer));
    return completer.future;
  }

  Future<OcrResult?> analyzeText(String text) async {
    final completer = Completer<OcrResult?>();
    add(EvidenceTextParseRequested(text, completer));
    return completer.future;
  }

  Future<bool> saveReceipt(Receipt receipt, {Uint8List? imageBytes}) async {
    final completer = Completer<bool>();
    add(EvidenceSaveRequested(receipt, imageBytes, completer));
    return completer.future;
  }

  Future<bool> deleteReceipt(String id) async {
    final completer = Completer<bool>();
    add(EvidenceDeleteRequested(id, completer));
    return completer.future;
  }

  Future<Uint8List?> imageFor(String id) => _loadImage(id);

  void clearFailure() => add(const EvidenceFailureCleared());

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
