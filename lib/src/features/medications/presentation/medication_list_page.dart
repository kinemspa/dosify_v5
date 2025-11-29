import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/utils/format.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/glass_card_surface.dart';
import 'package:dosifi_v5/src/widgets/large_card.dart';
import 'package:dosifi_v5/src/widgets/stock_donut_gauge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _MedView { list, compact, large }

enum _SortBy { name, stock, strength, expiry }

enum _FilterBy { all, lowStock, expiringSoon, refrigerated }

class MedicationListPage extends ConsumerStatefulWidget {
  const MedicationListPage({super.key});

  @override
  ConsumerState<MedicationListPage> createState() => _MedicationListPageState();
}

class _MedicationListPageState extends ConsumerState<MedicationListPage> {
  _MedView _view = _MedView.large; // Default to large cards
  _SortBy _sortBy = _SortBy.name;
  bool _sortAsc = true;
  _FilterBy _filterBy = _FilterBy.all;
  String _query = '';
  bool _searchExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadSavedView();
  }

  Future<void> _loadSavedView() async {
    final prefs = await SharedPreferences.getInstance();
    final savedView = prefs.getString('medication_list_view') ?? 'large';
    setState(() {
      _view = _MedView.values.firstWhere(
        (v) => v.name == savedView,
        orElse: () => _MedView.large,
      );
    });
  }

  Future<void> _saveView(_MedView view) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('medication_list_view', view.name);
    setState(() => _view = view);
  }

  // Ensure we have an original stock value for count-based units so that we can
  // display Remaining / Original correctly. This sets it lazily to the first
  // observed value and updates it when the current stock increases (restock).
  void _ensureInitialStockValues(List<Medication> items) {
    final box = Hive.box<Medication>('medications');
    for (final m in items) {
      final isCountUnit =
          m.stockUnit == StockUnit.preFilledSyringes ||
          m.stockUnit == StockUnit.singleDoseVials ||
          m.stockUnit == StockUnit.multiDoseVials ||
          m.stockUnit == StockUnit.tablets ||
          m.stockUnit == StockUnit.capsules;
      if (!isCountUnit) continue;
      final cur = m.stockValue;
      final init = m.initialStockValue;
      var nextInit = init;
      if (init == null || init <= 0) {
        nextInit = cur;
      } else if (cur > init) {
        nextInit = cur; // treat as restock
      }
      if (nextInit != init) {
        final updated = m.copyWith(initialStockValue: nextInit);
        box.put(updated.id, updated);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Medication>('medications');

    return Scaffold(
      appBar: const GradientAppBar(title: 'Medications', forceBackButton: true),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Medication> b, _) {
          final items = _getFilteredAndSortedMedications(
            b.values.toList(growable: false),
          );
          // Ensure initial stock values so large cards can show current vs
          // initial amounts.
          _ensureInitialStockValues(items);

          // Show initial state if no medications exist, or the filtered
          // empty state when search removes everything.
          if (items.isEmpty) {
            if (_query.isEmpty && b.values.isEmpty) {
              // No medications at all - show initial state
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.medication, size: 48),
                    const SizedBox(height: 12),
                    const Text('Add a medication to begin tracking'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.push('/medications/select-type'),
                      child: const Text('Add Medication'),
                    ),
                  ],
                ),
              );
            } else {
              // Search has no results - show search state
              return Column(
                children: [
                  _buildToolbar(context),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off, size: 48),
                          const SizedBox(height: 12),
                          Text('No medications found for "$_query"'),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => setState(() {
                              _query = '';
                              _searchExpanded = false;
                            }),
                            child: const Text('Clear search'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
          }
          return Stack(
            children: [
              _buildMedList(context, items),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildToolbar(context),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/medications/select-type'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
      child: Row(
        children: [
          // Search section - expands to layout button when activated
          if (_searchExpanded)
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.search,
                      size: 20,
                      color: kTextLighterGrey(context),
                    ),
                    hintText: 'Search medications',
                    isDense: true,
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerLowest,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    suffixIcon: IconButton(
                      iconSize: 20,
                      icon: Icon(Icons.close, color: kTextLighterGrey(context)),
                      onPressed: () => setState(() {
                        _searchExpanded = false;
                        _query = '';
                      }),
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.search, color: kTextLighterGrey(context)),
              onPressed: () => setState(() => _searchExpanded = true),
              tooltip: 'Search medications',
            ),
          // When search is expanded, only show layout button
          if (_searchExpanded) const SizedBox(width: 8),
          if (_searchExpanded)
            IconButton(
              icon: Icon(_getViewIcon(_view), color: kTextLighterGrey(context)),
              tooltip: 'Change layout',
              onPressed: _cycleView,
            ),
          if (!_searchExpanded) const Spacer(),

          // Layout toggle as popup menu
          if (!_searchExpanded)
            IconButton(
              icon: Icon(_getViewIcon(_view), color: kTextLighterGrey(context)),
              tooltip: 'Change layout',
              onPressed: _cycleView,
            ),

          if (!_searchExpanded) const SizedBox(width: 8),

          // Filter button
          if (!_searchExpanded)
            PopupMenuButton<_FilterBy>(
              icon: Icon(
                Icons.filter_list,
                color: _filterBy != _FilterBy.all
                    ? Theme.of(context).colorScheme.primary
                    : kTextLighterGrey(context),
              ),
              tooltip: 'Filter medications',
              onSelected: (filter) => setState(() => _filterBy = filter),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _FilterBy.all,
                  child: Text('All medications'),
                ),
                const PopupMenuItem(
                  value: _FilterBy.lowStock,
                  child: Text('Low stock'),
                ),
                const PopupMenuItem(
                  value: _FilterBy.expiringSoon,
                  child: Text('Expiring soon'),
                ),
                const PopupMenuItem(
                  value: _FilterBy.refrigerated,
                  child: Text('Refrigerated'),
                ),
              ],
            ),

          // Sort button
          if (!_searchExpanded)
            PopupMenuButton<Object>(
              icon: Icon(Icons.sort, color: kTextLighterGrey(context)),
              tooltip: 'Sort medications',
              onSelected: (value) => setState(() {
                if (value is _SortBy) {
                  _sortBy = value;
                } else if (value == 'toggle_dir') {
                  _sortAsc = !_sortAsc;
                }
              }),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _SortBy.name,
                  child: Text('Sort by name'),
                ),
                const PopupMenuItem(
                  value: _SortBy.stock,
                  child: Text('Sort by stock'),
                ),
                const PopupMenuItem(
                  value: _SortBy.strength,
                  child: Text('Sort by strength'),
                ),
                const PopupMenuItem(
                  value: _SortBy.expiry,
                  child: Text('Sort by expiry'),
                ),
                PopupMenuItem(
                  value: 'toggle_dir',
                  child: Row(
                    children: [
                      Icon(
                        _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(_sortAsc ? 'Ascending' : 'Descending'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  List<Medication> _getFilteredAndSortedMedications(
    List<Medication> medications,
  ) {
    var items = List<Medication>.from(medications);

    // Apply search filter
    if (_query.isNotEmpty) {
      items = items
          .where((m) => m.name.toLowerCase().contains(_query.toLowerCase()))
          .toList();
    }

    // Apply category filter
    switch (_filterBy) {
      case _FilterBy.all:
        break;
      case _FilterBy.lowStock:
        items = items
            .where(
              (m) =>
                  m.lowStockEnabled &&
                  m.stockValue <= (m.lowStockThreshold ?? 0),
            )
            .toList();
      case _FilterBy.expiringSoon:
        final now = DateTime.now();
        final soon = now.add(const Duration(days: 30));
        items = items
            .where((m) => m.expiry != null && m.expiry!.isBefore(soon))
            .toList();
      case _FilterBy.refrigerated:
        items = items.where((m) => m.requiresRefrigeration == true).toList();
    }

    // Apply sorting
    int dir(int v) => _sortAsc ? v : -v;
    switch (_sortBy) {
      case _SortBy.name:
        items.sort((a, b) => dir(a.name.compareTo(b.name)));
      case _SortBy.stock:
        items.sort((a, b) => dir(a.stockValue.compareTo(b.stockValue)));
      case _SortBy.strength:
        items.sort((a, b) => dir(a.strengthValue.compareTo(b.strengthValue)));
      case _SortBy.expiry:
        items.sort((a, b) {
          if (a.expiry == null && b.expiry == null) return 0;
          if (a.expiry == null) return dir(1);
          if (b.expiry == null) return dir(-1);
          return dir(a.expiry!.compareTo(b.expiry!));
        });
    }

    return items;
  }

  IconData _getViewIcon(_MedView view) {
    switch (view) {
      case _MedView.list:
        return Icons.view_list;
      case _MedView.compact:
        return Icons.view_comfy_alt;
      case _MedView.large:
        return Icons.view_comfortable;
    }
  }

  Future<void> _cycleView() async {
    final order = [_MedView.large, _MedView.compact, _MedView.list];
    final idx = order.indexOf(_view);
    final next = order[(idx + 1) % order.length];
    await _saveView(next);
  }

  // Helpers for list view formatting (duplicated from card helpers)
  String _formatDateDdMm(DateTime d) => DateFormat('dd/MM').format(d);

  Color _stockStatusColorFor(BuildContext context, Medication m) {
    final theme = Theme.of(context);
    final baseline = m.lowStockThreshold;
    if (baseline != null && baseline > 0) {
      final pct = (m.stockValue / baseline).clamp(0.0, 1.0);
      if (pct <= 0.2) return theme.colorScheme.error;
      if (pct <= 0.5) return Colors.orange;
      return theme.colorScheme.primary;
    }
    if (m.lowStockEnabled && m.stockValue <= (m.lowStockThreshold ?? 0)) {
      return theme.colorScheme.error;
    }
    return theme.colorScheme.onSurface;
  }

  TextSpan _stockStatusTextSpanFor(BuildContext context, Medication m) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
    );
    final stockInfo = MedicationDisplayHelpers.calculateStock(m);

    if (stockInfo.isCountUnit) {
      final colored = _stockStatusColorFor(context, m);
      return TextSpan(
        style: baseStyle,
        children: [
          TextSpan(
            text: '${stockInfo.current.floor()}',
            style: TextStyle(fontWeight: FontWeight.w800, color: colored),
          ),
          TextSpan(
            text:
                '/${stockInfo.total.floor()} ${MedicationDisplayHelpers.stockUnitLabel(m.stockUnit)}',
          ),
        ],
      );
    }
    return TextSpan(
      style: baseStyle,
      children: [
        TextSpan(
          text: fmt2(m.stockValue),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: _stockStatusColorFor(context, m),
          ),
        ),
        TextSpan(
          text: ' ${MedicationDisplayHelpers.stockUnitLabel(m.stockUnit)}',
        ),
      ],
    );
  }

  Widget _buildMedList(BuildContext context, List<Medication> items) {
    switch (_view) {
      case _MedView.list:
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 56, 16, 120),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final m = items[index];
            final strengthLabel =
                '${fmt2(m.strengthValue)} ${MedicationDisplayHelpers.unitLabel(m.strengthUnit)} '
                '${MedicationDisplayHelpers.formLabel(m.form, plural: true)}';
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              title: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  text: m.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  children: [
                    if (m.manufacturer?.isNotEmpty ?? false)
                      TextSpan(
                        text: '  •  ${m.manufacturer!}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    strengthLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: kTextLightGrey(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: _stockStatusTextSpanFor(context, m),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (m.expiry != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            _formatDateDdMm(m.expiry!),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color:
                                      (m.expiry!.isBefore(
                                        DateTime.now().add(
                                          const Duration(days: 30),
                                        ),
                                      ))
                                      ? Theme.of(context).colorScheme.error
                                      : kTextLightGrey(context),
                                ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              onTap: () => context.push('/medications/${m.id}'),
            );
          },
        );
      case _MedView.compact:
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 56, 16, 120),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) => _MedCard(m: items[i], dense: true),
        );
      case _MedView.large:
        // Large view uses centralized LargeCard layout.
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 56, 16, 120),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _MedLargeCard(m: items[i]),
        );
    }
  }
}

