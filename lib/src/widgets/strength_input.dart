// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/features/medications/domain/enums.dart';

/// Ten chip-based integer input styles with a spinner-style unit dropdown.
/// The value is always an integer with +/- controls; units are chosen via DropdownButtonFormField.
class StrengthInput extends StatefulWidget {
  const StrengthInput({
    required this.controller,
    required this.unit,
    required this.onUnitChanged,
    required this.styleIndex,
    super.key,
    this.labelAmount = 'Amount *',
    this.labelUnit = 'Unit *',
    this.min = 0,
    this.step = 1,
    this.padding,
  });

  final TextEditingController controller;
  final Unit unit;
  final ValueChanged<Unit> onUnitChanged;
  final int styleIndex; // 0..9
  final String labelAmount;
  final String labelUnit;
  final int min;
  final int step;
  final EdgeInsets? padding;

  @override
  State<StrengthInput> createState() => _StrengthInputState();
}

class _StrengthInputState extends State<StrengthInput> {
  late int _value;
  late Unit _unit;

  @override
  void initState() {
    super.initState();
    _value = int.tryParse(widget.controller.text) ?? 0;
    _unit = widget.unit;
  }

  void _applyValue(int v) {
    if (v < widget.min) v = widget.min;
    setState(() {
      _value = v;
      widget.controller.text = _value.toString();
    });
  }

  void _inc([int? by]) => _applyValue(_value + (by ?? widget.step));
  void _dec([int? by]) => _applyValue(_value - (by ?? widget.step));

