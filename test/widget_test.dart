import 'package:control_gastos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tema y MaterialApp arrancan', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Center(child: Text('control_gastos')),
        ),
      ),
    );
    expect(find.text('control_gastos'), findsOneWidget);
  });
}
