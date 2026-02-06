import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:dosifi_v5/src/core/utils/format.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:dosifi_v5/src/core/ui/experimental_ui_settings.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:dosifi_v5/src/features/medications/domain/medication.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:dosifi_v5/src/features/medications/presentation/medication_display_helpers.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:dosifi_v5/src/features/schedules/domain/schedule_occurrence_service.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:dosifi_v5/src/widgets/glass_card_surface.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:dosifi_v5/src/widgets/large_card.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:dosifi_v5/src/widgets/compact_storage_line.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:dosifi_v5/src/widgets/stock_donut_gauge.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:dosifi_v5/src/widgets/status_pill.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dosifi_v5/src/features/medications/presentation/providers.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';
import 'package:dosifi_v5/src/features/schedules/presentation/providers.dart';
import 'package:dosifi_v5/src/core/utils/datetime_formatter.dart';

enum _MedView { list, compact, large }

enum _SortBy { name, nextDose, mostUsed, manufacturer, form, stock, strength, expiry }

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

  static const _kPrefsViewKey = 'medication_list_view';
  static const _kPrefsSortByKey = 'medication_list_sort_by';
  static const _kPrefsSortAscKey = 'medication_list_sort_asc';

  IconData _viewIcon(_MedView v) => switch (v) {
    _MedView.list => Icons.view_list,
    _MedView.compact => Icons.view_comfy_alt,
    _MedView.large => Icons.view_comfortable,
  };

  void _cycleView() {
    final next = switch (_view) {
      _MedView.large => _MedView.compact,
      _MedView.compact => _MedView.list,
      _MedView.list => _MedView.large,
    };
    _saveView(next);
  }

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
    _loadSavedViewAndSort();
  }

  Future<void> _loadSavedViewAndSort() async {
    final prefs = await SharedPreferences.getInstance();
    final savedView = prefs.getString(_kPrefsViewKey) ?? 'large';
    final savedSortBy = prefs.getString(_kPrefsSortByKey) ?? _SortBy.name.name;
    final savedSortAsc = prefs.getBool(_kPrefsSortAscKey) ?? true;
    setState(() {
      _view = _MedView.values.firstWhere(
        (v) => v.name == savedView,
        orElse: () => _MedView.large,
      );

      _sortBy = _SortBy.values.firstWhere(
        (v) => v.name == savedSortBy,
        orElse: () => _SortBy.name,
      );
      _sortAsc = savedSortAsc;
    });
  }

  Future<void> _saveView(_MedView view) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefsViewKey, view.name);
    setState(() => _view = view);
  }

  Future<void> _saveSort({_SortBy? sortBy, bool? sortAsc}) async {
    final nextSortBy = sortBy ?? _sortBy;
    final nextSortAsc = sortAsc ?? _sortAsc;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefsSortByKey, nextSortBy.name);
    await prefs.setBool(_kPrefsSortAscKey, nextSortAsc);
    setState(() {
      _sortBy = nextSortBy;
      _sortAsc = nextSortAsc;
    });
  }

  // Ensure we have an original stock value for count-based units so that we can
  // display Remaining / Original correctly. This sets it lazily to the first
  // observed value and updates it when the current stock increases (restock).
  void _ensureInitialStockValues(List<Medication> items) {
    final box = ref.read(medicationsBoxProvider);
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
    ref.watch(medicationsBoxChangesProvider);
    ref.watch(schedulesBoxChangesProvider);

    final box = ref.watch(medicationsBoxProvider);
    final schedulesBox = ref.watch(schedulesBoxProvider);

    return Scaffold(
      appBar: const GradientAppBar(title: 'Medications', forceBackButton: true),
      body: Builder(
        builder: (context) {
          final meds = box.values.toList(growable: false);

          // Show initial state if no medications exist, or the filtered
          // empty state when search removes everything.
          if (meds.isEmpty) {
            if (_query.isEmpty) {
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

          final schedules = schedulesBox.values.toList(growable: false);
          final items = _getFilteredAndSortedMedications(
            meds,
            schedules: schedules,
          );

              // Ensure initial stock values so large cards can show current vs
              // initial amounts.
              _ensureInitialStockValues(items);

          if (items.isEmpty) {
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/medications/select-type'),
        icon: const Icon(Icons.add),
        label: const Text('Add Medication'),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconColor = cs.onSurfaceVariant.withValues(alpha: kOpacityMedium);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        kPageHorizontalPadding,
        kSpacingXS,
        kSpacingXS,
        kSpacingXS,
      ),
      child: Row(
        children: [
          if (_searchExpanded)
            Expanded(
              child: TextField(
                autofocus: true,
                textCapitalization: kTextCapitalizationDefault,
                decoration: buildFieldDecoration(
                  context,
                  hint: 'Search medications',
                  prefixIcon: Icon(
                    Icons.search,
                    size: kIconSizeMedium,
                    color: iconColor,
                  ),
                  suffixIcon: IconButton(
                    iconSize: kIconSizeMedium,
                    icon: Icon(Icons.close, color: iconColor),
                    onPressed: () => setState(() {
                      _searchExpanded = false;
                      _query = '';
                    }),
                  ),
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.search, color: iconColor),
              onPressed: () => setState(() => _searchExpanded = true),
              tooltip: 'Search medications',
            ),
          if (_searchExpanded) const SizedBox(width: kSpacingS),
          if (_searchExpanded)
            IconButton(
              icon: Icon(_viewIcon(_view), color: iconColor),
              tooltip: 'Change layout',
              onPressed: _cycleView,
            ),
          if (!_searchExpanded) const Spacer(),
          if (!_searchExpanded)
            IconButton(
              icon: Icon(_viewIcon(_view), color: iconColor),
              tooltip: 'Change layout',
              onPressed: _cycleView,
            ),
          if (!_searchExpanded) const SizedBox(width: kSpacingS),
          if (!_searchExpanded)
            PopupMenuButton<_FilterBy>(
              icon: Icon(
                Icons.filter_list,
                color: _filterBy != _FilterBy.all ? cs.primary : iconColor,
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
          if (!_searchExpanded)
            PopupMenuButton<Object>(
              icon: Icon(Icons.sort, color: iconColor),
              tooltip: 'Sort medications',
              onSelected: (value) {
                if (value is _SortBy) {
                  final nextSortAsc = switch (value) {
                    _SortBy.mostUsed => false,
                    _SortBy.nextDose => true,
                    _ => _sortAsc,
                  };
                  _saveSort(sortBy: value, sortAsc: nextSortAsc);
                } else if (value == 'toggle_dir') {
                  _saveSort(sortAsc: !_sortAsc);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _SortBy.name,
                  child: Text('Sort by name'),
                ),
                const PopupMenuItem(
                  value: _SortBy.nextDose,
                  child: Text('Sort by next dose'),
                ),
                const PopupMenuItem(
                  value: _SortBy.mostUsed,
                  child: Text('Sort by most used'),
                ),
                const PopupMenuDivider(),
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
                        size: kIconSizeSmall,
                      ),
                      const SizedBox(width: kSpacingS),
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
    {required List<Schedule> schedules}
  ) {
    var items = List<Medication>.from(medications);

    final nextDoseByMedId = <String, DateTime>{};
    final scheduledDoses7dByMedId = <String, int>{};
    if (_sortBy == _SortBy.nextDose || _sortBy == _SortBy.mostUsed) {
      final now = DateTime.now();
      final horizonEnd = now.add(const Duration(days: 30));
      final usageWindowEnd = now.add(const Duration(days: 7));

      for (final s in schedules) {
        if (!s.isActive) continue;
        final medId = s.medicationId;
        if (medId == null) continue;

        final occurrences = ScheduleOccurrenceService.occurrencesInRange(
          s,
          now,
          horizonEnd,
        );
        if (occurrences.isEmpty) continue;

        final nextOccurrence = occurrences.first;
        final existingNext = nextDoseByMedId[medId];
        if (existingNext == null || nextOccurrence.isBefore(existingNext)) {
          nextDoseByMedId[medId] = nextOccurrence;
        }

        var count7d = 0;
        for (final dt in occurrences) {
          if (dt.isAfter(usageWindowEnd)) break;
          count7d++;
        }
        if (count7d > 0) {
          scheduledDoses7dByMedId[medId] =
              (scheduledDoses7dByMedId[medId] ?? 0) + count7d;
        }
      }
    }

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
        case _SortBy.nextDose:
          final an = nextDoseByMedId[a.id];
          final bn = nextDoseByMedId[b.id];
          if (an == null && bn == null) return 0;
          if (an == null) return dir(1);
          if (bn == null) return dir(-1);
          return dir(an.compareTo(bn));
        case _SortBy.mostUsed:
          final ac = scheduledDoses7dByMedId[a.id] ?? 0;
          final bc = scheduledDoses7dByMedId[b.id] ?? 0;
          return dir(ac.compareTo(bc));
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

  DateTime _effectiveCreatedAtForExpiry(Medication m, DateTime expiry) {
    if (m.reconstitutedVialExpiry == expiry && m.reconstitutedAt != null) {
      return m.reconstitutedAt!;
    }
    return m.createdAt;
  }

  Widget? _buildMedicationStatusBadgesRow(BuildContext context, Medication m) {
    if (!ExperimentalUiSettings.value.value.showMedicationListStatusBadges) {
      return null;
    }

    final cs = Theme.of(context).colorScheme;
    final pills = <Widget>[];

    final stockInfo = MedicationDisplayHelpers.calculateStock(m);
    if (stockInfo.current <= 0) {
      pills.add(
        StatusPill(
          label: 'Empty',
          color: cs.error,
          icon: Icons.inventory_2_outlined,
        ),
      );
    } else if (stockInfo.percentage <= (kStockWarningRemainingRatio * 100)) {
      pills.add(
        StatusPill(
          label: 'Low stock',
          color: stockStatusColorFromPercentage(
            context,
            percentage: stockInfo.percentage,
          ),
          icon: Icons.inventory_2_outlined,
        ),
      );
    }

    final effectiveExpiry = _effectiveExpiry(m);
    if (effectiveExpiry != null) {
      final createdAt = _effectiveCreatedAtForExpiry(m, effectiveExpiry);
      final now = DateTime.now();
      if (!effectiveExpiry.isAfter(now)) {
        pills.add(
          StatusPill(
            label: 'Expired',
            color: cs.error,
            icon: Icons.event_busy,
          ),
        );
      } else {
        final ratio = expiryRemainingRatio(
          createdAt: createdAt,
          expiry: effectiveExpiry,
          now: now,
        );
        if (ratio <= kExpiryWarningRemainingRatio) {
          pills.add(
            StatusPill(
              label: ratio <= kExpiryCriticalRemainingRatio
                  ? 'Expiring'
                  : 'Soon',
              color: expiryStatusColor(
                context,
                createdAt: createdAt,
                expiry: effectiveExpiry,
                now: now,
              ),
              icon: Icons.event,
            ),
          );
        }
      }
    }

    if (_isFrozen(m)) {
      pills.add(
        StatusPill(
          label: 'Freezer',
          color: cs.secondary,
          icon: Icons.severe_cold,
        ),
      );
    } else if (_isRefrigerated(m)) {
      pills.add(
        StatusPill(
          label: 'Fridge',
          color: cs.primary,
          icon: Icons.ac_unit,
        ),
      );
    }

    if (_isLightSensitive(m)) {
      pills.add(
        StatusPill(
          label: 'Light',
          color: cs.tertiary,
          icon: Icons.wb_sunny_outlined,
        ),
      );
    }

    if (pills.isEmpty) return null;
    return Wrap(
      spacing: kSpacingXXS,
      runSpacing: kSpacingXXS,
      children: pills,
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

    final badges = _buildMedicationStatusBadgesRow(context, m);

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
                    if (badges != null) ...[
                      const SizedBox(height: kSpacingXXS),
                      badges,
                    ],
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
                      style: smallHelperTextStyle(
                        context,
                        color: expiryStatusColor(
                          context,
                          createdAt: m.createdAt,
                          expiry: m.expiry!,
                        ),
                      ),
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

  int _totalScheduleCount() {
    return schedules.where((s) => s.medicationId == m.id).length;
  }

  int _activeScheduleCount() {
    return schedules.where((s) => s.medicationId == m.id && s.active).length;
  }

  int _pausedScheduleCount() {
    return schedules.where((s) => s.medicationId == m.id && !s.active).length;
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

  TextSpan _mdvRemainingMlSpan(BuildContext context) {
    final theme = Theme.of(context);
    final colored = _MedicationStockStatusText.colorFor(context, m);
    final resolvedBaseStyle = microHelperTextStyle(context)?.copyWith(
      fontWeight: kFontWeightSemiBold,
      color: theme.colorScheme.onSurface.withValues(alpha: kOpacityMediumHigh),
    );

    final totalMl = (m.containerVolumeMl ?? 0).toDouble();
    final currentRaw = (m.activeVialVolume ?? totalMl).toDouble();
    final currentMl = totalMl > 0 ? currentRaw.clamp(0.0, totalMl) : 0.0;

    if (totalMl <= 0) {
      return TextSpan(style: resolvedBaseStyle, text: '');
    }

    return TextSpan(
      style: resolvedBaseStyle,
      children: [
        TextSpan(
          text: fmt2(currentMl),
          style: TextStyle(fontWeight: kFontWeightExtraBold, color: colored),
        ),
        TextSpan(text: '/${fmt2(totalMl)} mL'),
      ],
    );
  }

  TextSpan _mdvRemainingVialsSpan(BuildContext context) {
    final theme = Theme.of(context);
    final colored = _MedicationStockStatusText.colorFor(context, m);
    final resolvedBaseStyle = microHelperTextStyle(context)?.copyWith(
      fontWeight: kFontWeightSemiBold,
      color: theme.colorScheme.onSurface.withValues(alpha: kOpacityMediumHigh),
    );

    final hasMdvUnit = m.stockUnit == StockUnit.multiDoseVials;
    final count = hasMdvUnit ? m.stockValue.floor() : null;
    if (count == null || count <= 0) {
      return TextSpan(style: resolvedBaseStyle, text: '');
    }

    final label = count == 1 ? 'vial' : 'vials';
    return TextSpan(
      style: resolvedBaseStyle,
      children: [
        TextSpan(
          text: '$count',
          style: TextStyle(fontWeight: kFontWeightExtraBold, color: colored),
        ),
        TextSpan(text: ' $label'),
      ],
    );
  }

  Widget _buildCompactStorageLine(
    BuildContext context, {
    required List<IconData> icons,
    required String label,
    required String? location,
    required DateTime? createdAt,
    required DateTime? expiry,
    Widget? trailing,
  }) {
    return CompactStorageLine(
      icons: icons,
      label: label,
      location: location,
      createdAt: createdAt,
      expiry: expiry,
      trailing: trailing,
    );
  }

  Widget _buildStorageInsetSection(
    BuildContext context, {
    required List<IconData> activeIcons,
    required List<IconData> sealedIcons,
    required List<IconData> combinedIcons,
  }) {
    final activeCreatedAt = m.reconstitutedAt ?? m.createdAt;
    final activeExpiry = m.reconstitutedVialExpiry;

    final sealedCreatedAt = m.createdAt;
    final sealedExpiry = m.backupVialsExpiry ?? m.expiry;

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

    final baseRemainingStyle = microHelperTextStyle(context);

    final body = m.form == MedicationForm.multiDoseVial
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCompactStorageLine(
                context,
                label: 'Active',
                icons: activeIcons,
                location: activeLocation,
                createdAt: activeCreatedAt,
                expiry: activeExpiry,
                trailing: RichText(
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: _mdvRemainingMlSpan(context),
                ),
              ),
              const SizedBox(height: kSpacingXS),
              _buildCompactStorageLine(
                context,
                label: 'Sealed',
                icons: sealedIcons,
                location: sealedLocation,
                createdAt: sealedCreatedAt,
                expiry: sealedExpiry,
                trailing: RichText(
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: _mdvRemainingVialsSpan(context),
                ),
              ),
            ],
          )
        : _buildCompactStorageLine(
            context,
            label: 'Storage',
            icons: combinedIcons,
            location: location,
            createdAt: m.createdAt,
            expiry: m.expiry,
            trailing: RichText(
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: _MedicationStockStatusText.textSpanFor(
                context,
                m,
                baseStyle: baseRemainingStyle,
              ),
            ),
          );

    // Intentionally borderless/compact: keep storage details inline without an inset card.
    return body;
  }

  Widget _buildLeading(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeScheduleCount = _activeScheduleCount();
    final pausedScheduleCount = _pausedScheduleCount();
    final totalScheduleCount = _totalScheduleCount();
    final strengthQuantityLabel =
        '${fmt2(m.strengthValue)} ${MedicationDisplayHelpers.unitLabel(m.strengthUnit)}';

    final hasActiveSchedules = activeScheduleCount > 0;
    final hasPausedSchedules = !hasActiveSchedules && pausedScheduleCount > 0;
    final scheduleIconColor = hasActiveSchedules
        ? cs.primary
        : hasPausedSchedules
        ? cs.onSurfaceVariant.withValues(alpha: kOpacityMedium)
        : cs.onSurfaceVariant.withValues(alpha: kOpacityMediumLow);
    final scheduleTextColor = hasActiveSchedules
        ? cs.primary
        : cs.onSurfaceVariant.withValues(alpha: kOpacityMediumLow);

    final scheduleLabel = hasActiveSchedules
        ? (activeScheduleCount == 1
              ? '1 active schedule'
              : '$activeScheduleCount active schedules')
        : hasPausedSchedules
        ? (pausedScheduleCount == 1
              ? '1 paused schedule'
              : '$pausedScheduleCount paused schedules')
        : (totalScheduleCount == 0 ? 'No schedules' : '0 active schedules');

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
            style: smallHelperTextStyle(context),
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
              color: scheduleIconColor,
            ),
            const SizedBox(width: kSpacingXS),
            Expanded(
              child: Text(
                scheduleLabel,
                style: smallHelperTextStyle(
                  context,
                  color: scheduleTextColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrailing(BuildContext context) {
    final stockInfo = MedicationDisplayHelpers.calculateStock(m);
    final pctRounded = stockInfo.percentage.clamp(0, 100).round();
    final isMdv = m.form == MedicationForm.multiDoseVial;
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
            size: kStockDonutGaugeSizeCompact,
            strokeWidth: kStockDonutGaugeStrokeWidth,
            color: stockColor,
            textColor: stockColor,
          ),
        ),
        if (!isMdv) const SizedBox(height: kSpacingXS),
      ],
    );
  }

  Widget? _buildFooter(BuildContext context) {
    final isMdv = m.form == MedicationForm.multiDoseVial;

    final storageSection = _buildStorageInsetSection(
      context,
      activeIcons: isMdv
          ? _activeVialStorageConditionIcons()
          : const <IconData>[],
      sealedIcons: isMdv
          ? _sealedVialsStorageConditionIcons()
          : const <IconData>[],
      combinedIcons: _combinedStorageConditionIcons(),
    );

    return storageSection;
  }
}
