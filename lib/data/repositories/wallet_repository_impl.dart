import 'package:dompetektif/data/mappers/entity_mappers.dart';
import 'package:dompetektif/data/repositories/local_repository_base.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:dompetektif/domain/repositories/wallet_repository.dart';

class WalletRepositoryImpl extends LocalRepositoryBase
    implements WalletRepository {
  WalletRepositoryImpl(super.store, super.sync, super.auth);

  @override
  Stream<List<Wallet>> watchWallets() {
    return store.watch('wallets').map(_mapWallets);
  }

  @override
  Future<List<Wallet>> getWallets() async => _mapWallets(store.all('wallets'));

  @override
  Future<Wallet?> getWallet(String id) async {
    final row = store.get('wallets', id);
    if (row == null) return null;
    final wallet = walletFromRow(row);
    return wallet.isDeleted ? null : wallet;
  }

  @override
  Future<void> saveWallet(Wallet wallet) async {
    final now = DateTime.now();
    final updated = wallet.copyWith(
      ownerId: wallet.ownerId.isEmpty ? userId : wallet.ownerId,
      updatedAt: now,
    );
    await upsertRow('wallets', walletToRow(updated), updatedAt: now);
  }

  @override
  Future<void> deleteWallet(String id) => softDeleteRow('wallets', id);

  List<Wallet> _mapWallets(List<Map<String, dynamic>> rows) {
    final wallets =
        rows.map(walletFromRow).where((wallet) => !wallet.isDeleted).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return wallets;
  }
}

class CategoryRepositoryImpl extends LocalRepositoryBase
    implements CategoryRepository {
  CategoryRepositoryImpl(super.store, super.sync, super.auth);

  @override
  Stream<List<Category>> watchCategories({CategoryKind? kind}) {
    return store.watch('categories').map((rows) => _map(rows, kind));
  }

  @override
  Future<List<Category>> getCategories({CategoryKind? kind}) async =>
      _map(store.all('categories'), kind);

  @override
  Future<Category?> getCategory(String id) async {
    final row = store.get('categories', id);
    if (row == null) return null;
    final category = categoryFromRow(row);
    return category.isDeleted ? null : category;
  }

  @override
  Future<void> saveCategory(Category category) async {
    final existing = store.get('categories', category.id);
    if (existing != null) {
      final current = categoryFromRow(existing);
      if (current.isSystem) {
        throw StateError('Kategori bawaan tidak dapat diubah.');
      }
    }

    final now = DateTime.now();
    final updated = category.copyWith(
      ownerId: category.isSystem ? category.ownerId : userId,
      updatedAt: now,
      createdAt: category.createdAt,
    );
    await upsertRow('categories', categoryToRow(updated), updatedAt: now);
  }

  @override
  Future<void> deleteCategory(String id) async {
    final row = store.get('categories', id);
    if (row == null) return;
    final category = categoryFromRow(row);
    if (category.isSystem) {
      throw StateError('Kategori bawaan tidak dapat dihapus.');
    }
    await softDeleteRow('categories', id);
  }

  List<Category> _map(List<Map<String, dynamic>> rows, CategoryKind? kind) {
    final categories =
        rows
            .map(categoryFromRow)
            .where(
              (category) =>
                  !category.isDeleted &&
                  (kind == null || category.kind == kind),
            )
            .toList()
          ..sort((a, b) {
            if (a.kind != b.kind) return a.kind.index.compareTo(b.kind.index);
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
    return categories;
  }
}
