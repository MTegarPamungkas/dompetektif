import 'dart:typed_data';

abstract interface class ReceiptScanner {
  bool get isSupported;

  Future<String> recognize(Uint8List imageBytes);
}

abstract interface class NotificationService {
  Future<void> initialize();

  Future<bool> requestPermission();

  Future<void> showBudgetAlert({
    required String title,
    required String body,
    String? payload,
  });

  Future<void> showCaseAlert({
    required String title,
    required String body,
    String? payload,
  });

  Future<void> scheduleRecurringReminder({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  });

  Future<void> cancel(int id);
}

abstract interface class BiometricService {
  Future<bool> isAvailable();

  Future<bool> authenticate(String reason);
}
