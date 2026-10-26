import 'package:dompetektif/domain/services/device_services.dart';

import 'receipt_scanner_stub.dart'
    if (dart.library.io) 'receipt_scanner_io.dart'
    as platform;

ReceiptScanner createReceiptScanner() =>
    platform.createPlatformReceiptScanner();
