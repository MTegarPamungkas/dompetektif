import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dompetektif/app/app_maintenance.dart';
import 'package:dompetektif/data/datasources/cloud_gateway.dart';
import 'package:dompetektif/data/datasources/demo_cloud_gateway.dart';
import 'package:dompetektif/data/datasources/local_store.dart';
import 'package:dompetektif/data/datasources/supabase_cloud_gateway.dart';
import 'package:dompetektif/data/repositories/auth_repository_impl.dart';
import 'package:dompetektif/data/repositories/export_repository_impl.dart';
import 'package:dompetektif/data/repositories/insight_repository_impl.dart';
import 'package:dompetektif/data/repositories/ledger_repository_impl.dart';
import 'package:dompetektif/data/repositories/local_repository_base.dart';
import 'package:dompetektif/data/repositories/settings_repository_impl.dart';
import 'package:dompetektif/data/repositories/team_repository_impl.dart';
import 'package:dompetektif/data/repositories/wallet_repository_impl.dart';
import 'package:dompetektif/data/seed/demo_seeder.dart';
import 'package:dompetektif/data/services/biometric_service.dart';
import 'package:dompetektif/data/services/notification_service.dart';
import 'package:dompetektif/data/services/receipt_scanner.dart';
import 'package:dompetektif/data/sync/sync_engine.dart';
import 'package:dompetektif/domain/repositories/app_repository.dart';
import 'package:dompetektif/domain/repositories/auth_repository.dart';
import 'package:dompetektif/domain/repositories/ledger_repository.dart';
import 'package:dompetektif/domain/repositories/wallet_repository.dart';
import 'package:dompetektif/domain/services/device_services.dart';
import 'package:dompetektif/domain/usecases/alert_usecases.dart';
import 'package:dompetektif/domain/usecases/auth_usecases.dart';
import 'package:dompetektif/domain/usecases/budget_usecases.dart';
import 'package:dompetektif/domain/usecases/dashboard_usecases.dart';
import 'package:dompetektif/domain/usecases/export_usecases.dart';
import 'package:dompetektif/domain/usecases/insight_usecases.dart';
import 'package:dompetektif/domain/usecases/ledger_usecases.dart';
import 'package:dompetektif/domain/usecases/recurring_usecases.dart';
import 'package:dompetektif/domain/usecases/settings_usecases.dart';
import 'package:dompetektif/domain/usecases/sync_usecases.dart';
import 'package:dompetektif/domain/usecases/wallet_usecases.dart';
import 'package:dompetektif/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dompetektif/features/budgets/presentation/bloc/budget_bloc.dart';
import 'package:dompetektif/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:dompetektif/features/evidence/presentation/bloc/evidence_bloc.dart';
import 'package:dompetektif/features/ledger/presentation/bloc/ledger_bloc.dart';
import 'package:dompetektif/features/ledger/presentation/bloc/transaction_form_bloc.dart';
import 'package:dompetektif/features/reports/presentation/bloc/report_bloc.dart';
import 'package:dompetektif/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:dompetektif/features/settings/presentation/bloc/settings_data_bloc.dart';
import 'package:dompetektif/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:dompetektif/features/team/presentation/bloc/team_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies({
  required LocalStore store,
  SupabaseClient? client,
}) async {
  getIt.registerSingleton<LocalStore>(store);
  getIt.registerLazySingleton<Uuid>(() => const Uuid());

  getIt.registerLazySingleton<CloudGateway>(
    () =>
        client == null ? DemoCloudGateway(store) : SupabaseCloudGateway(client),
  );
  getIt.registerLazySingleton<DemoSeeder>(() => DemoSeeder(store));
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      store: store,
      seeder: getIt<DemoSeeder>(),
      client: client,
    ),
  );

  getIt.registerLazySingleton<Connectivity>(Connectivity.new);
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(store),
  );
  getIt.registerLazySingleton<AlertRepository>(
    () => AlertRepositoryImpl(store),
  );
  getIt.registerLazySingleton<SyncEngine>(
    () => SyncEngine(
      store: store,
      gateway: getIt<CloudGateway>(),
      auth: getIt<AuthRepository>(),
      connectivity: getIt<Connectivity>(),
    ),
  );
  getIt.registerLazySingleton<SyncRepository>(() => getIt<SyncEngine>());

  final walletRepository = WalletRepositoryImpl(
    store,
    getIt<SyncEngine>(),
    getIt<AuthRepository>(),
  );
  final categoryRepository = CategoryRepositoryImpl(
    store,
    getIt<SyncEngine>(),
    getIt<AuthRepository>(),
  );
  getIt.registerLazySingleton<WalletRepository>(() => walletRepository);
  getIt.registerLazySingleton<CategoryRepository>(() => categoryRepository);

  getIt.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(
      store,
      getIt<SyncEngine>(),
      getIt<AuthRepository>(),
    ),
  );
  getIt.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(
      store,
      getIt<SyncEngine>(),
      getIt<AuthRepository>(),
    ),
  );
  getIt.registerLazySingleton<RecurringRepository>(
    () => RecurringRepositoryImpl(
      store,
      getIt<SyncEngine>(),
      getIt<AuthRepository>(),
    ),
  );
  getIt.registerLazySingleton<ReceiptRepository>(
    () => ReceiptRepositoryImpl(
      store,
      getIt<SyncEngine>(),
      getIt<AuthRepository>(),
      getIt<CloudGateway>(),
    ),
  );
  getIt.registerLazySingleton<TeamRepository>(
    () => TeamRepositoryImpl(
      store,
      getIt<SyncEngine>(),
      getIt<AuthRepository>(),
      getIt<CloudGateway>(),
    ),
  );
  getIt.registerLazySingleton<LocalRepositoryBase>(() => walletRepository);
  getIt.registerLazySingleton<InsightRepository>(
    () => InsightRepositoryImpl(store, getIt<CloudGateway>(), walletRepository),
  );
  getIt.registerLazySingleton<ExportRepository>(ExportRepositoryImpl.new);

  getIt.registerLazySingleton<ReceiptScanner>(createReceiptScanner);
  getIt.registerLazySingleton<NotificationService>(createNotificationService);
  getIt.registerLazySingleton<BiometricService>(createBiometricService);

  _registerUsecases();
  _registerBlocs();
}

