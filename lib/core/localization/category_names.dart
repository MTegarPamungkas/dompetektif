import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/services/receipt_parser.dart';

String localizedCategoryName(AppLocalizations l10n, Category category) {
  if (!category.isSystem) return category.name;
  final id = category.id;
  if (id == DefaultCategories.foodId) {
    return l10n.t('Makanan & Minuman', 'Food & Drinks');
  }
  if (id == DefaultCategories.transportId) {
    return l10n.t('Transportasi', 'Transport');
  }
  if (id == DefaultCategories.shoppingId) {
    return l10n.t('Belanja', 'Shopping');
  }
  if (id == DefaultCategories.billsId) {
    return l10n.t('Tagihan', 'Bills');
  }
  if (id == DefaultCategories.healthId) {
    return l10n.t('Kesehatan', 'Health');
  }
  if (id == DefaultCategories.entertainmentId) {
    return l10n.t('Hiburan', 'Entertainment');
  }
  if (id == DefaultCategories.salaryId) {
    return l10n.t('Gaji', 'Salary');
  }
  if (id == DefaultCategories.freelanceId) {
    return l10n.t('Freelance', 'Freelance');
  }
  if (id == DefaultCategories.otherIncomeId) {
    return l10n.t('Pemasukan Lain', 'Other Income');
  }
  if (id == DefaultCategories.otherExpenseId) {
    return l10n.t('Lainnya', 'Other');
  }
  return category.name;
}

String localizedCategoryId(AppLocalizations l10n, String? id) {
  final name = switch (id) {
    DefaultCategories.foodId => l10n.t('Makanan & Minuman', 'Food & Drinks'),
    DefaultCategories.transportId => l10n.t('Transportasi', 'Transport'),
    DefaultCategories.shoppingId => l10n.t('Belanja', 'Shopping'),
    DefaultCategories.billsId => l10n.t('Tagihan', 'Bills'),
    DefaultCategories.healthId => l10n.t('Kesehatan', 'Health'),
    DefaultCategories.entertainmentId => l10n.t('Hiburan', 'Entertainment'),
    DefaultCategories.salaryId => l10n.t('Gaji', 'Salary'),
    DefaultCategories.freelanceId => l10n.t('Freelance', 'Freelance'),
    DefaultCategories.otherIncomeId => l10n.t('Pemasukan Lain', 'Other Income'),
    DefaultCategories.otherExpenseId => l10n.t('Lainnya', 'Other'),
    _ => null,
  };
  return name ?? '';
}
