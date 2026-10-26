import 'package:dompetektif/domain/services/device_services.dart';

import 'biometric_service_stub.dart'
    if (dart.library.io) 'biometric_service_io.dart'
    as platform;

BiometricService createBiometricService() =>
    platform.createPlatformBiometricService();
