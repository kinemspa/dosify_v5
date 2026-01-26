import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:dosifi_v5/src/widgets/unified_form.dart';
import 'package:flutter/material.dart';

class MissingRequiredFieldsCard extends StatelessWidget {
  const MissingRequiredFieldsCard({
    required this.fields,
    super.key,
    this.title = 'Required info missing',
    this.message = 'Fill the required fields before saving.',
  });

  final List<String> fields;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    if (fields.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return SectionFormCard(
      neutral: true,
      title: title,
      titleStyle: reviewCardTitleStyle(context),
      children: [
        Text(message, style: mutedTextStyle(context)),
        const SizedBox(height: kSpacingS),
        for (final field in fields)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: kSpacingXS),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: kSpacingXXS),
                  child: Icon(
                    Icons.error_outline,
                    size: kIconSizeSmall,
                    color: cs.error,
                  ),
                ),
                const SizedBox(width: kSpacingS),
                Expanded(
                  child: Text(
                    field,
                    style: errorTextStyle(context),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
