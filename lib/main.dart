import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'services/deep_link.dart';
import 'state/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.database;
  final controller = AppController(AppDatabase.instance);
  await controller.init();

  String? initialVoiceText;
  try {
    final initialUri = await AppLinks().getInitialLink();
    initialVoiceText = voiceTextFromDeepLink(initialUri);
  } catch (_) {
    // Sin soporte de deep links en esta plataforma (ej. escritorio): se ignora.
  }

  runApp(
    ChangeNotifierProvider.value(
      value: controller,
      child: ControlGastosApp(initialVoiceText: initialVoiceText),
    ),
  );
}
