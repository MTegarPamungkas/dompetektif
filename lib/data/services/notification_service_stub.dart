import 'package:dompetektif/domain/services/device_services.dart';

class SilentNotificationService implements NotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> showBudgetAlert({
    required String title,
    required String body,
    String? payload,
  }) async {}

  @override
  Future<void> showCaseAlert({
    required String title,
    required String body,
    String? payload,
  }) async {}

  @override
  Future<void> scheduleRecurringReminder({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {}

  @override
  Future<void> cancel(int id) async {}
}

NotificationService createPlatformNotificationService() =>
    SilentNotificationService();
