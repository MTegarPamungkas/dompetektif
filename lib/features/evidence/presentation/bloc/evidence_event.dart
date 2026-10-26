import 'dart:async';
import 'dart:typed_data';

import 'package:dompetektif/domain/entities/receipt.dart';

sealed class EvidenceEvent {
  const EvidenceEvent();
}

final class EvidenceStarted extends EvidenceEvent {
  const EvidenceStarted();
}

final class EvidenceChanged extends EvidenceEvent {
  const EvidenceChanged(this.receipts);

  final List<Receipt> receipts;
}

final class EvidenceLoadFailed extends EvidenceEvent {
  const EvidenceLoadFailed();
}

final class EvidenceScanRequested extends EvidenceEvent {
  const EvidenceScanRequested(this.imageBytes, this.completer);

  final Uint8List imageBytes;
  final Completer<OcrResult?> completer;
}

final class EvidenceTextParseRequested extends EvidenceEvent {
  const EvidenceTextParseRequested(this.text, this.completer);

  final String text;
  final Completer<OcrResult?> completer;
}

final class EvidenceSaveRequested extends EvidenceEvent {
  const EvidenceSaveRequested(this.receipt, this.imageBytes, this.completer);

  final Receipt receipt;
  final Uint8List? imageBytes;
  final Completer<bool> completer;
}

final class EvidenceDeleteRequested extends EvidenceEvent {
  const EvidenceDeleteRequested(this.id, this.completer);

  final String id;
  final Completer<bool> completer;
}

final class EvidenceFailureCleared extends EvidenceEvent {
  const EvidenceFailureCleared();
}