void _registerUsecases() {
  getIt.registerLazySingleton<WatchAuthUser>(
    () => WatchAuthUser(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<GetCurrentUser>(
    () => GetCurrentUser(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<SignInWithEmail>(
    () => SignInWithEmail(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<SignUpWithEmail>(
    () => SignUpWithEmail(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<SignInWithGoogle>(
    () => SignInWithGoogle(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<ContinueAsDemo>(
    () => ContinueAsDemo(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<SignOut>(() => SignOut(getIt<AuthRepository>()));

  getIt.registerLazySingleton<WatchSettings>(
    () => WatchSettings(getIt<SettingsRepository>()),
  );
  getIt.registerLazySingleton<GetSettings>(
    () => GetSettings(getIt<SettingsRepository>()),
  );
  getIt.registerLazySingleton<UpdateSettings>(
    () => UpdateSettings(getIt<SettingsRepository>()),
  );

  getIt.registerLazySingleton<WatchWallets>(
    () => WatchWallets(getIt<WalletRepository>()),
  );
  getIt.registerLazySingleton<GetWallets>(
    () => GetWallets(getIt<WalletRepository>()),
  );
  getIt.registerLazySingleton<GetWallet>(
    () => GetWallet(getIt<WalletRepository>()),
  );
  getIt.registerLazySingleton<SaveWallet>(
    () => SaveWallet(getIt<WalletRepository>()),
  );
  getIt.registerLazySingleton<DeleteWallet>(
    () => DeleteWallet(getIt<WalletRepository>()),
  );
  getIt.registerLazySingleton<WatchCategories>(
    () => WatchCategories(getIt<CategoryRepository>()),
  );
  getIt.registerLazySingleton<GetCategories>(
    () => GetCategories(getIt<CategoryRepository>()),
  );
  getIt.registerLazySingleton<SaveCategory>(
    () => SaveCategory(getIt<CategoryRepository>()),
  );
  getIt.registerLazySingleton<DeleteCategory>(
    () => DeleteCategory(getIt<CategoryRepository>()),
  );
  getIt.registerLazySingleton<WatchTeam>(
    () => WatchTeam(getIt<TeamRepository>()),
  );
  getIt.registerLazySingleton<SendCaseNote>(
    () => SendCaseNote(getIt<TeamRepository>()),
  );
  getIt.registerLazySingleton<CreateWalletInvite>(
    () => CreateWalletInvite(getIt<TeamRepository>()),
  );
  getIt.registerLazySingleton<JoinSharedWallet>(
    () => JoinSharedWallet(getIt<TeamRepository>()),
  );

  getIt.registerLazySingleton<WatchLedger>(
    () => WatchLedger(getIt<TransactionRepository>()),
  );
  getIt.registerLazySingleton<WatchTransactions>(
    () => WatchTransactions(getIt<TransactionRepository>()),
  );
  getIt.registerLazySingleton<GetLedgerEntry>(
    () => GetLedgerEntry(getIt<TransactionRepository>()),
  );
  getIt.registerLazySingleton<SaveTransaction>(
    () => SaveTransaction(getIt<TransactionRepository>()),
  );
  getIt.registerLazySingleton<DeleteTransaction>(
    () => DeleteTransaction(getIt<TransactionRepository>()),
  );
  getIt.registerLazySingleton<CreateTransactionFromReceipt>(
    () => CreateTransactionFromReceipt(
      getIt<TransactionRepository>(),
      getIt<ReceiptRepository>(),
      getIt<GetCurrentUser>(),
      uuid: getIt<Uuid>(),
    ),
  );
  getIt.registerLazySingleton<WatchReceipts>(
    () => WatchReceipts(getIt<ReceiptRepository>()),
  );
  getIt.registerLazySingleton<GetReceipt>(
    () => GetReceipt(getIt<ReceiptRepository>()),
  );
  getIt.registerLazySingleton<SaveReceipt>(
    () => SaveReceipt(getIt<ReceiptRepository>()),
  );
  getIt.registerLazySingleton<DeleteReceipt>(
    () => DeleteReceipt(getIt<ReceiptRepository>()),
  );
  getIt.registerLazySingleton<LoadReceiptImage>(
    () => LoadReceiptImage(getIt<ReceiptRepository>()),
  );
  getIt.registerLazySingleton<ScanReceipt>(
    () => ScanReceipt(getIt<ReceiptScanner>(), getIt<CategoryRepository>()),
  );
  getIt.registerLazySingleton<ParseReceiptText>(
    () => ParseReceiptText(getIt<CategoryRepository>()),
  );

  getIt.registerLazySingleton<WatchBudgets>(
    () => WatchBudgets(getIt<BudgetRepository>()),
  );
  getIt.registerLazySingleton<SaveBudget>(
    () => SaveBudget(getIt<BudgetRepository>()),
  );
  getIt.registerLazySingleton<DeleteBudget>(
    () => DeleteBudget(getIt<BudgetRepository>()),
  );
  getIt.registerLazySingleton<WatchBudgetProgress>(
    () => WatchBudgetProgress(
      getIt<BudgetRepository>(),
      getIt<CategoryRepository>(),
      getIt<TransactionRepository>(),
    ),
  );

  getIt.registerLazySingleton<WatchDashboard>(
    () => WatchDashboard(
      getIt<SettingsRepository>(),
      getIt<WalletRepository>(),
      getIt<TransactionRepository>(),
      getIt<CategoryRepository>(),
      getIt<BudgetRepository>(),
      getIt<ReceiptRepository>(),
      getIt<TeamRepository>(),
    ),
  );

  getIt.registerLazySingleton<WatchReports>(
    () => WatchReports(getIt<InsightRepository>()),
  );
  getIt.registerLazySingleton<GenerateInvestigation>(
    () => GenerateInvestigation(getIt<InsightRepository>()),
  );
  getIt.registerLazySingleton<WatchRecurringRules>(
    () => WatchRecurringRules(getIt<RecurringRepository>()),
  );
  getIt.registerLazySingleton<SaveRecurringRule>(
    () => SaveRecurringRule(getIt<RecurringRepository>()),
  );
  getIt.registerLazySingleton<DeleteRecurringRule>(
    () => DeleteRecurringRule(getIt<RecurringRepository>()),
  );
  getIt.registerLazySingleton<RunDueRecurring>(
    () => RunDueRecurring(
      getIt<RecurringRepository>(),
      getIt<TransactionRepository>(),
      getIt<NotificationService>(),
    ),
  );
  getIt.registerLazySingleton<ExportLedger>(
    () => ExportLedger(
      getIt<TransactionRepository>(),
      getIt<WalletRepository>(),
      getIt<ExportRepository>(),
    ),
  );
  getIt.registerLazySingleton<WatchSyncStatus>(
    () => WatchSyncStatus(getIt<SyncRepository>()),
  );
  getIt.registerLazySingleton<SyncNow>(() => SyncNow(getIt<SyncRepository>()));
  getIt.registerLazySingleton<CheckBiometrics>(
    () => CheckBiometrics(getIt<BiometricService>()),
  );
  getIt.registerLazySingleton<UnlockWithBiometrics>(
    () => UnlockWithBiometrics(getIt<BiometricService>()),
  );
  getIt.registerLazySingleton<CheckBudgetAlerts>(
    () => CheckBudgetAlerts(
      getIt<BudgetRepository>(),
      getIt<CategoryRepository>(),
      getIt<TransactionRepository>(),
      getIt<AlertRepository>(),
    ),
  );
  getIt.registerLazySingleton<SendBudgetAlert>(
    () => SendBudgetAlert(getIt<NotificationService>()),
  );
  getIt.registerLazySingleton<SendCaseAlert>(
    () => SendCaseAlert(getIt<NotificationService>()),
  );
  getIt.registerLazySingleton<AppMaintenance>(
    () => AppMaintenance(
      getIt<RunDueRecurring>(),
      getIt<CheckBudgetAlerts>(),
      getIt<SendBudgetAlert>(),
      getIt<NotificationService>(),
    ),
  );
}

void _registerBlocs() {
  getIt.registerLazySingleton<SettingsBloc>(
    () => SettingsBloc(
      getIt<WatchSettings>(),
      getIt<GetSettings>(),
      getIt<UpdateSettings>(),
    ),
  );
  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      getIt<WatchAuthUser>(),
      getIt<SignInWithEmail>(),
      getIt<SignUpWithEmail>(),
      getIt<SignInWithGoogle>(),
      getIt<ContinueAsDemo>(),
      getIt<SignOut>(),
      getIt<AuthRepository>(),
    ),
  );
  getIt.registerLazySingleton<SyncBloc>(
    () => SyncBloc(getIt<WatchSyncStatus>(), getIt<SyncNow>()),
  );

  getIt.registerFactory<DashboardBloc>(
    () => DashboardBloc(getIt<WatchDashboard>()),
  );
  getIt.registerFactory<LedgerBloc>(
    () => LedgerBloc(
      getIt<WatchLedger>(),
      getIt<WatchWallets>(),
      getIt<WatchCategories>(),
      getIt<SaveTransaction>(),
      getIt<DeleteTransaction>(),
    ),
  );
  getIt.registerFactoryParam<TransactionFormBloc, String?, void>(
    (transactionId, _) => TransactionFormBloc(
      getIt<WatchWallets>(),
      getIt<WatchCategories>(),
      getIt<GetLedgerEntry>(),
      getIt<SaveTransaction>(),
      getIt<DeleteTransaction>(),
      getIt<GetCurrentUser>(),
      transactionId,
      uuid: getIt<Uuid>(),
    ),
  );
  getIt.registerFactory<BudgetBloc>(
    () => BudgetBloc(
      getIt<WatchBudgetProgress>(),
      getIt<WatchCategories>(),
      getIt<SaveBudget>(),
      getIt<DeleteBudget>(),
      getIt<NotificationService>(),
    ),
  );
  getIt.registerFactory<ReportBloc>(
    () => ReportBloc(
      getIt<WatchReports>(),
      getIt<GenerateInvestigation>(),
      getIt<ExportLedger>(),
      getIt<GetSettings>(),
    ),
  );
  getIt.registerFactory<EvidenceBloc>(
    () => EvidenceBloc(
      getIt<WatchReceipts>(),
      getIt<ScanReceipt>(),
      getIt<ParseReceiptText>(),
      getIt<SaveReceipt>(),
      getIt<DeleteReceipt>(),
      getIt<LoadReceiptImage>(),
    ),
  );
  getIt.registerFactory<TeamBloc>(
    () => TeamBloc(
      getIt<WatchWallets>(),
      getIt<WatchTeam>(),
      getIt<SendCaseNote>(),
      getIt<CreateWalletInvite>(),
      getIt<JoinSharedWallet>(),
      getIt<GetCurrentUser>(),
      uuid: getIt<Uuid>(),
    ),
  );
  getIt.registerFactory<SettingsDataBloc>(
    () => SettingsDataBloc(
      getIt<WatchWallets>(),
      getIt<WatchCategories>(),
      getIt<WatchRecurringRules>(),
      getIt<WatchTransactions>(),
      getIt<SaveWallet>(),
      getIt<DeleteWallet>(),
      getIt<SaveCategory>(),
      getIt<DeleteCategory>(),
      getIt<SaveRecurringRule>(),
      getIt<DeleteRecurringRule>(),
      getIt<RunDueRecurring>(),
    ),
  );
}
