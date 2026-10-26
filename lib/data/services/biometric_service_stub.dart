import 'package:dompetektif/domain/services/device_services.dart';

class UnavailableBiometricService implements BiometricService {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> authenticate(String reason) async => false;
}

BiometricService createPlatformBiometricService() =>
    UnavailableBiometricService();
