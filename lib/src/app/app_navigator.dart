import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

void goToMedications(BuildContext fallbackContext) {
	final rootContext = rootNavigatorKey.currentContext;
	if (rootContext != null) {
		GoRouter.of(rootContext).go('/medications');
		return;
	}

	GoRouter.of(fallbackContext).go('/medications');
}
