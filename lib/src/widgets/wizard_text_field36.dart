import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/widgets/field36.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WizardTextField36 extends StatelessWidget {
  const WizardTextField36({
    required this.controller,
    required this.hint,
    super.key,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = kTextCapitalizationDefault,
    this.textAlign = TextAlign.left,
    this.textInputAction = TextInputAction.next,
    this.minLines,
    this.maxLines = 1,
    this.useCompactDecoration = false,
    this.onChanged,
    this.onSubmitted,
    this.enabled,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final TextAlign textAlign;
  final TextInputAction textInputAction;
  final int? minLines;
  final int maxLines;
  final bool useCompactDecoration;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool? enabled;

  @override
  Widget build(BuildContext context) {
    final decoration = useCompactDecoration
        ? buildCompactFieldDecoration(context: context, hint: hint)
        : buildFieldDecoration(context, hint: hint);

    final textField = TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      textAlign: textAlign,
      textInputAction: textInputAction,
      minLines: minLines,
      maxLines: maxLines,
      style: bodyTextStyle(context),
      decoration: decoration,
      onChanged: onChanged,
      onSubmitted: (value) {
        onSubmitted?.call(value);
        if (textInputAction == TextInputAction.next) {
          final didMove = FocusScope.of(context).nextFocus();
          if (!didMove) {
            FocusScope.of(context).unfocus();
          }
        } else if (textInputAction == TextInputAction.done) {
          FocusScope.of(context).unfocus();
        }
      },
    );

    if (maxLines > 1 || (minLines != null && minLines! > 1)) {
      return textField;
    }

    return Field36(child: textField);
  }
}
