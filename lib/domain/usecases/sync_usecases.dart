import 'package:dompetektif/domain/entities/sync_status.dart';
import 'package:dompetektif/domain/repositories/app_repository.dart';
import 'package:dompetektif/domain/services/device_services.dart';

class WatchSyncStatus {
  const WatchSyncStatus(this._repository);

  final SyncRepository _repository;

  Stream<SyncStatus> call() => _repository.watchStatus();
}

class SyncNow {
  const SyncNow(this._repository);

  final SyncRepository _repository;

  Future<void> call() => _repository.syncNow();
}

class CheckBiometrics {
  const CheckBiometrics(this._service);

  final BiometricService _service;

  Future<bool> call() => _service.isAvailable();
}

class UnlockWithBiometrics {
  const UnlockWithBiometrics(this._service);

  final BiometricService _service;

  Future<bool> call(String reason) => _service.authenticate(reason);
}
