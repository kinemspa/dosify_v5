import 'package:flutter/material.dart';

import 'package:dosifi_v5/src/core/design_system.dart';

class SectionHeaderRow extends StatelessWidget {
  const SectionHeaderRow({
    super.key,
    required this.title,
    this.trailing,
    this.padding,
  });

  final String title;
  final Widget? trailing;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final resolvedPadding = padding ?? kSectionHeaderRowPadding;

    return Padding(
      padding: resolvedPadding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cardTitleStyle(context),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: kSpacingS),
            trailing!,
          ],
        ],
      ),
    );
  }
}
