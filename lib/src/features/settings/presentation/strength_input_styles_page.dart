// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/core/prefs/user_prefs.dart';
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';
import 'package:dosifi_v5/src/widgets/app_header.dart';

class StrengthInputStylesPage extends StatelessWidget {
  const StrengthInputStylesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Strength Input Styles', forceBackButton: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.separated(
          itemCount: StrengthInputStyle.values.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _StrengthInputCard(style: StrengthInputStyle.values[i]),
        ),
      ),
    );
  }
}

enum StrengthInputStyle {
  chipRowCompact,
  chipRowStrong,
  chipRailLeft,
  chipRailRight,
  chipDeltaGrid,
  chipQuickPicks,
  chipPillsGroup,
  chipTwoRow,
  chipMinimalInline,
  chipCardTopRightDropdown,
}

extension StrengthInputStyleX on StrengthInputStyle {
  String get displayName => switch (this) {
    StrengthInputStyle.chipRowCompact => 'Chip row (compact)',
    StrengthInputStyle.chipRowStrong => 'Chip row (strong)',
    StrengthInputStyle.chipRailLeft => 'Left rail (vertical)',
    StrengthInputStyle.chipRailRight => 'Right rail (vertical)',
    StrengthInputStyle.chipDeltaGrid => 'Delta grid (−1/＋1/−5/＋5)',
    StrengthInputStyle.chipQuickPicks => 'Quick picks + stepper',
    StrengthInputStyle.chipPillsGroup => 'Pill group',
    StrengthInputStyle.chipTwoRow => 'Two-row controls',
    StrengthInputStyle.chipMinimalInline => 'Minimal inline',
    StrengthInputStyle.chipCardTopRightDropdown => 'Card with top-right dropdown',
  };
}

class _StrengthInputCard extends StatefulWidget {
  const _StrengthInputCard({required this.style});
  final StrengthInputStyle style;

  @override
  State<_StrengthInputCard> createState() => _StrengthInputCardState();
}

class _StrengthInputCardState extends State<_StrengthInputCard> {
  final _ctrl = TextEditingController(text: '250');
  int _value = 250;
  Unit _unit = Unit.mg;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // load selected from SharedPreferences to show a check (best-effort preview; not blocking)
    // We keep it simple: compare index by enum order, updated on tap from parent.
    final theme = Theme.of(context);

