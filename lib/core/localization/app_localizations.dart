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

  String get recentEvidence => t('Barang bukti terbaru', 'Recent evidence');

  String get recentCases => t('Berkas terbaru', 'Recent cases');

  String get budgetWatch => t('Pantauan Batas TKP', 'Crime scene limits');

  String get suspiciousCases => t('Kasus mencurigakan', 'Suspicious cases');

  String get cashflow => t('Arus kas', 'Cash flow');

  String get categoryBreakdown => t('Peta kebocoran', 'Leak map');

  String get teamActivity => t('Catatan tim', 'Case notes');

  String get quickActions => t('Aksi cepat', 'Quick actions');

  String get addTransaction => t('Catat transaksi', 'Record transaction');

  String get scanReceipt => t('Kumpulin Barang Bukti', 'Collect Evidence');

  String get newCase => t('Berkas baru', 'New case');

  String get search =>
      t('Cari merchant, catatan, nominal…', 'Search merchant, note, amount…');

  String get all => t('Semua', 'All');

  String get filters => t('Filter', 'Filters');

  String get clearFilters => t('Hapus filter', 'Clear filters');

  String get noTransactions =>
      t('Belum ada berkas transaksi.', 'No transactions yet.');

  String get noEvidence => t(
    'Belum ada barang bukti. Mulai dari struk terdekat.',
    'No evidence yet. Start with a nearby receipt.',
  );

  String get noReports =>
      t('Belum ada laporan penyelidikan.', 'No investigation reports yet.');

  String get noBudgets =>
      t('Belum ada Batas TKP bulan ini.', 'No limits set for this month.');

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

  String get loading => t('Menyiapkan berkas…', 'Preparing case files…');

  String get retry => t('Coba lagi', 'Try again');

  String get somethingWrong => t(
    'Ada yang tidak beres saat membuka berkas.',
    'Something went wrong while opening the file.',
  );

  String get amount => t('Nominal', 'Amount');

  String get date => t('Tanggal', 'Date');

  String get time => t('Waktu', 'Time');

  String get merchant => t('Merchant', 'Merchant');

  String get note => t('Catatan', 'Note');

  String get category => t('Kategori', 'Category');

  String get wallet => t('Dompet', 'Wallet');

  String get destinationWallet => t('Dompet tujuan', 'Destination wallet');

  String get type => t('Jenis', 'Type');

  String get description => t('Keterangan', 'Description');

  String get month => t('Bulan', 'Month');

  String get threshold => t('Ambang peringatan', 'Alert threshold');

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
    'Data tersimpan di perangkat ini. Supabase belum dikonfigurasi, jadi kolaborasi cloud berjalan dalam mode simulasi.',
    'Data stays on this device. Supabase is not configured, so cloud collaboration runs in simulation mode.',
  );

  String get cloudMode => t('Tersambung ke Supabase', 'Connected to Supabase');

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
    'Setiap transaksi adalah barang bukti. Dompetektif membantu menemukan kebocoran sebelum jadi kebiasaan.',
    'Every transaction is evidence. Dompetektif finds leaks before they become habits.',
  );

  String get noAccount => t('Belum punya berkas?', 'New to the case desk?');

  String get haveAccount =>
      t('Sudah punya berkas?', 'Already have a case file?');

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
      t('Pilih dompet terlebih dahulu.', 'Choose a wallet first.');

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
      t('Hapus berkas transaksi?', 'Delete this transaction?');

  String get deleteTransactionBody => t(
    'Transaksi akan dihapus dari perangkat dan ditandai terhapus di cloud.',
    'The transaction will be removed locally and soft-deleted in the cloud.',
  );

  String get deleteReceiptTitle =>
      t('Hapus barang bukti?', 'Delete this evidence?');

  String get deleteReceiptBody => t(
    'Gambar struk dan teks OCR akan ikut dihapus.',
    'The receipt image and OCR text will be deleted.',
  );

  String get deleteWalletTitle => t('Hapus dompet?', 'Delete this wallet?');

  String get deleteWalletBody => t(
    'Riwayat transaksi tetap tersimpan, tetapi dompet tidak lagi muncul di ringkasan.',
    'Transaction history stays, but the wallet disappears from summaries.',
  );

  String get deleteCategoryTitle =>
      t('Hapus kategori?', 'Delete this category?');

  String get deleteCategoryBody => t(
    'Transaksi lama tetap memakai nama kategori ini, tetapi kategori tidak bisa dipilih lagi.',
    'Old transactions keep this category name, but it can no longer be selected.',
  );

  String get deleteBudgetTitle => t('Hapus Batas TKP?', 'Delete this limit?');

  String get deleteBudgetBody => t(
    'Pantauan batas untuk kategori ini akan dihentikan.',
    'Monitoring for this category will stop.',
  );

  String get deleteRecurringTitle =>
      t('Hapus transaksi berulang?', 'Delete this recurring rule?');

  String get deleteRecurringBody => t(
    'Transaksi yang sudah tercipta tidak ikut dihapus.',
    'Transactions already created are not deleted.',
  );

  String get unsavedChanges => t(
    'Perubahan belum disimpan. Tinggalkan halaman?',
    'Changes are not saved. Leave this page?',
  );

  String get budgetAlertTitle =>
      t('Batas TKP terdeteksi', 'Crime scene limit reached');

  String budgetWarning(String category, String percent) => t(
    'Pengeluaran $category sudah $percent dari Batas TKP.',
    '$category spending has reached $percent of its limit.',
  );

  String budgetOver(String category) => t(
    'Kebocoran di kategori $category. Batas TKP sudah terlampaui.',
    'Leak found in $category. The limit has been exceeded.',
  );

  String anomalyHeadline(String category) =>
      t('Ada kebocoran di kategori $category', 'A leak surfaced in $category');

  String anomalyBody(String merchant, String amount) => t(
    'Transaksi $merchant sebesar $amount jauh di atas pola biasanya.',
    'The $merchant transaction of $amount is far above its usual pattern.',
  );

  String get reportGenerate =>
      t('Susun Laporan Penyelidikan', 'Build Investigation Report');

  String get reportGenerating => t('Menyusun laporan…', 'Building report…');

  String get reportLocalSource => t('Analisis lokal', 'Local analysis');

  String get reportAiSource => t('Analisis AI', 'AI analysis');

  String get reportSourceNote => t(
    'Laporan ini disusun dari data transaksi di perangkat. AI hanya menganalisis ringkasan, bukan mengubah bukti.',
    'This report is built from on-device transaction data. AI only analyzes the summary, never edits evidence.',
  );

  String get findings => t('Temuan', 'Findings');

  String get nextSteps => t('Langkah berikutnya', 'Next steps');

  String get info => t('Info', 'Info');

  String get recommendations => t('Rekomendasi', 'Recommendations');

  String get anomalies => t('Anomali', 'Anomalies');

  String get noAnomalies =>
      t('Tidak ada anomali mencolok.', 'No standout anomalies.');

  String get exportPdf => t('Ekspor PDF', 'Export PDF');

  String get exportCsv => t('Ekspor CSV', 'Export CSV');

  String get exportSuccess =>
      t('Berkas berhasil dibuat.', 'File created successfully.');

  String get budgetsSubtitle => t(
    'Tentukan batas wajar per kategori. Detektif akan memberi sinyal sebelum kebocoran membesar.',
    'Set a reasonable limit per category. The detective warns you before a leak grows.',
  );

  String get budgetCreate => t('Pasang Batas TKP', 'Set a limit');

  String get budgetEdit => t('Ubah Batas TKP', 'Edit limit');

  String get budgetThresholdHint => t(
    'Peringatan muncul saat pemakaian melewati ambang ini.',
    'A warning appears when spending crosses this threshold.',
  );

  String get receiptScanTitle =>
      t('Kumpulkan Barang Bukti', 'Collect Evidence');

  String get receiptScanSubtitle => t(
    'Foto struk, lalu biarkan detektif membaca merchant, total, tanggal, dan kategori yang paling mungkin.',
    'Photograph a receipt. The detective reads the merchant, total, date, and most likely category.',
  );

  String get pickFromGallery => t('Pilih dari galeri', 'Pick from gallery');

  String get takePhoto => t('Ambil foto', 'Take photo');

  String get pasteReceipt => t('Tempel teks struk', 'Paste receipt text');

  String get pasteReceiptHint => t(
    'Tempel teks struk di sini. OCR kamera tersedia di aplikasi Android.',
    'Paste receipt text here. Camera OCR is available in the Android app.',
  );

  String get analyzeText => t('Analisis teks', 'Analyze text');

  String get ocrUnsupported => t(
    'Kamera OCR tidak tersedia di perangkat ini. Gunakan tempel teks.',
    'Camera OCR is unavailable here. Use pasted text.',
  );

  String get receiptReview => t('Review barang bukti', 'Review evidence');

  String get attachToTransaction =>
      t('Jadikan transaksi', 'Turn into transaction');

  String get saveEvidence => t('Simpan barang bukti', 'Save evidence');

  String get savedEvidence => t('Barang bukti tersimpan.', 'Evidence saved.');

  String get rawText => t('Teks struk', 'Receipt text');

  String get items => t('Item', 'Items');

  String get noItems => t('Tidak ada item yang terbaca.', 'No items detected.');

  String get confidence => t('Keyakinan', 'Confidence');

  String get receiptAttached =>
      t('Sudah terhubung ke transaksi', 'Linked to a transaction');

  String get receiptDraft => t('Belum terhubung', 'Not linked yet');

  String get teamSubtitle => t(
    'Diskusikan temuan, pantau kehadiran, dan jaga agar setiap keputusan punya jejak.',
    'Discuss findings, watch presence, and keep a trail behind every decision.',
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
    'Berhasil bergabung. Menarik data dompet…',
    'Joined. Pulling wallet data…',
  );

  String get settingsSubtitle => t(
    'Atur identitas, tampilan, keamanan, dan data yang disimpan.',
    'Manage identity, appearance, security, and data.',
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
    'Minta sidik jari atau wajah saat membuka aplikasi.',
    'Ask for fingerprint or face when opening the app.',
  );

  String get biometricUnavailable => t(
    'Biometrik tidak tersedia di perangkat ini.',
    'Biometrics are unavailable on this device.',
  );

  String get biometricReason =>
      t('Buka berkas Dompetektif', 'Open the Dompetektif case file');

  String get privacy => t('Privasi angka', 'Amount privacy');

  String get hideAmounts => t('Sembunyikan nominal', 'Hide amounts');

  String get hideAmountsSubtitle => t(
    'Tampilkan •••••• di layar agar aman dilihat orang lain.',
    'Show •••••• on screen for privacy.',
  );

  String get data => t('Data & sinkronisasi', 'Data & sync');

  String get cloudStatus => t('Status cloud', 'Cloud status');

  String get syncNow => t('Sinkronkan sekarang', 'Sync now');

  String get lastSynced => t('Terakhir sinkron', 'Last synced');

  String get neverSynced => t('Belum pernah', 'Never');

  String get pendingChanges => t('Perubahan tertunda', 'Pending changes');

  String get noPendingChanges =>
      t('Semua perubahan sudah terkirim.', 'All changes are delivered.');

  String get offlineNotice => t(
    'Tidak ada koneksi. Perubahan disimpan di perangkat dan dikirim otomatis saat online.',
    'No connection. Changes are saved on device and sent automatically when online.',
  );

  String get exportData => t('Ekspor data', 'Export data');

  String get exportDataSubtitle => t(
    'Unduh berkas PDF atau CSV untuk arsip dan audit.',
    'Download PDF or CSV for archive and audit.',
  );

  String get account => t('Akun', 'Account');

  String get about => t('Tentang', 'About');

  String get version => t('Versi', 'Version');

  String get aboutBody => t(
    'Dompetektif adalah pelacak pengeluaran dengan sudut pandang investigasi. Data adalah milikmu; mode lokal tetap bisa dipakai tanpa cloud.',
    'Dompetektif is an expense tracker with an investigation lens. Your data is yours; local mode works without the cloud.',
  );

  String get demoData => t('Data demo', 'Demo data');

  String get resetDemo => t('Reset data demo', 'Reset demo data');

  String get resetDemoBody => t(
    'Semua berkas demo di perangkat ini akan dihapus dan dibuat ulang.',
    'All demo case files on this device will be erased and rebuilt.',
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

  String get categoryKeywords => t('Kata kunci OCR', 'OCR keywords');

  String get categoryKeywordsHint => t(
    'Pisahkan dengan koma, mis. kopi, cafe, resto',
    'Separate with commas, e.g. coffee, cafe, resto',
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

  String get runDue => t('Jalankan yang jatuh tempo', 'Run due');

  String get dueCompleted => t(
    'Transaksi berulang telah dijalankan.',
    'Recurring transactions have been run.',
  );

  String get noDue =>
      t('Tidak ada transaksi yang jatuh tempo.', 'Nothing is due yet.');

  String get monthCurrent => t('Bulan ini', 'This month');

  String get monthPrevious => t('Bulan lalu', 'Last month');

  String get generate => t('Susun laporan', 'Generate');

  String get generating => t('Menyusun…', 'Generating…');

  String get reportPeriod => t('Periode laporan', 'Report period');

  String get reportHeadline => t('Judul temuan', 'Headline');

  String get reportSummary => t('Ringkasan', 'Summary');

  String get source => t('Sumber', 'Source');

  String get generatedAt => t('Disusun pada', 'Generated at');

  String get createdAtLabel => t('Dibuat pada', 'Created at');

  String get updatedAtLabel => t('Diperbarui pada', 'Updated at');

  String get insightEmptyTitle =>
      t('Belum ada laporan untuk periode ini', 'No report for this period yet');

  String get insightEmptyBody => t(
    'Susun laporan untuk melihat pola pengeluaran, kebocoran kategori, dan rekomendasi yang bisa ditindaklanjuti.',
    'Generate a report to see spending patterns, category leaks, and actionable recommendations.',
  );

  String get saveTransactionSuccess =>
      t('Berkas transaksi tersimpan.', 'Transaction recorded.');

  String get saveTransaction => t('Simpan transaksi', 'Save transaction');

  String get deleteSuccess => t('Berkas dihapus.', 'Record deleted.');

  String get syncDone => t('Sinkronisasi selesai.', 'Sync complete.');

  String get syncFailed =>
      t('Sinkronisasi gagal. Coba lagi.', 'Sync failed. Try again.');

  String get locked => t('Berkas terkunci', 'Case file locked');

  String get unlock => t('Buka dengan biometrik', 'Unlock with biometrics');

  String get unlocked => t('Berkas terbuka.', 'Case file unlocked.');

  String get signOutConfirm =>
      t('Keluar dari berkas ini?', 'Leave this case file?');

  String get signOutBody => t(
    'Sesi ini akan diakhiri dan data kasus lokal dibersihkan. Data di cloud tetap aman.',
    'This session will end and the local case cache will be cleared. Cloud data stays safe.',
  );

  String get welcomeDetective =>
      t('Selamat datang, Detektif', 'Welcome, Detective');

  String get caseFile => t('BERKAS', 'CASE FILE');

  String get confidential => t('RAHASIA', 'CONFIDENTIAL');

  String get evidenceCount => t('barang bukti', 'evidence items');

  String get caseCount => t('berkas', 'cases');

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

  String get topMerchants => t('Merchant teratas', 'Top merchants');

  String get noMerchants => t('Belum ada merchant.', 'No merchants yet.');

  String get caseNoteHint =>
      t('Tulis temuan untuk tim…', 'Write a finding for the team…');

  String get teamOnlyShared => t(
    'Pilih dompet bersama untuk membuka ruang diskusi.',
    'Select a shared wallet to open the discussion room.',
  );

  String get createFirstWallet =>
      t('Buat dompet pertama', 'Create your first wallet');

  String get createFirstWalletBody => t(
    'Setelah dompet dibuat, transaksi dan Batas TKP bisa dicatat.',
    'Once a wallet exists, you can record transactions and limits.',
  );

  String get demoSeedReady =>
      t('Data demo siap diinvestigasi.', 'Demo case files are ready.');

  String get today => t('Hari ini', 'Today');

  String get yesterday => t('Kemarin', 'Yesterday');

  String get unknownDate => t('Tanggal tidak dikenal', 'Unknown date');

  String get unknownMerchant => t('Merchant tidak dikenal', 'Unknown merchant');

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

  String get attachReceipt => t('Lampirkan barang bukti', 'Attach evidence');

  String get removeReceipt => t('Lepas barang bukti', 'Remove evidence');

  String get transactionSaved =>
      t('Transaksi tersimpan.', 'Transaction saved.');

  String get saving => t('Menyimpan…', 'Saving…');

  String get analyzing => t('Menganalisis…', 'Analyzing…');

  String get scanHintAndroid => t(
    'Posisikan struk di area terang. OCR berjalan di perangkat, bukan di cloud.',
    'Place the receipt in good light. OCR runs on device, not in the cloud.',
  );

  String get cameraUnavailable => t(
    'Kamera hanya tersedia di aplikasi Android.',
    'Camera is only available in the Android app.',
  );

  String get scanFailed => t(
    'Struk belum bisa dibaca. Coba foto ulang atau tempel teks.',
    'Could not read the receipt. Retake the photo or paste the text.',
  );

  String get parseFailed => t(
    'Teks struk belum bisa dianalisis.',
    'Could not analyze the receipt text.',
  );

  String get noTextDetected =>
      t('Tidak ada teks yang terdeteksi.', 'No text detected.');

  String get receiptMerchantHint => t('Nama merchant', 'Merchant name');

  String get receiptTotalHint => t('Total struk', 'Receipt total');

  String get receiptDateHint => t('Tanggal struk', 'Receipt date');

  String get receiptCategoryHint =>
      t('Kategori yang disarankan', 'Suggested category');

  String get saveAsDraft => t('Simpan sebagai draft', 'Save as draft');

  String get createTransactionFromReceipt =>
      t('Buat transaksi dari bukti', 'Create transaction from evidence');

  String get transactionFromReceiptHint => t(
    'Nominal, merchant, tanggal, dan kategori sudah diisi dari struk. Periksa sebelum menyimpan.',
    'Amount, merchant, date, and category are prefilled from the receipt. Review before saving.',
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
    'Cek email untuk konfirmasi akun sebelum masuk.',
    'Check your email to confirm the account before signing in.',
  );

  String get errorNetwork => t(
    'Jaringan bermasalah. Periksa koneksi lalu coba lagi.',
    'Network problem. Check your connection and try again.',
  );

  String get errorAuthGeneric =>
      t('Autentikasi gagal. Coba lagi.', 'Authentication failed. Try again.');

  String get errorDemoDisabled => t(
    'Mode demo tidak tersedia saat Supabase aktif.',
    'Demo mode is unavailable while Supabase is configured.',
  );

  String get errorCloudNotConfigured => t(
    'Cloud belum dikonfigurasi. Gunakan mode demo atau isi kredensial Supabase.',
    'Cloud is not configured. Use demo mode or provide Supabase credentials.',
  );

  String get oauthRedirectHint => t(
    'Login Google membuka browser. Kembali ke aplikasi setelah selesai.',
    'Google login opens the browser. Return to the app when finished.',
  );

  String get sessionExpired => t(
    'Sesi berakhir. Masuk kembali untuk melanjutkan.',
    'Session expired. Sign in to continue.',
  );

  String get passwordReset => t('Lupa kata sandi?', 'Forgot password?');

  String get passwordResetHint => t(
    'Fitur reset kata sandi tersedia di Supabase. Hubungi admin proyek jika perlu bantuan.',
    'Password reset is handled by Supabase. Contact the project admin for help.',
  );

  String get reportWalletScope => t('Cakupan dompet', 'Wallet scope');

  String get allWalletsScope => t('Semua dompet', 'All wallets');

  String get exportIncludes => t('Berkas akan memuat', 'The file will include');

  String get transactions => t('transaksi', 'transactions');

  String get chooseFormat => t('Pilih format', 'Choose format');

  String get pdfFormat => t('PDF — siap cetak', 'PDF — print ready');

  String get csvFormat => t('CSV — siap olah', 'CSV — spreadsheet ready');

  String get reportExportHint => t(
    'Ekspor mengambil data periode laporan yang sedang dibuka.',
    'Export uses the period of the report currently open.',
  );

  String get evidenceVault => t('Lemari barang bukti', 'Evidence vault');

  String get vaultSubtitle => t(
    'Semua struk, teks OCR, dan tautan transaksi tersimpan rapi.',
    'Every receipt, OCR text, and transaction link in one place.',
  );

  String get scanNow => t('Pindai sekarang', 'Scan now');

  String get draft => t('Draft', 'Draft');

  String get parsed => t('Terbaca', 'Parsed');

  String get attached => t('Terhubung', 'Attached');

  String get failed => t('Gagal', 'Failed');

  String get itemQuantity => t('Qty', 'Qty');

  String get total => t('Total', 'Total');

  String get merchantFromReceipt =>
      t('Merchant dari struk', 'Merchant from receipt');

  String get dateFromReceipt => t('Tanggal dari struk', 'Date from receipt');

  String get totalFromReceipt => t('Total dari struk', 'Total from receipt');

  String get tapToView => t('Ketuk untuk membuka', 'Tap to open');

  String get imageAvailable =>
      t('Gambar struk tersedia', 'Receipt image available');

  String get noImage => t('Tanpa gambar', 'No image');

  String get evidenceDraftSaved =>
      t('Draft barang bukti tersimpan.', 'Evidence draft saved.');

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

  String get allCaughtUp =>
      t('Semua berkas sudah diperiksa.', 'Every file has been reviewed.');

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
    'Belum ada batas untuk kategori ini bulan ini.',
    'No limit for this category this month.',
  );

  String get categoriesSubtitle => t(
    'Kategori bawaan bisa dipakai langsung. Tambahkan kategori kustom untuk kebiasaan unikmu.',
    'Built-in categories are ready to use. Add custom ones for your own habits.',
  );

  String get walletsSubtitle => t(
    'Pisahkan uang tunai, bank, dan e-wallet agar saldo tidak tertukar.',
    'Separate cash, bank, and e-wallet balances so they never blur together.',
  );

  String get recurringSubtitle => t(
    'Catat gaji, langganan, dan sewa sekali. Detektif akan membuat transaksinya saat jatuh tempo.',
    'Set salary, subscriptions, and rent once. The detective records them when due.',
  );

  String get openSettings => t('Buka pengaturan', 'Open settings');

  String get lastActivity => t('Aktivitas terakhir', 'Last activity');

  String get noActivity => t('Belum ada aktivitas.', 'No activity yet.');

  String get errorLoadData => t(
    'Data belum bisa dimuat. Coba lagi.',
    'Could not load data. Try again.',
  );

  String get errorSaveData => t(
    'Data belum bisa disimpan. Coba lagi.',
    'Could not save data. Try again.',
  );

  String get errorDeleteData => t(
    'Data belum bisa dihapus. Coba lagi.',
    'Could not delete data. Try again.',
  );

  String get errorGenerateReport => t(
    'Laporan belum bisa disusun. Periksa koneksi lalu coba lagi.',
    'Could not build the report. Check your connection and try again.',
  );

  String get errorExport =>
      t('Ekspor gagal. Coba lagi.', 'Export failed. Try again.');

  String get errorInvite =>
      t('Kode undangan belum bisa dibuat.', 'Could not create an invite code.');

  String get errorJoin => t(
    'Belum bisa bergabung. Periksa kode dan koneksi.',
    'Could not join. Check the code and connection.',
  );

  String get errorSendNote =>
      t('Catatan belum terkirim. Coba lagi.', 'Note was not sent. Try again.');

  String get errorOcr => t(
    'Struk belum bisa diproses. Coba lagi.',
    'Could not process the receipt. Try again.',
  );

  String get errorBiometric => t(
    'Biometrik tidak cocok. Coba lagi.',
    'Biometric did not match. Try again.',
  );

  String get lockTitle => t('Berkas ini terkunci', 'This case file is locked');

  String get lockSubtitle => t(
    'Gunakan biometrik untuk membuka kembali Dompetektif.',
    'Use biometrics to reopen Dompetektif.',
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

  String get viewEvidence => t('Lihat bukti', 'View evidence');

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
    'Kunci biometrik memakai sensor perangkat. Dompetektif tidak pernah menyimpan sidik jari atau wajahmu.',
    'Biometric lock uses your device sensor. Dompetektif never stores your fingerprint or face.',
  );

  String get scanTip => t(
    'Tips: foto struk di permukaan datar dengan pencahayaan cukup. OCR berjalan lokal di Android.',
    'Tip: photograph receipts on a flat surface with good light. OCR runs locally on Android.',
  );

  String get evidenceSavedToVault => t(
    'Barang bukti tersimpan di lemari bukti.',
    'Evidence saved to the vault.',
  );

  String get upToDate =>
      t('Semua data sudah mutakhir.', 'Everything is up to date.');

  String get settingsSaved => t('Pengaturan tersimpan.', 'Settings saved.');

  String get errorSettings =>
      t('Pengaturan belum bisa disimpan.', 'Could not save settings.');

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
      t('Teks struk dianalisis.', 'Receipt text analyzed.');

  String get categorySuggestion => t('Saran kategori', 'Category suggestion');

  String get useSuggestion => t('Gunakan saran', 'Use suggestion');

  String get manualEntry => t('Isi manual', 'Manual entry');

  String get receiptReviewHint => t(
    'Periksa hasil baca sebelum menyimpan. OCR bisa salah membaca angka.',
    'Review the reading before saving. OCR can misread numbers.',
  );

  String get evidencePreview => t('Pratinjau bukti', 'Evidence preview');

  String get noPreview => t('Pratinjau tidak tersedia', 'No preview available');

  String get linkToTransaction => t('Tautkan transaksi', 'Link transaction');

  String get transactionLinked =>
      t('Transaksi berhasil ditautkan.', 'Transaction linked.');

  String get openEvidence => t('Buka barang bukti', 'Open evidence');

  String get reportReady =>
      t('Laporan penyelidikan siap.', 'Investigation report ready.');

  String get reportLocalNotice => t(
    'Cloud AI tidak aktif. Laporan disusun dengan analisis lokal deterministik agar tetap bisa dipakai offline.',
    'Cloud AI is inactive. The report uses deterministic local analysis so it still works offline.',
  );

  String get anomalyDeviation => t('x di atas rata-rata', 'x above average');

  String get budgetProgress => t('Progres batas', 'Limit progress');

  String get noBudgetAlerts =>
      t('Semua Batas TKP aman.', 'All limits are safe.');

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

  String get invitationCodeCopied => t(
    'Kode undangan disalin ke clipboard.',
    'Invite code copied to clipboard.',
  );

  String get noSharedWalletSelected => t(
    'Pilih dompet bersama untuk melihat tim.',
    'Select a shared wallet to see the team.',
  );

  String get sharedWalletHint => t(
    'Dompet bersama memungkinkan beberapa investigator mencatat transaksi dan berdiskusi.',
    'Shared wallets let several investigators record transactions and discuss.',
  );

  String get inviteCodeExpires => t(
    'Bagikan kode ini ke anggota tim. Kode berlaku selama 7 hari.',
    'Share this code with your team. It stays valid for 7 days.',
  );

  String get roleOwner => t('Pemilik', 'Owner');

  String get roleEditor => t('Editor', 'Editor');

  String get roleViewer => t('Pengamat', 'Viewer');

  String get noPermission => t(
    'Peranmu tidak mengizinkan aksi ini.',
    'Your role does not allow this action.',
  );

  String get settingsDataHeader => t('Berkas pendukung', 'Supporting files');

  String get settingsDataHeaderBody => t(
    'Dompet, kategori, dan transaksi berulang adalah fondasi investigasi.',
    'Wallets, categories, and recurring rules are the foundation of the investigation.',
  );

  String get appTaglineShort => t('Usut tuntas.', 'Follow it through.');

  String get legal => t(
    'Dompetektif bukan penasihat keuangan. Semua keputusan tetap milikmu.',
    'Dompetektif is not a financial advisor. Every decision remains yours.',
  );

  String get caseClosed => t('Berkas ditutup.', 'Case closed.');

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

  String get notFound => t('Berkas tidak ditemukan.', 'File not found.');

  String get backToDashboard => t('Kembali ke meja kasus', 'Back to case desk');

  String get reportNotFound =>
      t('Laporan tidak ditemukan.', 'Report not found.');

  String get receiptNotFound =>
      t('Barang bukti tidak ditemukan.', 'Evidence not found.');

  String get onlineMembers => t('Anggota online', 'Online members');

  String get noOnlineMembers =>
      t('Belum ada anggota online.', 'No one is online yet.');

  String get teamChatHint => t(
    'Percakapan ini tersinkron realtime saat Supabase aktif. Di mode demo, catatan disimpan lokal.',
    'This conversation syncs in realtime with Supabase. In demo mode, notes stay local.',
  );

  String get realtime => t('Realtime', 'Realtime');

  String get offlineFirst => t('Offline-first', 'Offline-first');

  String get localAiFallback => t('Analisis lokal', 'Local analysis');

  String get system => t('Sistem', 'System');

  String get settingsProfile => t('Profil', 'Profile');

  String get settingsProfileSubtitle =>
      t('Identitas dan sesi saat ini', 'Current identity and session');

  String get settingsAppearanceSubtitle => t(
    'Tema, bahasa, dan privasi angka',
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
