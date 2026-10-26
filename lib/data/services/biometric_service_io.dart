import 'package:dompetektif/domain/services/device_services.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class DeviceBiometricService implements BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      return await _auth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
        sensitiveTransaction: true,
      );
    } on PlatformException {
      return false;
    }
  }
}

BiometricService createPlatformBiometricService() => DeviceBiometricService();
