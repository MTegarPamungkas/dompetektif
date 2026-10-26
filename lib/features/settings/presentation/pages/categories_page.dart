import 'package:dompetektif/core/di/injection_container.dart';
import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/localization/category_names.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/usecases/auth_usecases.dart';
import 'package:dompetektif/features/settings/presentation/bloc/settings_data_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

const _categoryPalette = [
  '#E8B84B',
  '#6FB7A8',
  '#E0705C',
  '#7C9CF5',
  '#C98BDB',
  '#8FBF6F',
  '#E2A03F',
  '#5BA7C9',
  '#D36AA5',
  '#9E9E8F',
];

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<SettingsDataBloc, SettingsDataState>(
      listenWhen: (previous, current) => previous.failure != current.failure,
      listener: (context, state) {
        final failure = state.failure;
        if (failure == null) return;
        showAppSnackBar(context, switch (failure) {
          SettingsDataFailure.load => l10n.errorLoadData,
          SettingsDataFailure.save => l10n.errorSaveData,
          SettingsDataFailure.delete => l10n.errorDeleteData,
          SettingsDataFailure.runDue => l10n.errorSaveData,
        }, error: true);
        context.read<SettingsDataBloc>().clearFailure();
      },
      child: BlocBuilder<SettingsDataBloc, SettingsDataState>(
        builder: (context, state) {
          final expense = state.categories
              .where((category) => category.kind == CategoryKind.expense)
              .toList();
          final income = state.categories
              .where((category) => category.kind == CategoryKind.income)
              .toList();
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              title: Text(l10n.categories),
              actions: [
                IconButton(
                  tooltip: l10n.categoryCreate,
                  onPressed: () => _openEditor(context, null),
                  icon: const Icon(Icons.add_rounded),
                ),
                const SizedBox(width: 6),
              ],
            ),
            body: PageScroll(
              children: [
                DossierHeader(
                  eyebrow:
                      '${l10n.caseFile} / ${state.categories.length} ${l10n.categories.toLowerCase()}',
                  title: l10n.categories,
                  subtitle: l10n.categoriesSubtitle,
                  trailing: FilledButton.icon(
                    onPressed: () => _openEditor(context, null),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(l10n.categoryCreate),
                  ),
                ),
                const SizedBox(height: 22),
                if (state.loading)
                  const LoadingState()
                else ...[
                  _CategorySection(
                    title: l10n.expense,
                    eyebrow: l10n.caseFile,
                    categories: expense,
                    onEdit: (category) => _openEditor(context, category),
                    onDelete: (category) => _delete(context, category),
                  ),
                  const SizedBox(height: 18),
                  _CategorySection(
                    title: l10n.income,
                    eyebrow: l10n.caseFile,
                    categories: income,
                    onEdit: (category) => _openEditor(context, category),
                    onDelete: (category) => _delete(context, category),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, Category? category) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (_) => BlocProvider.value(
        value: context.read<SettingsDataBloc>(),
        child: _CategoryEditorSheet(category: category),
      ),
    );
  }

  Future<void> _delete(BuildContext context, Category category) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteCategoryTitle,
      body: l10n.deleteCategoryBody,
      confirmLabel: l10n.confirmDelete,
    );
    if (!confirmed || !context.mounted) return;
    final success = await context.read<SettingsDataBloc>().deleteCategory(
      category.id,
    );
    if (!context.mounted) return;
    if (success) showAppSnackBar(context, l10n.deleteSuccess);
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.eyebrow,
    required this.categories,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String eyebrow;
  final List<Category> categories;
  final ValueChanged<Category> onEdit;
  final ValueChanged<Category> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            eyebrow: eyebrow,
            title: title,
            padding: EdgeInsets.zero,
            action: StatusPill(
              label: '${categories.length}',
              tone: PillTone.neutral,
              compact: true,
            ),
          ),
          const SizedBox(height: 10),
          if (categories.isEmpty)
            Text(l10n.noData, style: context.texts.bodySmall)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 780
                    ? 3
                    : (constraints.maxWidth >= 480 ? 2 : 1);
                return Column(
                  children: [
                    for (
                      var index = 0;
                      index < categories.length;
                      index += columns
                    )
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            for (var column = 0; column < columns; column++)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: column < columns - 1 ? 8 : 0,
                                  ),
                                  child: index + column < categories.length
                                      ? _CategoryTile(
                                          category: categories[index + column],
                                          onEdit: () => onEdit(
                                            categories[index + column],
                                          ),
                                          onDelete: () => onDelete(
                                            categories[index + column],
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 4, 9),
      decoration: BoxDecoration(
        color: context.dompet.surfaceMuted.withValues(alpha: 0.65),
        borderRadius: AppRadius.allMd,
        border: Border.all(color: context.dompet.line),
      ),
      child: Row(
        children: [
          CategoryAvatar(category: category, size: 34),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizedCategoryName(l10n, category),
                  style: context.texts.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  category.isSystem ? l10n.systemCategory : l10n.customCategory,
                  style: context.texts.labelSmall?.copyWith(fontSize: 7.5),
                ),
              ],
            ),
          ),
          if (category.isSystem)
            Padding(
              padding: const EdgeInsets.only(right: 9),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 13,
                color: context.dompet.inkMuted,
              ),
            )
          else
            PopupMenuButton<String>(
              tooltip: l10n.edit,
              icon: Icon(
                Icons.more_vert_rounded,
                size: 17,
                color: context.dompet.inkMuted,
              ),
              onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(Icons.edit_outlined, size: 17),
                      const SizedBox(width: 9),
                      Text(l10n.edit),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 17,
                        color: context.dompet.evidence,
                      ),
                      const SizedBox(width: 9),
                      Text(
                        l10n.delete,
                        style: TextStyle(color: context.dompet.evidence),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CategoryEditorSheet extends StatefulWidget {
  const _CategoryEditorSheet({this.category});

  final Category? category;

  @override
  State<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<_CategoryEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _keywordsController;
  CategoryKind _kind = CategoryKind.expense;
  String _color = _categoryPalette.first;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _nameController = TextEditingController(text: category?.name ?? '');
    _keywordsController = TextEditingController(
      text: category?.keywords.join(', ') ?? '',
    );
    _kind = category?.kind ?? CategoryKind.expense;
    _color = category?.colorHex ?? _categoryPalette.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<SettingsDataBloc>().state;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.category == null
                      ? l10n.categoryCreate
                      : l10n.categoryEdit,
                  style: context.texts.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(l10n.categoriesSubtitle, style: context.texts.bodySmall),
                const SizedBox(height: 18),
                AppTextField(
                  controller: _nameController,
                  label: l10n.categoryName,
                  hint: l10n.t(
                    'Contoh: Kopi & camilan',
                    'e.g. Coffee & snacks',
                  ),
                  prefixIcon: const Icon(Icons.category_outlined, size: 19),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? l10n.nameRequired : null,
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.categoryKind.toUpperCase(),
                  style: context.texts.labelSmall?.copyWith(
                    letterSpacing: 1.3,
                    fontSize: 8.5,
                  ),
                ),
                const SizedBox(height: 8),
                AppSegmented<CategoryKind>(
                  values: CategoryKind.values,
                  selected: _kind,
                  expanded: true,
                  labelBuilder: (kind) =>
                      kind == CategoryKind.expense ? l10n.expense : l10n.income,
                  onChanged: (kind) => setState(() => _kind = kind),
                ),
                const SizedBox(height: 15),
                Text(
                  l10n.chooseColor.toUpperCase(),
                  style: context.texts.labelSmall?.copyWith(
                    letterSpacing: 1.3,
                    fontSize: 8.5,
                  ),
                ),
                const SizedBox(height: 8),
                AppColorPicker(
                  colors: _categoryPalette,
                  selected: _color,
                  onChanged: (color) => setState(() => _color = color),
                ),
                const SizedBox(height: 15),
                AppTextField(
                  controller: _keywordsController,
                  label: l10n.categoryKeywords,
                  hint: l10n.t(
                    'kopi, kafe, starbucks',
                    'coffee, cafe, starbucks',
                  ),
                  prefixIcon: const Icon(Icons.tag_rounded, size: 19),
                  helper: l10n.t(
                    'Pisahkan dengan koma. Dipakai untuk menebak kategori dari struk.',
                    'Separate with commas. Used to guess the category from a receipt.',
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: state.saving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: state.saving ? null : _save,
                        child: state.saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.save),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    final current = widget.category;
    final now = DateTime.now();
    final keywords = _keywordsController.text
        .split(',')
        .map((keyword) => keyword.trim().toLowerCase())
        .where((keyword) => keyword.isNotEmpty)
        .toSet()
        .toList();
    final category = Category(
      id: current?.id ?? getIt<Uuid>().v4(),
      ownerId: current?.ownerId ?? getIt<GetCurrentUser>()()?.id,
      name: _nameController.text.trim(),
      kind: _kind,
      colorHex: _color,
      iconKey: current?.iconKey ?? 'category',
      keywords: keywords,
      isSystem: false,
      createdAt: current?.createdAt ?? now,
      updatedAt: now,
    );
    final success = await context.read<SettingsDataBloc>().saveCategory(
      category,
    );
    if (!mounted || !success) return;
    showAppSnackBar(context, l10n.categoryCreated);
    Navigator.of(context).pop();
  }
}
