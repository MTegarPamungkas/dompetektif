import 'dart:io';
import 'dart:typed_data';

import 'package:dompetektif/domain/services/device_services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MlKitReceiptScanner implements ReceiptScanner {
  @override
  bool get isSupported => true;

  @override
  Future<String> recognize(Uint8List imageBytes) async {
    final file = File(
      '${Directory.systemTemp.path}/dompetektif_ocr_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(imageBytes, flush: true);

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final input = InputImage.fromFilePath(file.path);
      final recognized = await recognizer.processImage(input);
      return recognized.text;
    } finally {
      await recognizer.close();
      if (await file.exists()) {
        try {
          await file.delete();
        } on FileSystemException {
          // Best effort cleanup.
        }
      }
    }
  }
}

ReceiptScanner createPlatformReceiptScanner() => MlKitReceiptScanner();
