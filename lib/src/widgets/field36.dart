import 'package:flutter/material.dart';
import 'package:dosifi_v5/src/features/medications/presentation/ui_consts.dart';

class Field36 extends StatelessWidget {
  const Field36({super.key, required this.child, this.width});
  final Widget child;
  final double? width;
  @override
  Widget build(BuildContext context) {
    return SizedBox(height: kFieldHeight, width: width, child: child);
  }
}
