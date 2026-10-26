import 'dart:typed_data';

import 'package:dompetektif/domain/services/device_services.dart';

class UnsupportedReceiptScanner implements ReceiptScanner {
  @override
  bool get isSupported => false;

  @override
  Future<String> recognize(Uint8List imageBytes) {
    throw UnsupportedError(
      'Scan kamera cuma ada di aplikasi Android. Di web, tempel teks struknya.',
    );
  }
}

ReceiptScanner createPlatformReceiptScanner() => UnsupportedReceiptScanner();
