import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/app/app.dart';
import 'src/core/hive/hive_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveBootstrap.init();
  runApp(const ProviderScope(child: DosifiApp()));
}
