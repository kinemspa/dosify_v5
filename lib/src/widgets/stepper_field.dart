// Flutter imports:
import 'package:flutter/material.dart';

class StepperField extends StatefulWidget {
  const StepperField({
    required this.controller, super.key,
    this.label,
    this.hint,
    this.onChanged,
    this.enabled = true,
    this.step = 1,
    this.min,
    this.max,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final bool enabled;
  final num step;
  final num? min;
  final num? max;
  final ValueChanged<String>? onChanged;

  @override
  State<StepperField> createState() => _StepperFieldState();
}

class _StepperFieldState extends State<StepperField> {
  num _parse() => num.tryParse(widget.controller.text) ?? 0;

  void _set(num v) {
    if (widget.min != null && v < widget.min!) v = widget.min!;
    if (widget.max != null && v > widget.max!) v = widget.max!;
    widget.controller.text = v.toStringAsFixed(0);
    widget.onChanged?.call(widget.controller.text);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: widget.enabled ? () => _set(_parse() - widget.step) : null,
          icon: const Icon(Icons.remove),
          visualDensity: VisualDensity.compact,
        ),
        Expanded(
          child: TextFormField(
            controller: widget.controller,
            enabled: widget.enabled,
            keyboardType: const TextInputType.numberWithOptions(),
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            onChanged: widget.onChanged,
          ),
        ),
        IconButton(
          onPressed: widget.enabled ? () => _set(_parse() + widget.step) : null,
          icon: const Icon(Icons.add),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
