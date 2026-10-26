import 'package:dompetektif/domain/entities/case_note.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:dompetektif/domain/repositories/wallet_repository.dart';

class WatchWallets {
  const WatchWallets(this._repository);

  final WalletRepository _repository;

  Stream<List<Wallet>> call() => _repository.watchWallets();
}

class GetWallets {
  const GetWallets(this._repository);

  final WalletRepository _repository;

  Future<List<Wallet>> call() => _repository.getWallets();
}

class GetWallet {
  const GetWallet(this._repository);

  final WalletRepository _repository;

  Future<Wallet?> call(String id) => _repository.getWallet(id);
}

class SaveWallet {
  const SaveWallet(this._repository);

  final WalletRepository _repository;

  Future<void> call(Wallet wallet) => _repository.saveWallet(wallet);
}

class DeleteWallet {
  const DeleteWallet(this._repository);

  final WalletRepository _repository;

  Future<void> call(String id) => _repository.deleteWallet(id);
}

class WatchCategories {
  const WatchCategories(this._repository);

  final CategoryRepository _repository;

  Stream<List<Category>> call({CategoryKind? kind}) =>
      _repository.watchCategories(kind: kind);
}

class GetCategories {
  const GetCategories(this._repository);

  final CategoryRepository _repository;

  Future<List<Category>> call({CategoryKind? kind}) =>
      _repository.getCategories(kind: kind);
}

class SaveCategory {
  const SaveCategory(this._repository);

  final CategoryRepository _repository;

  Future<void> call(Category category) => _repository.saveCategory(category);
}

class DeleteCategory {
  const DeleteCategory(this._repository);

  final CategoryRepository _repository;

  Future<void> call(String id) => _repository.deleteCategory(id);
}

class WatchTeam {
  const WatchTeam(this._repository);

  final TeamRepository _repository;

  Stream<List<WalletMember>> members(String walletId) =>
      _repository.watchMembers(walletId);

  Stream<List<CaseNote>> notes(String walletId) =>
      _repository.watchNotes(walletId);

  Stream<List<OnlineMember>> presence(String walletId) =>
      _repository.watchPresence(walletId);
}

class SendCaseNote {
  const SendCaseNote(this._repository);

  final TeamRepository _repository;

  Future<void> call(CaseNote note) => _repository.sendNote(note);
}

class CreateWalletInvite {
  const CreateWalletInvite(this._repository);

  final TeamRepository _repository;

  Future<String> call(String walletId) => _repository.createInvite(walletId);
}

class JoinSharedWallet {
  const JoinSharedWallet(this._repository);

  final TeamRepository _repository;

  Future<void> call(String code) => _repository.joinWallet(code);
}
