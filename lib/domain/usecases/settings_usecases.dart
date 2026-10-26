import 'package:dompetektif/domain/entities/app_settings.dart';
import 'package:dompetektif/domain/repositories/app_repository.dart';

class WatchSettings {
  const WatchSettings(this._repository);

  final SettingsRepository _repository;

  Stream<AppSettings> call() => _repository.watch();
}

class GetSettings {
  const GetSettings(this._repository);

  final SettingsRepository _repository;

  AppSettings call() => _repository.current;
}

class UpdateSettings {
  const UpdateSettings(this._repository);

  final SettingsRepository _repository;

  Future<void> call(AppSettings settings) => _repository.save(settings);
}
