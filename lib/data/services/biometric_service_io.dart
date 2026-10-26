import 'package:dompetektif/domain/services/device_services.dart';
import 'package:flutter/foundation.dart';
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
    } on PlatformException catch (error) {
      debugPrint('Biometrics unavailable: ${error.code} ${error.message}');
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      // Sticky auth ignores the cancel error while the activity is paused,
      // which leaves the lock screen stuck at "preparing" after the user
      // dismisses the prompt with Back.
      return await _auth
          .authenticate(
            localizedReason: reason,
            biometricOnly: true,
            persistAcrossBackgrounding: false,
            sensitiveTransaction: true,
          )
          .timeout(const Duration(seconds: 30), onTimeout: () => false);
    } on LocalAuthException catch (error) {
      debugPrint(
        'Biometric prompt failed: ${error.code.name} ${error.description}',
      );
      return false;
    } on PlatformException catch (error) {
      debugPrint('Biometric prompt failed: ${error.code} ${error.message}');
      return false;
    }
  }
}

BiometricService createPlatformBiometricService() => DeviceBiometricService();
