// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';

class Field36 extends StatelessWidget {
  const Field36({required this.child, super.key, this.width});
  final Widget child;
  final double? width;
  @override
  Widget build(BuildContext context) {
    return SizedBox(height: kFieldHeight, width: width, child: child);
  }
}
