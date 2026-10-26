import 'package:dompetektif/app/app.dart';
import 'package:dompetektif/core/config/app_config.dart';
import 'package:dompetektif/core/di/injection_container.dart';
import 'package:dompetektif/data/datasources/local_store.dart';
import 'package:dompetektif/data/sync/sync_engine.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final store = LocalStore();
  await store.init();

  SupabaseClient? client;
  if (AppConfig.hasSupabase) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: AppConfig.supabaseAnonKey,
      );
      client = Supabase.instance.client;
    } catch (error, stackTrace) {
      debugPrint('Supabase initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      client = null;
    }
  }

  await configureDependencies(store: store, client: client);
  await getIt<SyncEngine>().start();
  runApp(const DompetektifApp());
}
