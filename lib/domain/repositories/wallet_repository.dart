import 'package:dompetektif/domain/entities/case_note.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/wallet.dart';

abstract interface class WalletRepository {
  Stream<List<Wallet>> watchWallets();

  Future<List<Wallet>> getWallets();

  Future<Wallet?> getWallet(String id);

  Future<void> saveWallet(Wallet wallet);

  Future<void> deleteWallet(String id);
}

abstract interface class CategoryRepository {
  Stream<List<Category>> watchCategories({CategoryKind? kind});

  Future<List<Category>> getCategories({CategoryKind? kind});

  Future<Category?> getCategory(String id);

  Future<void> saveCategory(Category category);

  Future<void> deleteCategory(String id);
}

abstract interface class TeamRepository {
  Stream<List<WalletMember>> watchMembers(String walletId);

  Stream<List<CaseNote>> watchNotes(String walletId);

  Stream<List<CaseNote>> watchAllNotes();

  Stream<List<OnlineMember>> watchPresence(String walletId);

  Future<void> sendNote(CaseNote note);

  Future<String> createInvite(String walletId);

  Future<void> joinWallet(String code);
}