class _MedCard extends StatelessWidget {
  const _MedCard({required this.m, required this.dense});
  final Medication m;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (!dense) {
      return _MedLargeCard(m: m);
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final stockInfo = MedicationDisplayHelpers.calculateStock(m);

    final strengthAndFormLabel =
        '${fmt2(m.strengthValue)} ${MedicationDisplayHelpers.unitLabel(m.strengthUnit)} '
        '${MedicationDisplayHelpers.formLabel(m.form)}';

    return GlassCardSurface(
      onTap: () => context.push('/medications/${m.id}'),
      useGradient: false,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    m.manufacturer ?? 'Medication',
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.1,
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    m.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: kFieldSpacing),
                  Text(
                    '${stockInfo.label} · $strengthAndFormLabel',
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: kSpacingM),
            MiniStockGauge(percentage: stockInfo.percentage),
          ],
        ),
      ),
    );
  }
}

class _MedLargeCard extends StatelessWidget {
  const _MedLargeCard({required this.m});

  final Medication m;

  @override
  Widget build(BuildContext context) {
    return LargeCard(
      onTap: () => context.push('/medications/${m.id}'),
      leading: _buildLeading(context),
      trailing: _buildTrailing(context),
      footer: _buildFooter(context),
    );
  }

  Widget _buildLeading(BuildContext context) {
    final primaryStorage = m.storageLocation;
    final fallbackStorage = m.activeVialStorageLocation;
    final storageLabel = (primaryStorage?.isNotEmpty ?? false)
        ? primaryStorage
        : fallbackStorage;
    final strengthQuantityLabel =
        '${fmt2(m.strengthValue)} ${MedicationDisplayHelpers.unitLabel(m.strengthUnit)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          m.name,
          style: cardTitleStyle(context)?.copyWith(fontWeight: FontWeight.w800),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: kSpacingS),
        if (m.manufacturer != null && m.manufacturer!.isNotEmpty) ...[
          Text(
            m.manufacturer!,
            style: helperTextStyle(context)?.copyWith(fontSize: kFontSizeSmall),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: kSpacingXS),
        ],
        RichText(
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            style: bodyTextStyle(context),
            children: [
              TextSpan(
                text: strengthQuantityLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text:
                    ' ${MedicationDisplayHelpers.formLabel(m.form, plural: true)}',
              ),
            ],
          ),
        ),
        if (storageLabel?.isNotEmpty ?? false) ...[
          const SizedBox(height: kSpacingXS),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: kIconSizeSmall,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: kSpacingXS),
              Expanded(
                child: Text(
                  storageLabel!,
                  style: helperTextStyle(
                    context,
                  )?.copyWith(fontSize: kFontSizeSmall),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTrailing(BuildContext context) {
    final stockInfo = MedicationDisplayHelpers.calculateStock(m);
    final pctRounded = stockInfo.percentage.clamp(0, 100).round();

    final cs = Theme.of(context).colorScheme;
    final fractionText = stockInfo.fractionPart;
    final trailingUnitText = stockInfo.unitPart;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (stockInfo.isMdv)
          DualStockDonutGauge(
            outerPercentage: stockInfo.percentage,
            innerPercentage: stockInfo.backupPercentage,
            primaryLabel: '$pctRounded%',
          )
        else
          StockDonutGauge(
            percentage: stockInfo.percentage,
            primaryLabel: '$pctRounded%',
          ),
        const SizedBox(height: kSpacingXS),
        Align(
          alignment: Alignment.centerRight,
          child: RichText(
            textAlign: TextAlign.right,
            text: TextSpan(
              style: helperTextStyle(context)?.copyWith(fontSize: 9),
              children: [
                TextSpan(
                  text: fractionText,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
                if (trailingUnitText.isNotEmpty)
                  TextSpan(text: ' $trailingUnitText'),
              ],
            ),
          ),
        ),
        if (m.form == MedicationForm.multiDoseVial)
          Padding(
            padding: const EdgeInsets.only(top: kSpacingXS),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                _buildMdvSecondaryLine(),
                style: helperTextStyle(context)?.copyWith(fontSize: 9),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
          ),
      ],
    );
  }

  String _buildMdvSecondaryLine() {
    // Active vial total volume
    final containerMl = m.containerVolumeMl;

    // Backup/unopened vials: use stockValue when the stockUnit is multi-dose vials
    final hasMdvUnit = m.stockUnit == StockUnit.multiDoseVials;
    final backupCount = hasMdvUnit ? m.stockValue.floor() : null;

    if (backupCount != null && backupCount > 0) {
      final total = backupCount;
      return '$backupCount/$total reserve vials';
    }

    if (containerMl != null) {
      return '${fmt2(containerMl)} mL vial';
    }

    return '';
  }

  String _formatExpiryLabel(DateTime expiry) {
    return DateFormat('dd MMM').format(expiry);
  }

  Color _expiryTextColor(BuildContext context, DateTime expiry) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    if (expiry.isBefore(now)) {
      return cs.error;
    }
    if (expiry.isBefore(now.add(const Duration(days: 30)))) {
      return cs.error;
    }
    return cs.onSurfaceVariant.withValues(alpha: kOpacityMediumHigh);
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);

    final icons = <IconData>[];
    final isDark = m.activeVialLightSensitive || m.backupVialsLightSensitive;
    final isFrozen =
        m.activeVialRequiresFreezer || m.backupVialsRequiresFreezer;
    final isRefrigerated =
        m.requiresRefrigeration == true ||
        m.activeVialRequiresRefrigeration ||
        m.backupVialsRequiresRefrigeration;

    if (isFrozen) {
      icons.add(Icons.ac_unit);
    } else if (isRefrigerated) {
      icons.add(Icons.ac_unit);
    }
    if (isDark) {
      icons.add(Icons.dark_mode);
    }
    if (icons.isEmpty) {
      icons.add(Icons.thermostat);
    }

    // Cap at 2 icons
    final visibleIcons = icons.take(2).toList();

    return Row(
      children: [
        ...visibleIcons.map(
          (icon) => Padding(
            padding: const EdgeInsets.only(right: kSpacingXS),
            child: Icon(
              icon,
              size: kIconSizeSmall,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const Spacer(),
        if (m.expiry != null)
          Text(
            'Exp ${_formatExpiryLabel(m.expiry!)}',
            style: helperTextStyle(context)?.copyWith(
              fontSize: 9,
              color: _expiryTextColor(context, m.expiry!),
            ),
          ),
      ],
    );
  }
}