  Widget _unitDropdown({EdgeInsets? padding}) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: SizedBox(
        height: 36,
        child: DropdownButtonFormField<Unit>(
          initialValue: _unit,
          alignment: AlignmentDirectional.center,
          menuMaxHeight: 320,
          selectedItemBuilder: (ctx) => const [Unit.mcg, Unit.mg, Unit.g]
              .map(
                (u) => Center(
                  child: Text(
                    u == Unit.mcg ? 'mcg' : (u == Unit.mg ? 'mg' : 'g'),
                  ),
                ),
              )
              .toList(),
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
          onChanged: (v) {
            final nv = v ?? _unit;
            setState(() => _unit = nv);
            widget.onUnitChanged(nv);
          },
          icon: Icon(
            Icons.arrow_drop_down,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            labelText: widget.labelUnit,
            isDense: false,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            constraints: const BoxConstraints(minHeight: 36),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
          ),
        ),
      ),
    );
  }

  Widget _amountField({TextAlign align = TextAlign.center, double? width}) {
    final theme = Theme.of(context);
    final tf = TextFormField(
      controller: widget.controller,
      textAlign: align,
      keyboardType: const TextInputType.numberWithOptions(),
      decoration: InputDecoration(
        labelText: widget.labelAmount,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        filled: true,
      ),
      onChanged: (v) => _applyValue(int.tryParse(v) ?? _value),
    );
    return width != null ? SizedBox(width: width, child: tf) : tf;
  }

  // Variant builders
  Widget _variant1() {
    // Compact row: small −/＋ chips, value field, unit dropdown
    return Row(
      children: [
        IconButton.filledTonal(onPressed: _dec, icon: const Icon(Icons.remove)),
        const SizedBox(width: 8),
        _amountField(width: 100),
        const SizedBox(width: 8),
        IconButton.filledTonal(onPressed: _inc, icon: const Icon(Icons.add)),
        const SizedBox(width: 12),
        Expanded(child: _unitDropdown()),
      ],
    );
  }

  Widget _variant2() {
    // Elevated card: big centered value, floating +/-
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '$_value',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Positioned(
              left: 8,
              child: IconButton.filledTonal(
                onPressed: _dec,
                icon: const Icon(Icons.remove),
              ),
            ),
            Positioned(
              right: 8,
              child: IconButton.filledTonal(
                onPressed: _inc,
                icon: const Icon(Icons.add),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _unitDropdown(),
      ],
    );
  }

  Widget _variant3() {
    // Left rail vertical +/- and value inline, dropdown right
    return Row(
      children: [
        Column(
          children: [
            IconButton.filledTonal(
              onPressed: _inc,
              icon: const Icon(Icons.keyboard_arrow_up),
            ),
            IconButton.filledTonal(
              onPressed: _dec,
              icon: const Icon(Icons.keyboard_arrow_down),
            ),
          ],
        ),
        const SizedBox(width: 8),
        _amountField(width: 90),
        const SizedBox(width: 12),
        Expanded(child: _unitDropdown()),
      ],
    );
  }

  Widget _variant4() {
    // Right rail vertical +/-
    return Row(
      children: [
        _amountField(width: 90),
        const SizedBox(width: 8),
        Column(
          children: [
            IconButton.filled(onPressed: _inc, icon: const Icon(Icons.add)),
            const SizedBox(height: 4),
            IconButton.filled(onPressed: _dec, icon: const Icon(Icons.remove)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(child: _unitDropdown()),
      ],
    );
  }

  Widget _variant5() {
    // Delta grid: −1/＋1/−5/＋5
    Widget chip(String label, void Function() onTap) => Padding(
      padding: const EdgeInsets.all(2),
      child: ActionChip(label: Text(label), onPressed: onTap),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          children: [
            chip('−1', () => _dec(1)),
            chip('+1', () => _inc(1)),
            chip('−5', () => _dec(5)),
            chip('+5', () => _inc(5)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _amountField(width: 100),
            const SizedBox(width: 12),
            Expanded(child: _unitDropdown()),
          ],
        ),
      ],
    );
  }

  Widget _variant6() {
    // Quick picks + stepper
    Widget quick(int v) => Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text('$v'),
        selected: _value == v,
        onSelected: (_) => _applyValue(v),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [quick(0), quick(5), quick(10), quick(20)]),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: _dec,
              icon: const Icon(Icons.remove),
            ),
            const SizedBox(width: 8),
            _amountField(width: 100),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: _inc,
              icon: const Icon(Icons.add),
            ),
            const SizedBox(width: 12),
            Expanded(child: _unitDropdown()),
          ],
        ),
      ],
    );
  }

  Widget _pillBtn(String label, VoidCallback onTap) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(8);
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: Ink(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: radius,
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: radius),
          overlayColor: WidgetStatePropertyAll(
            theme.colorScheme.primary.withValues(alpha: 0.12),
          ),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(label, style: theme.textTheme.labelLarge),
          ),
        ),
      ),
    );
  }

  Widget _variant7() {
    // Pill group (outlined amount field + compact +/- chips)
    return Row(
      children: [
        _pillBtn('−', _dec),
        const SizedBox(width: 6),
        SizedBox(width: 96, child: _amountField()),
        const SizedBox(width: 6),
        _pillBtn('+', _inc),
        const SizedBox(width: 12),
        Expanded(child: _unitDropdown()),
      ],
    );
  }

  Widget _variant8() {
    // Two-row layout
    return Column(
      children: [
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: _dec,
              icon: const Icon(Icons.remove),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: _inc,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _amountField()),
            const SizedBox(width: 12),
            Expanded(child: _unitDropdown()),
          ],
        ),
      ],
    );
  }

  Widget _variant9() {
    // Minimal inline
    return Row(
      children: [
        IconButton(onPressed: _dec, icon: const Icon(Icons.remove)),
        _amountField(width: 80),
        IconButton(onPressed: _inc, icon: const Icon(Icons.add)),
        const SizedBox(width: 12),
        Expanded(child: _unitDropdown()),
      ],
    );
  }

  Widget _variant10() {
    // Card with top-right unit dropdown
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              IconButton.filled(
                onPressed: _dec,
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: 8),
              _amountField(width: 100),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _inc, icon: const Icon(Icons.add)),
            ],
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: SizedBox(width: 120, child: _unitDropdown()),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: widget.padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: switch (widget.styleIndex) {
        0 => _variant1(),
        1 => _variant2(),
        2 => _variant3(),
        3 => _variant4(),
        4 => _variant5(),
        5 => _variant6(),
        6 => _variant7(),
        7 => _variant8(),
        8 => _variant9(),
        _ => _variant10(),
      },
    );
    return box;
  }
}
