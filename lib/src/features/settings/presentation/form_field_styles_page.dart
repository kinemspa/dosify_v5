// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/prefs/user_prefs.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';
import 'package:dosifi_v5/src/widgets/form_field_styler.dart';

class FormFieldStylesPage extends StatefulWidget {
  const FormFieldStylesPage({super.key});

  @override
  State<FormFieldStylesPage> createState() => _FormFieldStylesPageState();
}

class _FormFieldStylesPageState extends State<FormFieldStylesPage> {
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final idx = await UserPrefs.getFormFieldStyle();
    if (mounted) setState(() => _selected = idx);
  }

  Future<void> _select(int i) async {
    await UserPrefs.setFormFieldStyle(i);
    if (!mounted) return;
    setState(() => _selected = i);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected form field style #${i + 1}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(
        title: 'Form Field Styles',
        forceBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.9,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: 10,
          itemBuilder: (context, i) => _StyleCard(
            index: i,
            selected: _selected == i,
            onSelect: () => _select(i),
          ),
        ),
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  const _StyleCard({
    required this.index,
    required this.selected,
    required this.onSelect,
  });
  final int index;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final deco = FormFieldStyler.sectionDecoration(context, index);
    return Card(
      elevation: selected ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Style #${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (selected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: deco,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: FormFieldStyler.decoration(
                          context: context,
                          styleIndex: index,
                          label: 'Name',
                          hint: 'eg. Panadol',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: FormFieldStyler.decoration(
                          context: context,
                          styleIndex: index,
                          label: 'Manufacturer',
                          hint: 'eg. GSK',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: onSelect,
                  child: const Text('Select'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
