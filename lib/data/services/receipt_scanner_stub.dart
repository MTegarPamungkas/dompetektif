import 'dart:typed_data';

import 'package:dompetektif/domain/services/device_services.dart';

class UnsupportedReceiptScanner implements ReceiptScanner {
  @override
  bool get isSupported => false;

  @override
  Future<String> recognize(Uint8List imageBytes) {
    throw UnsupportedError(
      'Pemindaian struk dengan kamera tersedia di aplikasi Android. Di web, tempel teks struk secara manual.',
    );
  }
}

ReceiptScanner createPlatformReceiptScanner() => UnsupportedReceiptScanner();
