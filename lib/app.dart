import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/add_movement_screen.dart';
import 'screens/shell_screen.dart';
import 'services/deep_link.dart';
import 'theme/app_theme.dart';

class ControlGastosApp extends StatefulWidget {
  const ControlGastosApp({super.key, this.initialVoiceText});

  final String? initialVoiceText;

  @override
  State<ControlGastosApp> createState() => _ControlGastosAppState();
}

class _ControlGastosAppState extends State<ControlGastosApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    // El link inicial (app cerrada) ya se resolvió en main(); aquí solo
    // atendemos links que llegan con la app ya abierta.
    _linkSub = AppLinks().uriLinkStream.listen(_handleIncomingLink);
  }

  void _handleIncomingLink(Uri uri) {
    final texto = voiceTextFromDeepLink(uri);
    if (texto == null) return;
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Confirmar movimiento')),
          body: AddMovementScreen(initialText: texto),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Control Gastos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX'), Locale('es', 'ES')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: ShellScreen(initialVoiceText: widget.initialVoiceText),
    );
  }
}
