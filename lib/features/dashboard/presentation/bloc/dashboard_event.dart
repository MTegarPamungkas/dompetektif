import 'package:dompetektif/domain/entities/dashboard_data.dart';

sealed class DashboardEvent {
  const DashboardEvent();
}

final class DashboardStarted extends DashboardEvent {
  const DashboardStarted();
}

final class DashboardReloaded extends DashboardEvent {
  const DashboardReloaded();
}

final class DashboardDataReceived extends DashboardEvent {
  const DashboardDataReceived(this.data);

  final DashboardData data;
}

final class DashboardFailed extends DashboardEvent {
  const DashboardFailed();
}
