// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:dosifi_v5/src/app/nav_items.dart';

final bottomNavIdsProvider = StateNotifierProvider<BottomNavIdsController, List<String>>((ref) {
  return BottomNavIdsController()..load();
});

class BottomNavIdsController extends StateNotifier<List<String>> {
  BottomNavIdsController() : super(const []);
  static const _prefsKey = 'bottom_nav_ids_v1';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_prefsKey);
    if (ids == null || ids.length != 4) {
      // Default selection
      state = const ['home', 'medications', 'schedules', 'calendar'];
      await prefs.setStringList(_prefsKey, state);
    } else {
      state = ids;
    }
  }

  Future<void> save(List<String> ids) async {
    state = List<String>.from(ids);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, state);
  }
}

class BottomNavSettingsPage extends ConsumerStatefulWidget {
  const BottomNavSettingsPage({super.key});

  @override
  ConsumerState<BottomNavSettingsPage> createState() => _BottomNavSettingsPageState();
}

class _BottomNavSettingsPageState extends ConsumerState<BottomNavSettingsPage> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = const [];
    // Delay read a tick to ensure provider loaded
    Future.microtask(() {
      setState(() => _selected = List.of(ref.read(bottomNavIdsProvider)));
    });
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else if (_selected.length < 4) {
        _selected.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _selected.length == 4;
    return Scaffold(
      appBar: AppBar(title: const Text('Bottom Nav Tabs (Pick 4)')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: ReorderableListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _selected.removeAt(oldIndex);
                  _selected.insert(newIndex, item);
                });
              },
              children: [
                for (final id in _selected)
                  ListTile(
                    key: ValueKey('sel_$id'),
                    leading: Icon(findNavItem(id)!.icon),
                    title: Text(findNavItem(id)!.label),
                    trailing: const Icon(Icons.drag_handle),
                  ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const Text('Available', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...allNavItems.map((e) {
                  final isSelected = _selected.contains(e.id);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (_) => _toggle(e.id),
                    title: Text(e.label),
                    secondary: Icon(e.icon),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton(
          onPressed: canSave
              ? () async {
                  await ref.read(bottomNavIdsProvider.notifier).save(_selected);
                  if (context.mounted) Navigator.of(context).pop();
                }
              : null,
          child: const Text('Save (exactly 4 tabs)'),
        ),
      ),
    );
  }
}
