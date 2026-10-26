import 'package:flutter/material.dart';

/// Lightweight, compile-safe localization for the two supported languages.
///
/// Keeping the dictionary in Dart makes it easy to use translated strings in
/// tests without generating code, while `t(id, en)` keeps every screen explicit
/// about both languages.
class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const List<Locale> supportedLocales = [Locale('id'), Locale('en')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  bool get isId => locale.languageCode != 'en';

  String t(String id, String en) => isId ? id : en;

  String get languageName => isId ? 'Bahasa Indonesia' : 'English';

  String get appName => 'Dompetektif';

  String get tagline =>
      t('Usut tuntas ke mana uangmu pergi.', 'Follow every rupiah to its end.');

  String get dashboard => t('Meja Kasus', 'Case Desk');

  String get ledger => t('Berkas', 'Ledger');

  String get evidence => t('Barang Bukti', 'Evidence');

  String get reports => t('Laporan', 'Reports');

  String get team => t('Tim Investigasi', 'Investigation Team');

  String get settings => t('Pengaturan', 'Settings');

  String get budgets => t('Batas TKP', 'Crime Scene Limits');

  String get wallets => t('Dompet', 'Wallets');

  String get categories => t('Kategori', 'Categories');

  String get recurring => t('Transaksi Berulang', 'Recurring');

  String get overview => t('Ringkasan', 'Overview');

  String get totalBalance => t('Total saldo', 'Total balance');

  String get thisMonth => t('Bulan ini', 'This month');

  String get lastMonth => t('Bulan lalu', 'Last month');

  String get income => t('Pemasukan', 'Income');

  String get expense => t('Pengeluaran', 'Expense');

  String get transfer => t('Transfer', 'Transfer');

  String get net => t('Selisih bersih', 'Net difference');

  String get netShort => t('Bersih', 'Net');

  String get recentEvidence => t('Struk terbaru', 'Recent receipts');

  String get recentCases => t('Transaksi terbaru', 'Recent transactions');

  String get budgetWatch => t('Pantauan batas', 'Limit watch');

  String get suspiciousCases => t('Kasus mencurigakan', 'Suspicious cases');

  String get cashflow => t('Arus kas', 'Cash flow');

  String get categoryBreakdown => t('Peta kebocoran', 'Leak map');

  String get teamActivity => t('Catatan tim', 'Case notes');

  String get quickActions => t('Aksi cepat', 'Quick actions');

  String get addTransaction => t('Catat transaksi', 'Record transaction');

  String get scanReceipt => t('Scan struk', 'Scan receipt');

  String get newCase => t('Berkas baru', 'New case');

  String get search =>
      t('Cari toko, catatan, atau nominal…', 'Search shop, note, or amount…');

  String get all => t('Semua', 'All');

  String get filters => t('Filter', 'Filters');

  String get clearFilters => t('Hapus filter', 'Clear filters');

  String get noTransactions =>
      t('Belum ada transaksi.', 'No transactions yet.');

  String get noEvidence => t(
    'Belum ada struk. Yuk, scan struk pertamamu.',
    'No receipts yet. Scan your first one.',
  );

  String get noReports => t('Belum ada laporan.', 'No reports yet.');

  String get noBudgets =>
      t('Belum ada batas bulan ini.', 'No limits this month.');

  String get noNotes => t('Belum ada catatan tim.', 'No case notes yet.');

  String get noMembers => t('Belum ada anggota tim.', 'No team members yet.');

  String get add => t('Tambah', 'Add');

  String get save => t('Simpan', 'Save');

  String get cancel => t('Batal', 'Cancel');

  String get delete => t('Hapus', 'Delete');

  String get edit => t('Ubah', 'Edit');

  String get close => t('Tutup', 'Close');

  String get back => t('Kembali', 'Back');

  String get continueLabel => t('Lanjut', 'Continue');

  String get confirm => t('Konfirmasi', 'Confirm');

  String get loading => t('Menyiapkan…', 'Getting ready…');

  String get retry => t('Coba lagi', 'Try again');

  String get somethingWrong => t(
    'Ada yang tidak beres saat membuka halaman ini.',
    'Something went wrong while opening this page.',
  );

  String get amount => t('Nominal', 'Amount');

  String get date => t('Tanggal', 'Date');

  String get time => t('Waktu', 'Time');

  String get merchant => t('Toko', 'Shop');

  String get note => t('Catatan', 'Note');

  String get category => t('Kategori', 'Category');

  String get wallet => t('Dompet', 'Wallet');

  String get destinationWallet => t('Dompet tujuan', 'Destination wallet');

  String get type => t('Jenis', 'Type');

  String get description => t('Keterangan', 'Description');

  String get month => t('Bulan', 'Month');

  String get threshold => t('Batas peringatan', 'Alert threshold');

  String get spent => t('Terpakai', 'Spent');

  String get remaining => t('Sisa', 'Remaining');

  String get overBudget => t('Melebihi batas', 'Over limit');

  String get warning => t('Mendekati batas', 'Near limit');

  String get safe => t('Aman', 'Safe');

  String get manage => t('Kelola', 'Manage');

  String get invite => t('Undang', 'Invite');

  String get join => t('Gabung', 'Join');

  String get joinWithCode => t('Gabung dengan kode', 'Join with a code');

  String get inviteCode => t('Kode undangan', 'Invite code');

  String get copy => t('Salin', 'Copy');

  String get copied => t('Kode undangan disalin.', 'Invite code copied.');

  String get send => t('Kirim', 'Send');

  String get message => t('Tulis temuan…', 'Write a finding…');

  String get online => t('Online', 'Online');

  String get offline => t('Offline', 'Offline');

  String get demoMode => t('Mode demo lokal', 'Local demo mode');

  String get demoNotice => t(
    'Data disimpan di HP ini. Fitur kolaborasi cloud masih simulasi.',
    'Data stays on this phone. Cloud collaboration is still simulated.',
  );

  String get cloudMode => t('Tersambung ke cloud', 'Connected to cloud');

  String get signIn => t('Masuk', 'Sign in');

  String get signUp => t('Daftar', 'Create account');

  String get signOut => t('Keluar', 'Sign out');

  String get email => t('Email', 'Email');

  String get password => t('Kata sandi', 'Password');

  String get displayName => t('Nama detektif', 'Detective name');

  String get continueWithGoogle =>
      t('Lanjutkan dengan Google', 'Continue with Google');

  String get continueAsDemo =>
      t('Masuk sebagai detektif demo', 'Enter as demo detective');

  String get authTitle =>
      t('Buka berkas keuanganmu.', 'Open your financial case file.');

  String get authSubtitle => t(
    'Setiap transaksi adalah barang bukti. Dompetektif membantumu menemukan kebocoran sebelum jadi kebiasaan.',
    'Every transaction is evidence. Dompetektif helps you spot leaks before they become habits.',
  );

  String get noAccount => t('Belum punya akun?', 'No account yet?');

  String get haveAccount => t('Sudah punya akun?', 'Already have an account?');

  String get passwordHint => t('Minimal 6 karakter', 'At least 6 characters');

  String get invalidEmail =>
      t('Masukkan email yang valid.', 'Enter a valid email.');

  String get passwordTooShort => t(
    'Kata sandi minimal 6 karakter.',
    'Password must be at least 6 characters.',
  );

  String get nameRequired =>
      t('Nama detektif wajib diisi.', 'Detective name is required.');

  String get amountRequired =>
      t('Nominal harus lebih dari nol.', 'Amount must be greater than zero.');

  String get walletRequired =>
      t('Pilih dompet dulu.', 'Choose a wallet first.');

  String get categoryRequired => t('Pilih kategori.', 'Choose a category.');

  String get destinationRequired => t(
    'Pilih dompet tujuan untuk transfer.',
    'Choose a destination wallet for transfers.',
  );

  String get sameWalletError => t(
    'Dompet tujuan harus berbeda.',
    'Destination wallet must be different.',
  );

  String get deleteTransactionTitle =>
      t('Hapus transaksi ini?', 'Delete this transaction?');

  String get deleteTransactionBody => t(
    'Transaksinya dihapus dari HP ini dan dari cloud.',
    'It will be removed from this phone and from the cloud.',
  );

  String get deleteReceiptTitle =>
      t('Hapus struk ini?', 'Delete this receipt?');

  String get deleteReceiptBody => t(
    'Foto struk dan hasil bacaannya ikut terhapus.',
    'The photo and its reading will be deleted too.',
  );

  String get deleteWalletTitle => t('Hapus dompet?', 'Delete this wallet?');

  String get deleteWalletBody => t(
    'Riwayat transaksinya tetap ada, tapi dompet ini tidak muncul lagi di ringkasan.',
    'Transaction history stays, but this wallet will no longer show in summaries.',
  );

  String get deleteCategoryTitle =>
      t('Hapus kategori?', 'Delete this category?');

  String get deleteCategoryBody => t(
    'Transaksi lama tetap pakai nama kategori ini, tapi kamu tidak bisa memilihnya lagi.',
    'Older transactions keep this category name, but you can no longer pick it.',
  );

  String get deleteBudgetTitle => t('Hapus batas ini?', 'Delete this limit?');

  String get deleteBudgetBody => t(
    'Pemantauan batas kategori ini akan dihentikan.',
    'This category will stop being monitored.',
  );

  String get deleteRecurringTitle =>
      t('Hapus transaksi berulang?', 'Delete this recurring rule?');

  String get deleteRecurringBody => t(
    'Transaksi yang sudah dibuat tidak ikut terhapus.',
    'Transactions already created are not deleted.',
  );

  String get unsavedChanges => t(
    'Perubahanmu belum disimpan. Tetap keluar?',
    'Your changes are not saved. Leave anyway?',
  );

  String get budgetAlertTitle =>
      t('Batas TKP hampir jebol', 'Limit almost breached');

  String budgetWarning(String category, String percent) => t(
    'Pengeluaran $category sudah $percent dari batasnya.',
    '$category spending is at $percent of its limit.',
  );

  String budgetOver(String category) => t(
    'Kebocoran di $category: batasnya sudah terlampaui.',
    'Leak in $category: the limit is already exceeded.',
  );

  String anomalyHeadline(String category) =>
      t('Ada kebocoran di $category', 'A leak showed up in $category');

  String anomalyBody(String merchant, String amount) => t(
    'Transaksi $merchant sebesar $amount jauh di atas kebiasaanmu.',
    'The $merchant transaction of $amount is way above your usual.',
  );

  String get reportGenerate => t('Buat laporan', 'Create report');

  String get reportGenerating => t('Menyusun laporan…', 'Building report…');

  String get reportLocalSource => t('Analisis lokal', 'Local analysis');

  String get reportAiSource => t('Analisis AI', 'AI analysis');

  String get reportSourceNote => t(
    'Pilih periode yang mau diusut. Hasilnya bisa langsung kamu baca dan ekspor.',
    'Pick a period to dig into. Read the result right away or export it.',
  );

  String get cloudNotice => t(
    'Data tersimpan aman di cloud dan tersinkron antar perangkat.',
    'Your data is stored safely in the cloud and synced across devices.',
  );

  String get findings => t('Temuan', 'Findings');

  String get nextSteps => t('Langkah berikutnya', 'Next steps');

  String get info => t('Info', 'Info');

  String get recommendations => t('Saran', 'Suggestions');

  String get anomalies => t('Anomali', 'Anomalies');

  String get noAnomalies =>
      t('Tidak ada yang mencurigakan.', 'Nothing looks suspicious.');

  String get exportPdf => t('Ekspor PDF', 'Export PDF');

  String get exportCsv => t('Ekspor CSV', 'Export CSV');

  String get exportSuccess => t('File berhasil dibuat.', 'File created.');

  String get budgetsSubtitle => t(
    'Tentukan batas wajar tiap kategori. Detektif akan mengingatkan sebelum kebocoran makin besar.',
    'Set a sensible limit per category. The detective warns you before a leak gets bigger.',
  );

  String get budgetCreate => t('Pasang batas', 'Set a limit');

  String get budgetEdit => t('Ubah batas', 'Edit limit');

  String get budgetThresholdHint => t(
    'Kamu akan dapat peringatan begitu pemakaian melewati angka ini.',
    'You get a warning once spending crosses this number.',
  );

  String get receiptScanTitle => t('Scan struk', 'Scan receipt');

  String get receiptHeaderTitle => t('Barang bukti baru', 'New evidence');

  String get receiptCaptureTitle => t('Foto struk', 'Photograph the receipt');

  String get scanAgain => t('Ulang', 'Redo');

  String get noEvidenceBody => t(
    'Scan dari kamera atau pilih foto dari galeri. Hasilnya bisa kamu cek dulu sebelum disimpan.',
    'Scan with the camera or pick a photo from the gallery. You can check the result before saving.',
  );

  String get receiptScanSubtitle => t(
    'Foto struk, lalu detektif akan membaca toko, total, tanggal, dan kategorinya. Semua masih bisa kamu koreksi.',
    'Photograph the receipt and the detective will read the shop, total, date, and category. You can still fix anything.',
  );

  String get pickFromGallery => t('Pilih dari galeri', 'Pick from gallery');

  String get takePhoto => t('Ambil foto', 'Take photo');

  String get pasteReceipt => t('Tempel teks struk', 'Paste receipt text');

  String get pasteReceiptHint => t(
    'Scan kamera hanya ada di aplikasi Android. Di sini, tempel saja teks struknya.',
    'Camera scanning is Android-only. Paste the receipt text here instead.',
  );

  String get analyzeText => t('Baca teks', 'Read text');

  String get ocrUnsupported => t(
    'Kamera belum tersedia di perangkat ini. Tempel teks struknya saja.',
    'The camera is not available here. Paste the receipt text instead.',
  );

  String get receiptReview => t('Cek hasil scan', 'Check the scan');

  String get attachToTransaction =>
      t('Jadikan transaksi', 'Turn into transaction');

  String get saveEvidence => t('Simpan struk', 'Save receipt');

  String get savedEvidence => t('Struk tersimpan.', 'Receipt saved.');

  String get rawText => t('Teks struk', 'Receipt text');

  String get items => t('Item', 'Items');

  String get noItems => t('Tidak ada item yang terbaca.', 'No items detected.');

  String get confidence => t('Terbaca', 'Accuracy');

  String get receiptAttached =>
      t('Sudah jadi transaksi', 'Turned into a transaction');

  String get receiptDraft => t('Belum jadi transaksi', 'Not a transaction yet');

  String get teamSubtitle => t(
    'Diskusikan temuan, lihat siapa yang online, dan simpan semua keputusan di satu tempat.',
    'Discuss findings, see who is online, and keep every decision in one place.',
  );

  String get sharedWallets => t('Dompet bersama', 'Shared wallets');

  String get createSharedWallet =>
      t('Buat dompet bersama', 'Create shared wallet');

  String get noSharedWallet => t(
    'Belum ada dompet bersama. Buat satu untuk mulai berkolaborasi.',
    'No shared wallet yet. Create one to start collaborating.',
  );

  String get caseNotes => t('Catatan kasus', 'Case notes');

  String get members => t('Anggota', 'Members');

  String get inviteMember => t('Undang anggota', 'Invite member');

  String get joinWalletTitle =>
      t('Gabung dompet bersama', 'Join a shared wallet');

  String get joinWalletHint =>
      t('Masukkan kode undangan', 'Enter the invite code');

  String get invalidInvite =>
      t('Kode undangan tidak valid.', 'That invite code is not valid.');

  String get joinedWallet => t(
    'Kamu berhasil bergabung. Sedang mengambil data dompet…',
    'You are in. Pulling wallet data…',
  );

  String get settingsSubtitle => t(
    'Atur profil, tampilan, keamanan, dan datamu.',
    'Manage your profile, appearance, security, and data.',
  );

  String get appearance => t('Tampilan', 'Appearance');

  String get theme => t('Tema', 'Theme');

  String get themeDark => t('Gelap', 'Dark');

  String get themeLight => t('Terang', 'Light');

  String get themeSystem => t('Ikuti sistem', 'System');

  String get themeSystemShort => t('Sistem', 'System');

  String get language => t('Bahasa', 'Language');

  String get security => t('Keamanan', 'Security');

  String get biometric => t('Kunci biometrik', 'Biometric lock');

  String get biometricSubtitle => t(
    'Minta sidik jari atau wajah setiap kali membuka aplikasi.',
    'Ask for a fingerprint or face every time the app opens.',
  );

  String get biometricUnavailable => t(
    'Biometrik tidak tersedia di perangkat ini.',
    'Biometrics are unavailable on this device.',
  );

  String get biometricReason => t('Buka Dompetektif', 'Open Dompetektif');

  String get privacy => t('Privasi nominal', 'Amount privacy');

  String get hideAmounts => t('Sembunyikan nominal', 'Hide amounts');

  String get hideAmountsSubtitle => t(
    'Nominal diganti •••••• supaya aman dilihat orang lain.',
    'Amounts turn into •••••• so others cannot read them.',
  );

  String get data => t('Data & sinkronisasi', 'Data & sync');

  String get cloudStatus => t('Status cloud', 'Cloud status');

  String get syncNow => t('Sinkronkan sekarang', 'Sync now');

  String get lastSynced => t('Terakhir disinkronkan', 'Last synced');

  String get neverSynced => t('Belum pernah', 'Never');

  String get pendingChanges => t('Perubahan tertunda', 'Pending changes');

  String get noPendingChanges =>
      t('Semua perubahan sudah terkirim.', 'All changes are delivered.');

  String get offlineNotice => t(
    'Tidak ada koneksi. Perubahanmu disimpan di HP dan dikirim otomatis begitu online.',
    'No connection. Your changes stay on this phone and go out automatically once you are back online.',
  );

  String get exportData => t('Ekspor data', 'Export data');

  String get exportDataSubtitle => t(
    'Unduh PDF atau CSV untuk arsip dan pengecekan.',
    'Download PDF or CSV for your archive and checks.',
  );

  String get account => t('Akun', 'Account');

  String get about => t('Tentang', 'About');

  String get version => t('Versi', 'Version');

  String get aboutBody => t(
    'Dompetektif adalah pelacak pengeluaran bergaya investigasi. Datamu milikmu; mode lokal tetap jalan tanpa cloud.',
    'Dompetektif is an expense tracker with a detective twist. Your data is yours, and local mode works without the cloud.',
  );

  String get demoData => t('Data demo', 'Demo data');

  String get resetDemo => t('Reset data demo', 'Reset demo data');

  String get resetDemoBody => t(
    'Semua data demo di HP ini akan dihapus lalu dibuat ulang.',
    'All demo data on this phone will be erased and rebuilt.',
  );

  String get reset => t('Reset', 'Reset');

  String get walletName => t('Nama dompet', 'Wallet name');

  String get openingBalance => t('Saldo awal', 'Opening balance');

  String get walletType => t('Jenis dompet', 'Wallet type');

  String get cash => t('Tunai', 'Cash');

  String get bank => t('Bank', 'Bank');

  String get ewallet => t('E-wallet', 'E-wallet');

  String get sharedWallet => t('Dompet bersama', 'Shared wallet');

  String get sharedWalletSubtitle => t(
    'Anggota lain bisa melihat dan mencatat transaksi.',
    'Other members can view and record transactions.',
  );

  String get walletCreate => t('Tambah dompet', 'Add wallet');

  String get walletEdit => t('Ubah dompet', 'Edit wallet');

  String get categoryName => t('Nama kategori', 'Category name');

  String get categoryKind => t('Jenis kategori', 'Category type');

  String get categoryKeywords => t('Kata kunci struk', 'Receipt keywords');

  String get categoryKeywordsHint => t(
    'Pisahkan dengan koma, misalnya: kopi, kafe, resto',
    'Separate with commas, for example: coffee, cafe, resto',
  );

  String get categoryCreate => t('Tambah kategori', 'Add category');

  String get categoryEdit => t('Ubah kategori', 'Edit category');

  String get systemCategory => t('Bawaan', 'Built-in');

  String get customCategory => t('Kustom', 'Custom');

  String get recurringCreate =>
      t('Tambah transaksi berulang', 'Add recurring transaction');

  String get recurringEdit =>
      t('Ubah transaksi berulang', 'Edit recurring transaction');

  String get frequency => t('Frekuensi', 'Frequency');

  String get daily => t('Harian', 'Daily');

  String get weekly => t('Mingguan', 'Weekly');

  String get monthly => t('Bulanan', 'Monthly');

  String get yearly => t('Tahunan', 'Yearly');

  String get nextRun => t('Jadwal berikutnya', 'Next run');

  String get nextRunShort => t('Jadwal', 'Next');

  String get active => t('Aktif', 'Active');

  String get inactive => t('Nonaktif', 'Inactive');

  String get runDue => t('Proses yang jatuh tempo', 'Run what is due');

  String get dueCompleted => t(
    'Transaksi berulang sudah dijalankan.',
    'Recurring transactions are done.',
  );

  String get noDue =>
      t('Tidak ada transaksi yang jatuh tempo.', 'Nothing is due yet.');

  String get monthCurrent => t('Bulan ini', 'This month');

  String get monthPrevious => t('Bulan lalu', 'Last month');

  String get generate => t('Buat laporan', 'Create');

  String get generating => t('Menyusun…', 'Generating…');

  String get reportPeriod => t('Periode laporan', 'Report period');

  String get reportHeadline => t('Judul laporan', 'Report headline');

  String get reportSummary => t('Ringkasan', 'Summary');

  String get source => t('Sumber', 'Source');

  String get generatedAt => t('Disusun pada', 'Generated at');

  String get createdAtLabel => t('Dibuat pada', 'Created at');

  String get updatedAtLabel => t('Diperbarui pada', 'Updated at');

  String get insightEmptyTitle =>
      t('Belum ada laporan untuk periode ini', 'No report for this period yet');

  String get insightEmptyBody => t(
    'Buat laporan untuk melihat pola pengeluaran, kebocoran kategori, dan saran yang bisa langsung kamu jalankan.',
    'Create a report to see spending patterns, category leaks, and suggestions you can act on.',
  );

  String get saveTransactionSuccess =>
      t('Transaksi tersimpan.', 'Transaction saved.');

  String get saveTransaction => t('Simpan transaksi', 'Save transaction');

  String get deleteSuccess => t('Data dihapus.', 'Deleted.');

  String get syncDone => t('Sinkronisasi selesai.', 'Sync complete.');

  String get syncFailed =>
      t('Sinkronisasi gagal. Coba lagi.', 'Sync failed. Try again.');

  String get locked => t('Aplikasi terkunci', 'App locked');

  String get unlock => t('Buka dengan biometrik', 'Unlock with biometrics');

  String get unlocked => t('Aplikasi terbuka.', 'App unlocked.');

  String get signOutConfirm =>
      t('Keluar dari akun ini?', 'Sign out of this account?');

  String get signOutBody => t(
    'Kamu akan keluar dan data lokal di HP ini dibersihkan. Data di cloud tetap aman.',
    'You will be signed out and local data on this phone cleared. Cloud data stays safe.',
  );

  String get welcomeDetective =>
      t('Selamat datang, Detektif', 'Welcome, Detective');

  String get caseFile => t('BERKAS', 'CASE FILE');

  String get confidential => t('RAHASIA', 'CONFIDENTIAL');

  String get evidenceCount => t('struk', 'receipts');

  String get caseCount => t('transaksi', 'transactions');

  String get viewAll => t('Lihat semua', 'View all');

  String get activeWallet => t('Dompet aktif', 'Active wallet');

  String get allWallets => t('Semua dompet', 'All wallets');

  String get totalSpent => t('Total pengeluaran', 'Total spent');

  String get previousMonthComparison =>
      t('dibanding bulan lalu', 'vs last month');

  String get lessThanLastMonth =>
      t('lebih hemat dari bulan lalu', 'less than last month');

  String get moreThanLastMonth =>
      t('lebih besar dari bulan lalu', 'more than last month');

  String get topMerchants => t('Toko teratas', 'Top shops');

  String get noMerchants => t('Belum ada toko.', 'No shops yet.');

  String get caseNoteHint =>
      t('Tulis temuan untuk tim…', 'Write a finding for the team…');

  String get teamOnlyShared => t(
    'Pilih dompet bersama untuk membuka ruang diskusi.',
    'Select a shared wallet to open the discussion room.',
  );

  String get createFirstWallet =>
      t('Buat dompet pertama', 'Create your first wallet');

  String get createFirstWalletBody => t(
    'Setelah dompet dibuat, kamu bisa mencatat transaksi dan memasang batas.',
    'Once a wallet exists, you can record transactions and set limits.',
  );

  String get demoSeedReady =>
      t('Data demo siap diusut.', 'Demo case files are ready.');

  String get today => t('Hari ini', 'Today');

  String get yesterday => t('Kemarin', 'Yesterday');

  String get unknownDate => t('Tanggal tidak dikenal', 'Unknown date');

  String get unknownMerchant => t('Toko tidak dikenal', 'Unknown shop');

  String get transferFromTo => t('Transfer antar dompet', 'Wallet transfer');

  String get evidenceLinked => t('Terhubung', 'Linked');

  String get status => t('Status', 'Status');

  String get details => t('Rincian', 'Details');

  String get result => t('Hasil', 'Result');

  String get analysis => t('Analisis', 'Analysis');

  String get localOnly => t('Lokal', 'Local');

  String get cloudOnly => t('Cloud', 'Cloud');

  String get upcoming => t('Mendatang', 'Upcoming');

  String get deleted => t('Terhapus', 'Deleted');

  String get collapse => t('Tutup rincian', 'Collapse');

  String get expand => t('Buka rincian', 'Expand');

  String get or => t('atau', 'or');

  String get requiredField => t('Wajib diisi', 'Required');

  String get invalidAmount => t('Nominal tidak valid.', 'Invalid amount.');

  String get noWallet => t('Buat dompet dulu', 'Create a wallet first');

  String get noCategories => t('Belum ada kategori.', 'No categories yet.');

  String get allTime => t('Sepanjang waktu', 'All time');

  String get period => t('Periode', 'Period');

  String get from => t('Dari', 'From');

  String get to => t('Sampai', 'To');

  String get selectDate => t('Pilih tanggal', 'Select date');

  String get selectMonth => t('Pilih bulan', 'Select month');

  String get localImageUnavailable => t(
    'Gambar struk tidak tersedia di perangkat ini.',
    'Receipt image is unavailable on this device.',
  );

  String get remoteImage =>
      t('Gambar tersimpan di cloud', 'Image stored in the cloud');

  String get attachReceipt => t('Lampirkan struk', 'Attach receipt');

  String get removeReceipt => t('Lepas struk', 'Remove receipt');

  String get transactionSaved =>
      t('Transaksi tersimpan.', 'Transaction saved.');

  String get saving => t('Menyimpan…', 'Saving…');

  String get analyzing => t('Membaca struk…', 'Reading receipt…');

  String get scanHintAndroid => t(
    'Taruh struk di tempat terang dan pastikan tulisannya kelihatan. Semua diproses di HP kamu, bukan di cloud.',
    'Put the receipt in good light and keep the text visible. Everything runs on your phone, not in the cloud.',
  );

  String get cameraUnavailable => t(
    'Kamera hanya bisa dipakai di aplikasi Android.',
    'The camera only works in the Android app.',
  );

  String get scanFailed => t(
    'Struknya belum terbaca. Coba foto ulang, atau tempel teksnya.',
    'Could not read the receipt. Try another photo, or paste the text.',
  );

  String get parseFailed =>
      t('Teks struknya belum bisa dibaca.', 'Could not read the receipt text.');

  String get noTextDetected => t(
    'Tidak ada teks yang terbaca di gambar itu.',
    'No text was found in that image.',
  );

  String get receiptMerchantHint => t('Nama toko', 'Shop name');

  String get receiptTotalHint => t('Total struk', 'Receipt total');

  String get receiptDateHint => t('Tanggal struk', 'Receipt date');

  String get receiptCategoryHint =>
      t('Kategori yang disarankan', 'Suggested category');

  String get saveAsDraft => t('Simpan sebagai draf', 'Save as draft');

  String get createTransactionFromReceipt =>
      t('Buat transaksi dari struk', 'Create transaction from receipt');

  String get transactionFromReceiptHint => t(
    'Nominal, toko, tanggal, dan kategori sudah diisi otomatis. Cek lagi sebelum menyimpan.',
    'Amount, shop, date, and category are filled in for you. Check them before saving.',
  );

  String get teamPresence => t('Sedang online', 'Online now');

  String get noteSent => t('Catatan terkirim.', 'Note sent.');

  String get inviteCreated =>
      t('Kode undangan siap dibagikan.', 'Invite code ready to share.');

  String get walletCreated => t('Dompet tersimpan.', 'Wallet saved.');

  String get categoryCreated => t('Kategori tersimpan.', 'Category saved.');

  String get budgetCreated => t('Batas TKP tersimpan.', 'Limit saved.');

  String get recurringCreated =>
      t('Transaksi berulang tersimpan.', 'Recurring rule saved.');

  String get errorEmailInUse => t(
    'Email sudah terdaftar. Coba masuk atau gunakan email lain.',
    'Email is already registered. Sign in or use another email.',
  );

  String get errorInvalidCredentials => t(
    'Email atau kata sandi tidak cocok.',
    'Email or password is incorrect.',
  );

  String get errorEmailNotConfirmed => t(
    'Cek emailmu untuk konfirmasi akun sebelum masuk.',
    'Check your email to confirm the account, then sign in.',
  );

  String get errorEmailRateLimit => t(
    'Terlalu banyak percobaan email. Tunggu sebentar, lalu coba lagi—atau masuk dengan Google.',
    'Too many email attempts. Wait a moment, then try again—or continue with Google.',
  );

  String get errorNetwork => t(
    'Jaringan bermasalah. Cek koneksimu lalu coba lagi.',
    'Network problem. Check your connection and try again.',
  );

  String get errorAuthGeneric =>
      t('Gagal masuk. Coba lagi.', 'Could not sign in. Try again.');

  String get errorDemoDisabled => t(
    'Mode demo tidak bisa dipakai saat cloud aktif.',
    'Demo mode is unavailable while the cloud is on.',
  );

  String get errorCloudNotConfigured => t(
    'Cloud belum diatur. Pakai mode demo dulu, atau hubungi admin.',
    'The cloud is not set up. Use demo mode for now, or ask your admin.',
  );

  String get oauthRedirectHint => t(
    'Kamu akan diarahkan ke browser untuk masuk dengan Google. Setelah selesai, kembali ke aplikasi ini.',
    'You will be sent to the browser to sign in with Google. Come back to the app when done.',
  );

  String get sessionExpired => t(
    'Sesimu berakhir. Masuk lagi untuk melanjutkan.',
    'Your session expired. Sign in again to continue.',
  );

  String get passwordReset => t('Lupa kata sandi?', 'Forgot password?');

  String get passwordResetHint => t(
    'Reset kata sandi belum ada di aplikasi. Hubungi admin kalau butuh bantuan.',
    'Password reset is not in the app yet. Ask the admin for help.',
  );

  String get reportWalletScope => t('Cakupan dompet', 'Wallet scope');

  String get allWalletsScope => t('Semua dompet', 'All wallets');

  String get exportIncludes => t('File akan memuat', 'The file will include');

  String get transactions => t('transaksi', 'transactions');

  String get chooseFormat => t('Pilih format', 'Choose format');

  String get pdfFormat => t('PDF — siap cetak', 'PDF — print ready');

  String get csvFormat => t('CSV — siap olah', 'CSV — spreadsheet ready');

  String get reportExportHint => t(
    'Ekspor memakai periode laporan yang sedang kamu buka.',
    'Export uses the period of the report you have open.',
  );

  String get evidenceVault => t('Lemari barang bukti', 'Evidence vault');

  String get vaultSubtitle => t(
    'Semua struk, hasil bacaan, dan tautan transaksinya ada di sini.',
    'Every receipt, its reading, and its transaction link in one place.',
  );

  String get scanNow => t('Scan sekarang', 'Scan now');

  String get draft => t('Draf', 'Draft');

  String get parsed => t('Terbaca', 'Parsed');

  String get attached => t('Terhubung', 'Attached');

  String get failed => t('Gagal', 'Failed');

  String get itemQuantity => t('Qty', 'Qty');

  String get total => t('Total', 'Total');

  String get merchantFromReceipt => t('Toko di struk', 'Shop on receipt');

  String get dateFromReceipt => t('Tanggal di struk', 'Date on receipt');

  String get totalFromReceipt => t('Total di struk', 'Total on receipt');

  String get tapToView => t('Ketuk untuk membuka', 'Tap to open');

  String get imageAvailable =>
      t('Gambar struk tersedia', 'Receipt image available');

  String get noImage => t('Tanpa gambar', 'No image');

  String get evidenceDraftSaved =>
      t('Struk disimpan sebagai draf.', 'Receipt saved as a draft.');

  String get linkedTransaction => t('Transaksi terkait', 'Linked transaction');

  String get openTransaction => t('Buka transaksi', 'Open transaction');

  String get noLinkedTransaction =>
      t('Belum terhubung ke transaksi.', 'Not linked to a transaction yet.');

  String get attachToExisting =>
      t('Hubungkan ke transaksi', 'Link to a transaction');

  String get chooseTransaction => t('Pilih transaksi', 'Choose a transaction');

  String get noMatchingTransactions =>
      t('Tidak ada transaksi yang cocok.', 'No matching transactions.');

  String get connectionProblem => t(
    'Koneksi bermasalah. Data lokal tetap aman.',
    'Connection problem. Local data is safe.',
  );

  String get localDataSafe => t('Data lokal aman', 'Local data is safe');

  String get pullToRefresh => t('Tarik untuk menyegarkan', 'Pull to refresh');

  String get allCaughtUp => t('Semua sudah beres.', 'All caught up.');

  String get lightMode => t('Mode terang', 'Light mode');

  String get darkMode => t('Mode gelap', 'Dark mode');

  String get accentGold => t('Aksen emas', 'Gold accent');

  String get caseFileNumber => t('No. berkas', 'File no.');

  String get fieldNotes => t('Catatan lapangan', 'Field notes');

  String get budgetStatusSafe => t('Aman', 'Safe');

  String get budgetStatusWarning => t('Waspada', 'Watch');

  String get budgetStatusOver => t('Bocor', 'Leaking');

  String get budgetLeft => t('Sisa batas', 'Limit remaining');

  String get budgetOf => t('dari', 'of');

  String get noBudgetThisMonth => t(
    'Belum ada batas kategori ini bulan ini.',
    'No limit for this category this month.',
  );

  String get categoriesSubtitle => t(
    'Kategori bawaan bisa dipakai langsung. Tambahkan kategori kustom untuk kebiasaanmu yang khas.',
    'Built-in categories are ready to use. Add your own for habits that are uniquely yours.',
  );

  String get walletsSubtitle => t(
    'Pisahkan uang tunai, bank, dan e-wallet agar saldo tidak tertukar.',
    'Separate cash, bank, and e-wallet balances so they never blur together.',
  );

  String get recurringSubtitle => t(
    'Catat gaji, langganan, dan sewa sekali saja. Detektif akan mencatat transaksinya saat jatuh tempo.',
    'Set salary, subscriptions, and rent once. The detective records them when they are due.',
  );

  String get openSettings => t('Buka pengaturan', 'Open settings');

  String get lastActivity => t('Aktivitas terakhir', 'Last activity');

  String get noActivity => t('Belum ada aktivitas.', 'No activity yet.');

  String get errorLoadData =>
      t('Data gagal dimuat. Coba lagi.', 'Could not load data. Try again.');

  String get errorSaveData =>
      t('Data gagal disimpan. Coba lagi.', 'Could not save data. Try again.');

  String get errorDeleteData =>
      t('Data gagal dihapus. Coba lagi.', 'Could not delete data. Try again.');

  String get errorGenerateReport => t(
    'Laporan gagal dibuat. Cek koneksimu lalu coba lagi.',
    'Could not build the report. Check your connection and try again.',
  );

  String get errorExport =>
      t('Ekspor gagal. Coba lagi.', 'Export failed. Try again.');

  String get errorInvite =>
      t('Kode undangan gagal dibuat.', 'Could not create an invite code.');

  String get errorJoin => t(
    'Gagal bergabung. Cek kodenya dan koneksimu.',
    'Could not join. Check the code and your connection.',
  );

  String get errorSendNote => t(
    'Catatan gagal terkirim. Coba lagi.',
    'The note was not sent. Try again.',
  );

  String get errorOcr => t(
    'Struknya belum bisa diproses. Coba lagi.',
    'Could not process the receipt. Try again.',
  );

  String get errorBiometric => t(
    'Biometrik tidak cocok. Coba lagi.',
    'Biometric did not match. Try again.',
  );

  String get lockTitle => t('Dompetektif terkunci', 'Dompetektif is locked');

  String get lockSubtitle => t(
    'Buka pakai sidik jari atau wajah untuk melanjutkan.',
    'Use your fingerprint or face to continue.',
  );

  String get useBiometric => t('Gunakan biometrik', 'Use biometrics');

  String get signOutAnyway => t('Keluar dari akun', 'Sign out');

  String get switchAccount => t('Ganti akun', 'Switch account');

  String get syncing => t('Menyinkronkan…', 'Syncing…');

  String get onlineNow => t('Online sekarang', 'Online now');

  String get offlineNow => t('Offline', 'Offline');

  String get shared => t('Bersama', 'Shared');

  String get owner => t('Pemilik', 'Owner');

  String get editor => t('Editor', 'Editor');

  String get viewer => t('Pengamat', 'Viewer');

  String get role => t('Peran', 'Role');

  String get membersCount => t('anggota', 'members');

  String get evidenceCountShort => t('bukti', 'evidence');

  String get noData => t('Belum ada data.', 'No data yet.');

  String get closeDialog => t('Tutup dialog', 'Close dialog');

  String get previousMonth => t('Bulan sebelumnya', 'Previous month');

  String get nextMonth => t('Bulan berikutnya', 'Next month');

  String get showMore => t('Selengkapnya', 'Show more');

  String get showLess => t('Ringkas', 'Show less');

  String get share => t('Bagikan', 'Share');

  String get statusSynced => t('Tersinkron', 'Synced');

  String get statusPending => t('Menunggu', 'Pending');

  String get statusLocal => t('Lokal', 'Local');

  String get viewEvidence => t('Lihat struk', 'View receipt');

  String get viewReport => t('Lihat laporan', 'View report');

  String get unexpectedError =>
      t('Terjadi kesalahan tak terduga.', 'An unexpected error occurred.');

  String get confirmDelete => t('Ya, hapus', 'Yes, delete');

  String get confirmReset => t('Ya, reset', 'Yes, reset');

  String get demoUser => t('Detektif demo', 'Demo detective');

  String get demoEmail => t('demo@dompetektif.app', 'demo@dompetektif.app');

  String get demoWarning => t(
    'Mode demo memakai data contoh. Jangan masukkan data keuangan nyata.',
    'Demo mode uses sample data. Do not enter real financial data.',
  );

  String get connected => t('Tersambung', 'Connected');

  String get notConnected => t('Belum tersambung', 'Not connected');

  String get createAccountNow => t('Buat akun', 'Create account');

  String get signInNow => t('Masuk sekarang', 'Sign in now');

  String get securityNote => t(
    'Kunci biometrik pakai sensor HP-mu. Dompetektif tidak pernah menyimpan sidik jari atau wajahmu.',
    'Biometric lock uses your phone sensor. Dompetektif never stores your fingerprint or face.',
  );

  String get scanTip => t(
    'Tips: taruh struk di permukaan datar dan pastikan cahayanya cukup. Scan berjalan di HP, jadi datamu tetap aman.',
    'Tip: lay the receipt flat and make sure the light is good. Scanning runs on your phone, so your data stays put.',
  );

  String get evidenceSavedToVault =>
      t('Struk tersimpan di lemari bukti.', 'Receipt saved to the vault.');

  String get upToDate =>
      t('Semua data sudah mutakhir.', 'Everything is up to date.');

  String get settingsSaved => t('Pengaturan tersimpan.', 'Settings saved.');

  String get errorSettings =>
      t('Pengaturan gagal disimpan.', 'Could not save settings.');

  String get welcomeBack => t('Selamat datang kembali', 'Welcome back');

  String get caseDeskFor => t('Meja kasus untuk', 'Case desk for');

  String get noActiveWallet => t('Semua dompet', 'All wallets');

  String get transactionTypeExpense => t('Pengeluaran', 'Expense');

  String get transactionTypeIncome => t('Pemasukan', 'Income');

  String get transactionTypeTransfer => t('Transfer', 'Transfer');

  String get reportPeriodThisMonth => t('Bulan ini', 'This month');

  String get reportPeriodLastMonth => t('Bulan lalu', 'Last month');

  String get evidenceFromCamera => t('Dari kamera', 'From camera');

  String get evidenceFromGallery => t('Dari galeri', 'From gallery');

  String get receiptTextAnalyzed =>
      t('Teks struk berhasil dibaca.', 'Receipt text read.');

  String get categorySuggestion => t('Saran kategori', 'Category suggestion');

  String get useSuggestion => t('Gunakan saran', 'Use suggestion');

  String get manualEntry => t('Isi manual', 'Manual entry');

  String get receiptReviewHint => t(
    'Cek dulu hasilnya sebelum disimpan. Angka dari struk bisa salah baca.',
    'Give it a quick check before saving. Receipt numbers can be misread.',
  );

  String get evidencePreview => t('Pratinjau struk', 'Receipt preview');

  String get noPreview => t('Pratinjau tidak tersedia', 'No preview available');

  String get linkToTransaction =>
      t('Tautkan ke transaksi', 'Link to transaction');

  String get transactionLinked =>
      t('Transaksi sudah ditautkan.', 'Transaction linked.');

  String get openEvidence => t('Buka struk', 'Open receipt');

  String get reportReady =>
      t('Laporan penyelidikan siap.', 'Investigation report ready.');

  String get reportLocalNotice => t(
    'AI cloud sedang tidak aktif. Laporan tetap dibuat dengan analisis lokal, jadi tetap jalan tanpa internet.',
    'Cloud AI is off. The report still uses local analysis, so it works without internet.',
  );

  String get anomalyDeviation => t('kali di atas rata-rata', 'x above average');

  String get budgetProgress => t('Pemakaian batas', 'Limit usage');

  String get noBudgetAlerts =>
      t('Semua batas masih aman.', 'All limits are safe.');

  String get categoryLeak => t('Kebocoran kategori', 'Category leak');

  String get unusualAmount => t('Nominal tidak biasa', 'Unusual amount');

  String get alert => t('Siaga', 'Alert');

  String get watch => t('Pantau', 'Watch');

  String get allEvidence => t('Semua bukti', 'All evidence');

  String get filterByWallet => t('Filter dompet', 'Filter by wallet');

  String get filterByCategory => t('Filter kategori', 'Filter by category');

  String get filterByType => t('Filter jenis', 'Filter by type');

  String get clear => t('Bersihkan', 'Clear');

  String get apply => t('Terapkan', 'Apply');

  String get showingResults => t('hasil', 'results');

  String get searchHint => t('Cari…', 'Search…');

  String get notes => t('Catatan', 'Notes');

  String get noteBody => t('Isi catatan', 'Note body');

  String get invitationCodeCopied =>
      t('Kode undangan disalin.', 'Invite code copied.');

  String get noSharedWalletSelected => t(
    'Pilih dompet bersama untuk melihat tim.',
    'Select a shared wallet to see the team.',
  );

  String get sharedWalletHint => t(
    'Dompet bersama memungkinkan beberapa orang mencatat transaksi dan berdiskusi.',
    'Shared wallets let several people record transactions and talk it through.',
  );

  String get inviteCodeExpires => t(
    'Bagikan kode ini ke anggota tim. Berlaku 7 hari.',
    'Share this code with your team. It works for 7 days.',
  );

  String get roleOwner => t('Pemilik', 'Owner');

  String get roleEditor => t('Editor', 'Editor');

  String get roleViewer => t('Pengamat', 'Viewer');

  String get noPermission => t(
    'Peranmu tidak punya akses untuk ini.',
    'Your role does not allow this.',
  );

  String get settingsDataHeader => t('Data pendukung', 'Supporting data');

  String get settingsDataHeaderBody => t(
    'Dompet, kategori, dan transaksi berulang jadi dasar investigasimu.',
    'Wallets, categories, and recurring rules are the base of your investigation.',
  );

  String get appTaglineShort => t('Usut tuntas.', 'Follow it through.');

  String get legal => t(
    'Dompetektif bukan penasihat keuangan. Semua keputusan tetap milikmu.',
    'Dompetektif is not a financial advisor. Every decision remains yours.',
  );

  String get caseClosed => t('Kasus selesai.', 'Case closed.');

  String get open => t('Buka', 'Open');

  String get chooseColor => t('Pilih warna', 'Choose a color');

  String get currentBalance => t('Saldo saat ini', 'Current balance');

  String get chooseIcon => t('Pilih ikon', 'Choose an icon');

  String get amountInIdr => t('Nominal (Rp)', 'Amount (IDR)');

  String get incomeShort => t('Masuk', 'In');

  String get expenseShort => t('Keluar', 'Out');

  String get noWalletSelected => t('Pilih dompet', 'Select wallet');

  String get saveChanges => t('Simpan perubahan', 'Save changes');

  String get create => t('Buat', 'Create');

  String get optional => t('Opsional', 'Optional');

  String get deletePermanently => t('Hapus permanen', 'Delete permanently');

  String get notFound => t('Halaman tidak ditemukan.', 'Page not found.');

  String get backToDashboard => t('Kembali ke meja kasus', 'Back to case desk');

  String get reportNotFound =>
      t('Laporan tidak ditemukan.', 'Report not found.');

  String get receiptNotFound =>
      t('Struk tidak ditemukan.', 'Receipt not found.');

  String get onlineMembers => t('Anggota online', 'Online members');

  String get noOnlineMembers =>
      t('Belum ada yang online.', 'No one is online yet.');

  String get teamChatHint => t(
    'Tersinkron otomatis saat cloud aktif.',
    'Syncs automatically while the cloud is on.',
  );

  String get realtime => t('Realtime', 'Realtime');

  String get syncAuto => t('Sinkron otomatis', 'Auto sync');

  String get offlineFirst => t('Bisa offline', 'Works offline');

  String get localAiFallback => t('Analisis lokal', 'Local analysis');

  String get system => t('Sistem', 'System');

  String get settingsProfile => t('Profil', 'Profile');

  String get settingsProfileSubtitle => t(
    'Profil dan sesi yang sedang aktif',
    'Your profile and current session',
  );

  String get settingsAppearanceSubtitle => t(
    'Tema, bahasa, dan privasi nominal',
    'Theme, language, and amount privacy',
  );

  String get settingsSecuritySubtitle =>
      t('Kunci biometrik perangkat', 'Device biometric lock');

  String get settingsDataSubtitle =>
      t('Sinkronisasi cloud dan ekspor', 'Cloud sync and export');

  String get settingsSupportSubtitle => t(
    'Dompet, kategori, dan transaksi berulang',
    'Wallets, categories, and recurring rules',
  );

  String get tapToRetry => t('Ketuk untuk mencoba lagi', 'Tap to retry');

  String get serverError => t(
    'Server menolak permintaan. Coba lagi.',
    'The server rejected the request. Try again.',
  );

  String get genericErrorShort => t('Gagal memuat.', 'Failed to load.');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}

extension AppLocalizationContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
