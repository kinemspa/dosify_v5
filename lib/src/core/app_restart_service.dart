import 'dart:async';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppRestartService {
  const AppRestartService._();

  static Future<void> restart() async {
    if (!Platform.isAndroid) {
      await SystemNavigator.pop();
      return;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final packageName = packageInfo.packageName;

    final intent = AndroidIntent(
      action: 'android.intent.action.MAIN',
      category: 'android.intent.category.LAUNCHER',
      package: packageName,
      componentName: '$packageName.MainActivity',
      flags: const <int>[268435456, 32768, 67108864],
    );

    await intent.launch();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await SystemNavigator.pop();
  }
}