    // default content (used by chipRowCompact)
    Widget content = Row(
      children: [
        // Integer input with +/- steppers
        Expanded(
          child: TextFormField(
            controller: _ctrl,
            keyboardType: const TextInputType.numberWithOptions(),
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixIcon: IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () => setState(() {
                  _value = (int.tryParse(_ctrl.text) ?? _value) - 1;
                  if (_value < 0) _value = 0;
                  _ctrl.text = _value.toString();
                }),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => setState(() {
                  _value = (int.tryParse(_ctrl.text) ?? _value) + 1;
                  _ctrl.text = _value.toString();
                }),
              ),
            ),
            onChanged: (v) => setState(() => _value = int.tryParse(v) ?? _value),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 140,
          child: DropdownButtonFormField<Unit>(
            initialValue: _unit,
            items: const [
              DropdownMenuItem(value: Unit.mcg, child: Text('mcg')),
              DropdownMenuItem(value: Unit.mg, child: Text('mg')),
              DropdownMenuItem(value: Unit.g, child: Text('g')),
            ],
            onChanged: (v) => setState(() => _unit = v ?? _unit),
            decoration: const InputDecoration(labelText: 'Unit'),
          ),
        ),
      ],
    );

    BoxDecoration? deco;
    const padding = EdgeInsets.all(12);

    switch (widget.style) {
      case StrengthInputStyle.chipRowCompact:
        deco = BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        );

      case StrengthInputStyle.chipRailLeft:
        deco = BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        );
        content = Row(
          children: [
            // Vertical stepper (left)
            Container(
              width: 56,
              height: 84,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_up),
                    onPressed: () => setState(() {
                      _value += 1;
                      _ctrl.text = _value.toString();
                    }),
                    visualDensity: VisualDensity.compact,
                  ),
                  Text('$_value', style: Theme.of(context).textTheme.titleMedium),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down),
                    onPressed: () => setState(() {
                      _value = (_value - 1).clamp(0, 1000000);
                      _ctrl.text = _value.toString();
                    }),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<Unit>(
                initialValue: _unit,
                items: const [
                  DropdownMenuItem(value: Unit.mcg, child: Text('mcg')),
                  DropdownMenuItem(value: Unit.mg, child: Text('mg')),
                  DropdownMenuItem(value: Unit.g, child: Text('g')),
                ],
                onChanged: (v) => setState(() => _unit = v ?? _unit),
                decoration: const InputDecoration(labelText: 'Unit'),
              ),
            ),
          ],
        );

      case StrengthInputStyle.chipRailRight:
        deco = BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        );
        content = Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<Unit>(
                initialValue: _unit,
                items: const [
                  DropdownMenuItem(value: Unit.mcg, child: Text('mcg')),
                  DropdownMenuItem(value: Unit.mg, child: Text('mg')),
                  DropdownMenuItem(value: Unit.g, child: Text('g')),
                ],
                onChanged: (v) => setState(() => _unit = v ?? _unit),
                decoration: const InputDecoration(labelText: 'Unit'),
              ),
            ),
            const SizedBox(width: 12),
            // Vertical stepper (right)
            Container(
              width: 56,
              height: 84,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_up),
                    onPressed: () => setState(() {
                      _value += 1;
                      _ctrl.text = _value.toString();
                    }),
                    visualDensity: VisualDensity.compact,
                  ),
                  Text('$_value', style: Theme.of(context).textTheme.titleMedium),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down),
                    onPressed: () => setState(() {
                      _value = (_value - 1).clamp(0, 1000000);
                      _ctrl.text = _value.toString();
                    }),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ],
        );

      case StrengthInputStyle.chipDeltaGrid:
        deco = BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        );
        Widget deltaChip(String label, VoidCallback onPressed) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: ActionChip(label: Text(label), onPressed: onPressed),
        );
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              children: [
                deltaChip(
                  '−1',
                  () => setState(() {
                    _value = (_value - 1).clamp(0, 1000000);
                    _ctrl.text = _value.toString();
                  }),
                ),
                deltaChip(
                  '+1',
                  () => setState(() {
                    _value += 1;
                    _ctrl.text = _value.toString();
                  }),
                ),
                deltaChip(
                  '−5',
                  () => setState(() {
                    _value = (_value - 5).clamp(0, 1000000);
                    _ctrl.text = _value.toString();
                  }),
                ),
                deltaChip(
                  '+5',
                  () => setState(() {
                    _value += 5;
                    _ctrl.text = _value.toString();
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    controller: _ctrl,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(),
                    onChanged: (v) => setState(() => _value = int.tryParse(v) ?? _value),
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<Unit>(
                    initialValue: _unit,
                    items: const [
                      DropdownMenuItem(value: Unit.mcg, child: Text('mcg')),
                      DropdownMenuItem(value: Unit.mg, child: Text('mg')),
                      DropdownMenuItem(value: Unit.g, child: Text('g')),
                    ],
                    onChanged: (v) => setState(() => _unit = v ?? _unit),
                    decoration: const InputDecoration(labelText: 'Unit'),
                  ),
                ),
              ],
            ),
          ],
        );

      case StrengthInputStyle.chipRowStrong:
        deco = BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        );
        content = Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _ctrl,
                keyboardType: const TextInputType.numberWithOptions(),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => setState(() {
                          _value = (_value - 1).clamp(0, 1000000);
                          _ctrl.text = _value.toString();
                        }),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() {
                          _value += 1;
                          _ctrl.text = _value.toString();
                        }),
                      ),
                    ],
                  ),
                ),
                onChanged: (v) => setState(() => _value = int.tryParse(v) ?? _value),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 140,
              child: DropdownButtonFormField<Unit>(
                initialValue: _unit,
                items: const [
                  DropdownMenuItem(value: Unit.mcg, child: Text('mcg')),
                  DropdownMenuItem(value: Unit.mg, child: Text('mg')),
                  DropdownMenuItem(value: Unit.g, child: Text('g')),
                ],
                onChanged: (v) => setState(() => _unit = v ?? _unit),
                decoration: const InputDecoration(labelText: 'Unit'),
              ),
            ),
          ],
        );

      case StrengthInputStyle.chipQuickPicks:
        deco = BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        );
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: () => setState(() {
                    _value = (_value - 1).clamp(0, 1000000);
                    _ctrl.text = _value.toString();
                  }),
                  icon: const Icon(Icons.remove),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: TextFormField(
                    controller: _ctrl,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(),
                    decoration: const InputDecoration(labelText: 'Amount'),
                    onChanged: (v) => setState(() => _value = int.tryParse(v) ?? _value),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () => setState(() {
                    _value += 1;
                    _ctrl.text = _value.toString();
                  }),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<Unit>(
                initialValue: _unit,
                items: const [
                  DropdownMenuItem(value: Unit.mcg, child: Text('mcg')),
                  DropdownMenuItem(value: Unit.mg, child: Text('mg')),
                  DropdownMenuItem(value: Unit.g, child: Text('g')),
                ],
                onChanged: (v) => setState(() => _unit = v ?? _unit),
                decoration: const InputDecoration(labelText: 'Unit'),
              ),
            ),
          ],
        );

      case StrengthInputStyle.chipTwoRow:
        deco = BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        );
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _value.toDouble(),
                    max: 1000,
                    divisions: 1000,
                    label: '$_value',
                    onChanged: (v) => setState(() {
                      _value = v.round();
                      _ctrl.text = _value.toString();
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Text('$_value'),
              ],
            ),
            DropdownButtonFormField<Unit>(
              initialValue: _unit,
              items: const [
                DropdownMenuItem(value: Unit.mcg, child: Text('mcg')),
                DropdownMenuItem(value: Unit.mg, child: Text('mg')),
                DropdownMenuItem(value: Unit.g, child: Text('g')),
              ],
              onChanged: (v) => setState(() => _unit = v ?? _unit),
              decoration: const InputDecoration(labelText: 'Unit'),
            ),
          ],
        );

      case StrengthInputStyle.chipCardTopRightDropdown:
        deco = BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        );
        content = Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => setState(() {
                      _value = (_value - 1).clamp(0, 1000000);
                      _ctrl.text = _value.toString();
                    }),
                    icon: const Icon(Icons.remove),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    child: TextFormField(
                      controller: _ctrl,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(),
                      onChanged: (v) => setState(() => _value = int.tryParse(v) ?? _value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () => setState(() {
                      _value += 1;
                      _ctrl.text = _value.toString();
                    }),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: SizedBox(
                width: 140,
                child: DropdownButtonFormField<Unit>(
                  initialValue: _unit,
                  items: const [
                    DropdownMenuItem(value: Unit.mcg, child: Text('mcg')),
                    DropdownMenuItem(value: Unit.mg, child: Text('mg')),
                    DropdownMenuItem(value: Unit.g, child: Text('g')),
                  ],
                  onChanged: (v) => setState(() => _unit = v ?? _unit),
                  decoration: const InputDecoration(labelText: 'Unit'),
                ),
              ),
            ),
          ],
        );

      case StrengthInputStyle.chipPillsGroup:
        // Use a subtle primary-tinted background with no outline
        deco = BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(12));
        // Local helper to get primary-colour overlay animation on tap with visible ripple
        Widget pillBtn(String label, VoidCallback onTap) {
          final theme = Theme.of(context);
          return Material(
            color: Colors.transparent,
            shape: const StadiumBorder(),
            child: Ink(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: InkWell(
                customBorder: const StadiumBorder(),
                overlayColor: WidgetStatePropertyAll(theme.colorScheme.primary.withOpacity(0.12)),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(label, style: theme.textTheme.labelLarge),
                ),
              ),
            ),
          );
        }
        content = Row(
          children: [
            pillBtn(
              '−',
              () => setState(() {
                _value = (_value - 1).clamp(0, 1000000);
                _ctrl.text = _value.toString();
              }),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 96,
              child: TextFormField(
                controller: _ctrl,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(),
                onChanged: (v) => setState(() => _value = int.tryParse(v) ?? _value),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
              ),
            ),
            const SizedBox(width: 6),
            pillBtn(
              '+',
              () => setState(() {
                _value += 1;
                _ctrl.text = _value.toString();
              }),
            ),
            const SizedBox(width: 12),
            // Use Expanded to avoid RenderFlex overflow and center-align text
            Expanded(
              child: DropdownButtonFormField<Unit>(
                initialValue: _unit,
                isExpanded: true,
                alignment: AlignmentDirectional.center,
                items: const [
                  DropdownMenuItem(
                    value: Unit.mcg,
                    alignment: AlignmentDirectional.center,
                    child: Center(child: Text('mcg', textAlign: TextAlign.center)),
                  ),
                  DropdownMenuItem(
                    value: Unit.mg,
                    alignment: AlignmentDirectional.center,
                    child: Center(child: Text('mg', textAlign: TextAlign.center)),
                  ),
                  DropdownMenuItem(
                    value: Unit.g,
                    alignment: AlignmentDirectional.center,
                    child: Center(child: Text('g', textAlign: TextAlign.center)),
                  ),
                ],
                onChanged: (v) => setState(() => _unit = v ?? _unit),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  labelText: 'Unit',
                ),
                menuMaxHeight: 320,
              ),
            ),
          ],
        );

      case StrengthInputStyle.chipMinimalInline:
        deco = BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor),
        );
        content = Row(
          children: [
            IconButton(
              onPressed: () => setState(() {
                _value = (_value - 1).clamp(0, 1000000);
                _ctrl.text = _value.toString();
              }),
              icon: const Icon(Icons.remove),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 80,
              child: TextFormField(
                controller: _ctrl,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(),
                onChanged: (v) => setState(() => _value = int.tryParse(v) ?? _value),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: () => setState(() {
                _value += 1;
                _ctrl.text = _value.toString();
              }),
              icon: const Icon(Icons.add),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<Unit>(
                initialValue: _unit,
                items: const [
                  DropdownMenuItem(value: Unit.mcg, child: Text('mcg')),
                  DropdownMenuItem(value: Unit.mg, child: Text('mg')),
                  DropdownMenuItem(value: Unit.g, child: Text('g')),
                ],
                onChanged: (v) => setState(() => _unit = v ?? _unit),
                decoration: const InputDecoration(labelText: 'Unit'),
              ),
            ),
          ],
        );
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.style.displayName,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                FilledButton.tonal(
                  onPressed: () async {
                    final idx = StrengthInputStyle.values.indexOf(widget.style);
                    await UserPrefs.setStrengthInputStyle(idx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Selected: ${widget.style.displayName}')),
                      );
                    }
                  },
                  child: const Text('Select'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(decoration: deco, padding: padding, child: content),
          ],
        ),
      ),
    );
  }
}
