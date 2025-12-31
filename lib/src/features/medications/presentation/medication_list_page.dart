import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/utils/format.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
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

enum _SortBy { name, manufacturer, form, stock, strength, expiry }

enum _FilterBy {
  all,
  lowStock,
  expiringSoon,
  refrigerated,
  freezer,
  lightSensitive,
  formTablet,
  formCapsule,
  formPrefilledSyringe,
  formSingleDoseVial,
  formMultiDoseVial,
}

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

  ({int fieldPriority, int startsWithPriority, int indexPriority})
  _searchRelevanceKey(Medication m, String qLower) {
    final name = m.name.toLowerCase();
    final manufacturer = (m.manufacturer ?? '').toLowerCase();
    final description = (m.description ?? '').toLowerCase();

    // Lower tuple values are higher priority.
    // Field priority: name -> manufacturer -> description.
    // Within a field: startsWith beats contains; earlier index beats later.
    if (name.contains(qLower)) {
      final idx = name.indexOf(qLower);
      return (
        fieldPriority: 0,
        startsWithPriority: name.startsWith(qLower) ? 0 : 1,
        indexPriority: idx < 0 ? 9999 : idx,
      );
    }
    if (manufacturer.contains(qLower)) {
      final idx = manufacturer.indexOf(qLower);
      return (
        fieldPriority: 1,
        startsWithPriority: manufacturer.startsWith(qLower) ? 0 : 1,
        indexPriority: idx < 0 ? 9999 : idx,
      );
    }
    if (description.contains(qLower)) {
      final idx = description.indexOf(qLower);
      return (
        fieldPriority: 2,
        startsWithPriority: description.startsWith(qLower) ? 0 : 1,
        indexPriority: idx < 0 ? 9999 : idx,
      );
    }

    return (fieldPriority: 999, startsWithPriority: 1, indexPriority: 9999);
  }

  bool _matchesSearchQuery(Medication m, String qLower) {
    return m.name.toLowerCase().contains(qLower) ||
        (m.manufacturer ?? '').toLowerCase().contains(qLower) ||
        (m.description ?? '').toLowerCase().contains(qLower);
  }

  bool _isRefrigerated(Medication m) {
    return m.requiresRefrigeration == true ||
        m.activeVialRequiresRefrigeration ||
        m.backupVialsRequiresRefrigeration;
  }

  bool _isFrozen(Medication m) {
    return m.requiresFreezer == true ||
        m.activeVialRequiresFreezer ||
        m.backupVialsRequiresFreezer;
  }

  bool _isLightSensitive(Medication m) {
    return m.lightSensitive == true ||
        m.activeVialLightSensitive ||
        m.backupVialsLightSensitive;
  }

  DateTime? _effectiveExpiry(Medication m) {
    final candidates = <DateTime?>[
      m.expiry,
      m.reconstitutedVialExpiry,
      m.backupVialsExpiry,
    ].whereType<DateTime>().toList(growable: false);
    if (candidates.isEmpty) return null;
    candidates.sort();
    return candidates.first;
  }

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
    final schedulesBox = Hive.box<Schedule>('schedules');

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
                          Icon(
                            Icons.search_off,
                            size: kEmptyStateIconSize,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: kOpacityMedium),
                          ),
                          const SizedBox(height: kSpacingM),
                          Text(
                            'No medications found for "$_query"',
                            style: mutedTextStyle(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
          }

          return ValueListenableBuilder(
            valueListenable: schedulesBox.listenable(),
            builder: (context, Box<Schedule> sb, __) {
              final schedules = sb.values.toList(growable: false);
              return Stack(
                children: [
                  _buildMedList(context, items, schedules),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildToolbar(context),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/medications/select-type'),
        icon: const Icon(Icons.add),
        label: const Text('Add Medication'),
      ),
    );
  }

  IconData _getViewIcon(_MedView v) => switch (v) {
    _MedView.list => Icons.view_list,
    _MedView.compact => Icons.view_comfy_alt,
    _MedView.large => Icons.view_comfortable,
  };

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
                const PopupMenuItem(
                  value: _FilterBy.freezer,
                  child: Text('Freezer'),
                ),
                const PopupMenuItem(
                  value: _FilterBy.lightSensitive,
                  child: Text('Light sensitive'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: _FilterBy.formTablet,
                  child: Text('Tablets'),
                ),
                const PopupMenuItem(
                  value: _FilterBy.formCapsule,
                  child: Text('Capsules'),
                ),
                const PopupMenuItem(
                  value: _FilterBy.formPrefilledSyringe,
                  child: Text('Pre-filled syringes'),
                ),
                const PopupMenuItem(
                  value: _FilterBy.formSingleDoseVial,
                  child: Text('Single dose vials'),
                ),
                const PopupMenuItem(
                  value: _FilterBy.formMultiDoseVial,
                  child: Text('Multi-dose vials'),
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
                  value: _SortBy.manufacturer,
                  child: Text('Sort by manufacturer'),
                ),
                const PopupMenuItem(
                  value: _SortBy.form,
                  child: Text('Sort by form'),
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
      final qLower = _query.toLowerCase();
      items = items.where((m) => _matchesSearchQuery(m, qLower)).toList();
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
        items = items.where((m) {
          final exp = _effectiveExpiry(m);
          return exp != null && exp.isBefore(soon);
        }).toList();
      case _FilterBy.refrigerated:
        items = items.where(_isRefrigerated).toList();
      case _FilterBy.freezer:
        items = items.where(_isFrozen).toList();
      case _FilterBy.lightSensitive:
        items = items.where(_isLightSensitive).toList();
      case _FilterBy.formTablet:
        items = items.where((m) => m.form == MedicationForm.tablet).toList();
      case _FilterBy.formCapsule:
        items = items.where((m) => m.form == MedicationForm.capsule).toList();
      case _FilterBy.formPrefilledSyringe:
        items = items
            .where((m) => m.form == MedicationForm.prefilledSyringe)
            .toList();
      case _FilterBy.formSingleDoseVial:
        items = items
            .where((m) => m.form == MedicationForm.singleDoseVial)
            .toList();
      case _FilterBy.formMultiDoseVial:
        items = items
            .where((m) => m.form == MedicationForm.multiDoseVial)
            .toList();
    }

    // Apply sorting
    int dir(int v) => _sortAsc ? v : -v;

    int compareBySelectedSort(Medication a, Medication b) {
      switch (_sortBy) {
        case _SortBy.name:
          return dir(a.name.compareTo(b.name));
        case _SortBy.manufacturer:
          final am = (a.manufacturer ?? '').trim();
          final bm = (b.manufacturer ?? '').trim();
          final aEmpty = am.isEmpty;
          final bEmpty = bm.isEmpty;
          if (aEmpty != bEmpty) {
            return aEmpty ? dir(1) : dir(-1);
          }
          return dir(am.compareTo(bm));
        case _SortBy.form:
          final byForm = dir(a.form.index.compareTo(b.form.index));
          if (byForm != 0) return byForm;
          return dir(a.name.compareTo(b.name));
        case _SortBy.stock:
          return dir(a.stockValue.compareTo(b.stockValue));
        case _SortBy.strength:
          return dir(a.strengthValue.compareTo(b.strengthValue));
        case _SortBy.expiry:
          final ae = _effectiveExpiry(a);
          final be = _effectiveExpiry(b);
          if (ae == null && be == null) return 0;
          if (ae == null) return dir(1);
          if (be == null) return dir(-1);
          return dir(ae.compareTo(be));
      }
    }

    items.sort((a, b) {
      if (_query.isNotEmpty) {
        final qLower = _query.toLowerCase();
        final ak = _searchRelevanceKey(a, qLower);
        final bk = _searchRelevanceKey(b, qLower);
        final byField = ak.fieldPriority.compareTo(bk.fieldPriority);
        if (byField != 0) return byField;
        final byStartsWith = ak.startsWithPriority.compareTo(
          bk.startsWithPriority,
        );
        if (byStartsWith != 0) return byStartsWith;
        final byIndex = ak.indexPriority.compareTo(bk.indexPriority);
        if (byIndex != 0) return byIndex;
      }
      final bySelectedSort = compareBySelectedSort(a, b);
      if (bySelectedSort != 0) return bySelectedSort;
      return a.name.compareTo(b.name);
    });

    return items;
  }

  Future<void> _cycleView() async {
    final order = [_MedView.large, _MedView.compact, _MedView.list];
    final idx = order.indexOf(_view);
    final next = order[(idx + 1) % order.length];
    await _saveView(next);
  }

  // Helpers for list view formatting (duplicated from card helpers)
  String _formatDateDdMm(DateTime d) => DateFormat('dd/MM').format(d);

  TextSpan _stockStatusTextSpanFor(
    BuildContext context,
    Medication m, {
    TextStyle? baseStyle,
  }) {
    return _MedicationStockStatusText.textSpanFor(
      context,
      m,
      baseStyle: baseStyle,
    );
  }

  Widget _buildCompactListRow(BuildContext context, Medication m) {
    final cs = Theme.of(context).colorScheme;

    final strengthLabel =
        '${fmt2(m.strengthValue)} ${MedicationDisplayHelpers.unitLabel(m.strengthUnit)} '
        '${MedicationDisplayHelpers.formLabel(m.form, plural: true)}';
    final manufacturer = (m.manufacturer ?? '').trim();
    final detailLabel = manufacturer.isEmpty
        ? strengthLabel
        : '$manufacturer · $strengthLabel';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/medications/${m.id}'),
        borderRadius: BorderRadius.circular(kBorderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kSpacingS,
            vertical: kSpacingXS,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      m.name,
                      style: cardTitleStyle(context)?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: kSpacingXS),
                    Text(
                      detailLabel,
                      style: helperTextStyle(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: kSpacingS),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: _stockStatusTextSpanFor(
                      context,
                      m,
                      baseStyle: helperTextStyle(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                  if (m.expiry != null) ...[
                    const SizedBox(height: kSpacingXS),
                    Text(
                      _formatDateDdMm(m.expiry!),
                      style: helperTextStyle(
                        context,
                        color: expiryStatusColor(
                          context,
                          createdAt: m.createdAt,
                          expiry: m.expiry!,
                        ),
                      )?.copyWith(fontSize: kFontSizeSmall),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedList(
    BuildContext context,
    List<Medication> items,
    List<Schedule> schedules,
  ) {
    switch (_view) {
      case _MedView.list:
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 56, 16, 120),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final m = items[index];
            return _buildCompactListRow(context, m);
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
          separatorBuilder: (_, __) => const SizedBox(height: kSpacingS),
          itemBuilder: (context, i) =>
              _MedLargeCard(m: items[i], schedules: schedules),
        );
    }
  }
}

class _MedicationStockStatusText {
  static Color colorFor(BuildContext context, Medication m) {
    final stockInfo = MedicationDisplayHelpers.calculateStock(m);
    return stockStatusColorFromPercentage(
      context,
      percentage: stockInfo.percentage,
    );
  }

  static TextSpan textSpanFor(
    BuildContext context,
    Medication m, {
    TextStyle? baseStyle,
  }) {
    final theme = Theme.of(context);
    final resolvedBaseStyle = (baseStyle ?? helperTextStyle(context))?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface.withValues(alpha: kOpacityMediumHigh),
    );
    final stockInfo = MedicationDisplayHelpers.calculateStock(m);

    if (m.form == MedicationForm.multiDoseVial &&
        m.containerVolumeMl != null &&
        m.containerVolumeMl! > 0) {
      final totalMl = m.containerVolumeMl!.toDouble();
      final currentRaw = (m.activeVialVolume ?? totalMl).toDouble();
      final currentMl = currentRaw.clamp(0.0, totalMl);
      final colored = colorFor(context, m);

      return TextSpan(
        style: resolvedBaseStyle,
        children: [
          TextSpan(
            text: fmt2(currentMl),
            style: TextStyle(fontWeight: FontWeight.w800, color: colored),
          ),
          TextSpan(text: '/${fmt2(totalMl)} mL of vial'),
        ],
      );
    }

    if (stockInfo.isCountUnit) {
      final colored = colorFor(context, m);
      return TextSpan(
        style: resolvedBaseStyle,
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
      style: resolvedBaseStyle,
      children: [
        TextSpan(
          text: fmt2(m.stockValue),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: colorFor(context, m),
          ),
        ),
        TextSpan(
          text: ' ${MedicationDisplayHelpers.stockUnitLabel(m.stockUnit)}',
        ),
      ],
    );
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

    final cs = Theme.of(context).colorScheme;

    final stockInfo = MedicationDisplayHelpers.calculateStock(m);
    final stockColor = stockStatusColorFromPercentage(
      context,
      percentage: stockInfo.percentage,
    );

    final strengthAndFormLabel =
        '${fmt2(m.strengthValue)} ${MedicationDisplayHelpers.unitLabel(m.strengthUnit)} '
        '${MedicationDisplayHelpers.formLabel(m.form)}';

    return GlassCardSurface(
      onTap: () => context.push('/medications/${m.id}'),
      useGradient: false,
      padding: kCompactCardPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  m.name,
                  style: cardTitleStyle(
                    context,
                  )?.copyWith(fontWeight: FontWeight.w800, color: cs.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (m.manufacturer?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: kSpacingXS),
                  Text(
                    m.manufacturer!.trim(),
                    style: helperTextStyle(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: kSpacingXS),
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: helperTextStyle(context),
                    children: [
                      _MedicationStockStatusText.textSpanFor(
                        context,
                        m,
                        baseStyle: helperTextStyle(context),
                      ),
                      TextSpan(text: ' · $strengthAndFormLabel'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: kSpacingS),
          MiniStockGauge(
            percentage: stockInfo.percentage,
            color: stockColor,
            size: kStandardFieldHeight,
          ),
        ],
      ),
    );
  }
}

class _MedLargeCard extends StatelessWidget {
  const _MedLargeCard({required this.m, this.schedules = const []});

  final Medication m;
  final List<Schedule> schedules;

  int _activeScheduleCount() {
    return schedules.where((s) => s.medicationId == m.id && s.active).length;
  }

  @override
  Widget build(BuildContext context) {
    final footer = _buildFooter(context);
    return LargeCard(
      onTap: () => context.push('/medications/${m.id}'),
      dense: true,
      leading: _buildLeading(context),
      trailing: _buildTrailing(context),
      footer: footer,
    );
  }

  List<IconData> _storageConditionIconsFor({
    required bool requiresFreezer,
    required bool requiresRefrigeration,
    required bool lightSensitive,
  }) {
    final icons = <IconData>[];
    if (requiresFreezer) {
      icons.add(Icons.severe_cold);
    }
    if (requiresRefrigeration) {
      icons.add(Icons.ac_unit);
    }
    if (lightSensitive) {
      icons.add(Icons.dark_mode);
    }
    if (icons.isEmpty) {
      icons.add(Icons.thermostat);
    }

    // Cap at 3 icons to allow for more info.
    return icons.take(3).toList();
  }

  List<IconData> _combinedStorageConditionIcons() {
    return _storageConditionIconsFor(
      requiresFreezer:
          m.activeVialRequiresFreezer || m.backupVialsRequiresFreezer,
      requiresRefrigeration:
          m.requiresRefrigeration == true ||
          m.activeVialRequiresRefrigeration ||
          m.backupVialsRequiresRefrigeration,
      lightSensitive: m.activeVialLightSensitive || m.backupVialsLightSensitive,
    );
  }

  List<IconData> _activeVialStorageConditionIcons() {
    return _storageConditionIconsFor(
      requiresFreezer: m.activeVialRequiresFreezer,
      requiresRefrigeration: m.activeVialRequiresRefrigeration,
      lightSensitive: m.activeVialLightSensitive,
    );
  }

  List<IconData> _sealedVialsStorageConditionIcons() {
    return _storageConditionIconsFor(
      requiresFreezer: m.backupVialsRequiresFreezer,
      requiresRefrigeration: m.backupVialsRequiresRefrigeration,
      lightSensitive: m.backupVialsLightSensitive,
    );
  }

  String? _cleanText(String? value) {
    final v = value?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  String? _pickLocation(String? primary, String? fallback) {
    return _cleanText(primary) ?? _cleanText(fallback);
  }

  Widget _buildStorageLocationRow(BuildContext context, String location) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.location_on_outlined,
          size: kIconSizeSmall,
          color: cs.primary,
        ),
        const SizedBox(width: kSpacingXS),
        Expanded(
          child: Text(
            location,
            style: helperTextStyle(context)?.copyWith(fontSize: kFontSizeSmall),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMdvStorageBlock(
    BuildContext context, {
    required String label,
    required List<IconData> icons,
    required String? location,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Wrap(
              spacing: kSpacingXS,
              runSpacing: kSpacingXS,
              children: [
                for (final icon in icons)
                  Icon(icon, size: kIconSizeSmall, color: cs.primary),
              ],
            ),
            const SizedBox(width: kSpacingXS),
            Expanded(
              child: Text(
                label,
                style: helperTextStyle(context)?.copyWith(
                  fontSize: kFontSizeHint,
                  fontWeight: kFontWeightSemiBold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (location != null) ...[
          const SizedBox(height: kSpacingXS),
          _buildStorageLocationRow(context, location),
        ],
      ],
    );
  }

  Widget _buildStorageInsetSection(
    BuildContext context, {
    required List<IconData> activeIcons,
    required List<IconData> sealedIcons,
    required List<IconData> combinedIcons,
  }) {
    final location = _pickLocation(
      m.storageLocation,
      m.activeVialStorageLocation,
    );
    final activeLocation = _pickLocation(
      m.activeVialStorageLocation,
      m.storageLocation,
    );
    final sealedLocation = _pickLocation(
      m.backupVialsStorageLocation,
      m.storageLocation,
    );

    final body = m.form == MedicationForm.multiDoseVial
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMdvStorageBlock(
                context,
                label: 'Active',
                icons: activeIcons,
                location: activeLocation,
              ),
              const SizedBox(height: kSpacingS),
              _buildMdvStorageBlock(
                context,
                label: 'Sealed',
                icons: sealedIcons,
                location: sealedLocation,
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: kSpacingXS,
                runSpacing: kSpacingXS,
                children: [
                  for (final icon in combinedIcons)
                    Icon(icon, size: kIconSizeSmall),
                ],
              ),
              if (location != null) ...[
                const SizedBox(height: kSpacingXS),
                _buildStorageLocationRow(context, location),
              ],
            ],
          );

    return Container(
      width: double.infinity,
      padding: kInsetSectionPadding,
      decoration: buildInsetSectionDecoration(
        context: context,
        backgroundOpacity: 0.9,
      ),
      child: body,
    );
  }

  Widget _buildLeading(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeScheduleCount = _activeScheduleCount();
    final strengthQuantityLabel =
        '${fmt2(m.strengthValue)} ${MedicationDisplayHelpers.unitLabel(m.strengthUnit)}';
    final activeIcons = _activeVialStorageConditionIcons();
    final sealedIcons = _sealedVialsStorageConditionIcons();
    final combinedIcons = _combinedStorageConditionIcons();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          m.name,
          style: cardTitleStyle(
            context,
          )?.copyWith(fontWeight: FontWeight.w800, color: cs.primary),
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
        const SizedBox(height: kSpacingXS),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: kIconSizeSmall,
              color: activeScheduleCount > 0
                  ? cs.primary
                  : cs.onSurfaceVariant.withValues(alpha: kOpacityMediumLow),
            ),
            const SizedBox(width: kSpacingXS),
            Expanded(
              child: Text(
                activeScheduleCount == 1
                    ? '1 active schedule'
                    : '$activeScheduleCount active schedules',
                style: helperTextStyle(
                  context,
                  color: activeScheduleCount > 0
                      ? cs.primary
                      : cs.onSurfaceVariant.withValues(
                          alpha: kOpacityMediumLow,
                        ),
                )?.copyWith(fontSize: kFontSizeSmall),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: kSpacingS),
        _buildStorageInsetSection(
          context,
          activeIcons: activeIcons,
          sealedIcons: sealedIcons,
          combinedIcons: combinedIcons,
        ),
      ],
    );
  }

  Widget _buildTrailing(BuildContext context) {
    final stockInfo = MedicationDisplayHelpers.calculateStock(m);
    final pctRounded = stockInfo.percentage.clamp(0, 100).round();
    final baseStyle = helperTextStyle(context)?.copyWith(fontSize: 9);
    final stockColor = stockStatusColorFromPercentage(
      context,
      percentage: stockInfo.percentage,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Single ring for all: shows Active Vial % for MDV, overall stock % for others
        Align(
          alignment: Alignment.centerRight,
          child: StockDonutGauge(
            percentage: stockInfo.percentage,
            primaryLabel: '$pctRounded%',
            color: stockColor,
            textColor: stockColor,
          ),
        ),
        const SizedBox(height: kSpacingXS),
        Align(
          alignment: Alignment.centerRight,
          child: RichText(
            textAlign: TextAlign.right,
            text: _MedicationStockStatusText.textSpanFor(
              context,
              m,
              baseStyle: baseStyle,
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
      final label = backupCount == 1 ? 'sealed vial' : 'sealed vials';
      return '$backupCount $label';
    }

    if (containerMl != null) {
      return '${fmt2(containerMl)} mL vial';
    }

    return '';
  }

  String _formatExpiryLabel(DateTime expiry) {
    return DateFormat('dd MMM').format(expiry);
  }

  Widget? _buildFooter(BuildContext context) {
    if (m.expiry == null) return null;
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        'Exp ${_formatExpiryLabel(m.expiry!)}',
        style: helperTextStyle(context)?.copyWith(
          fontSize: 9,
          color: expiryStatusColor(
            context,
            createdAt: m.createdAt,
            expiry: m.expiry!,
          ),
        ),
      ),
    );
  }
}
