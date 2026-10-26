import 'package:dompetektif/domain/services/device_services.dart';

import 'notification_service_stub.dart'
    if (dart.library.io) 'notification_service_io.dart'
    as platform;

NotificationService createNotificationService() =>
    platform.createPlatformNotificationService();
