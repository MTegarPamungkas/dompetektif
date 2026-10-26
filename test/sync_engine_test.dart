import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dompetektif/data/datasources/cloud_gateway.dart';
import 'package:dompetektif/data/datasources/local_store.dart';
import 'package:dompetektif/data/sync/sync_engine.dart';
import 'package:dompetektif/domain/entities/app_user.dart';
import 'package:dompetektif/domain/entities/sync_status.dart';
import 'package:dompetektif/domain/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _CloudGateway extends Mock implements CloudGateway {}

class _AuthRepository extends Mock implements AuthRepository {}

class _Connectivity extends Mock implements Connectivity {}

void main() {
  test('demo sync starts in local mode and never queues cloud work', () async {
    final directory = await Directory.systemTemp.createTemp(
      'dompetektif_sync_test_',
    );
    final store = LocalStore();
    final gateway = _CloudGateway();
    final auth = _AuthRepository();
    final connectivity = _Connectivity();

    when(() => gateway.isDemo).thenReturn(true);
    when(() => auth.watchUser())
        .thenAnswer((_) => const Stream<AppUser?>.empty());
    when(() => connectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.wifi]);
    when(() => connectivity.onConnectivityChanged)
        .thenAnswer((_) => const Stream<List<ConnectivityResult>>.empty());

    final engine = SyncEngine(
      store: store,
      gateway: gateway,
      auth: auth,
      connectivity: connectivity,
    );

    addTearDown(() async {
      await engine.dispose();
      await store.close();
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    await store.init(directory: directory.path, name: 'demo_sync');
    await engine.start();

    expect(engine.current.phase, SyncPhase.demo);
    expect(engine.current.pendingCount, 0);

    engine.requestSync();
    expect(engine.current.phase, SyncPhase.demo);
    expect(store.outboxItems(), isEmpty);
  });
}
