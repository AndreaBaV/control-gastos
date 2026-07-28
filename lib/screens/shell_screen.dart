import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_controller.dart';
import '../util/money_format.dart';
import 'accounts_screen.dart';
import 'add_movement_screen.dart';
import 'budgets_screen.dart';
import 'home_screen.dart';
import 'insights_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key, this.initialVoiceText});

  /// Si viene de un deep link (Atajo de Siri), abre directo la pestaña de voz
  /// con el texto ya dictado, listo para confirmar.
  final String? initialVoiceText;

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  late int _index = widget.initialVoiceText != null ? 1 : 0;

  @override
  Widget build(BuildContext context) {
    final Widget page = switch (_index) {
      0 => const HomeScreen(),
      1 => AddMovementScreen(initialText: widget.initialVoiceText),
      2 => const AccountsScreen(),
      3 => const BudgetsScreen(),
      _ => const InsightsScreen(),
    };
    return Scaffold(
      body: page,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_none_rounded),
            selectedIcon: Icon(Icons.mic_rounded),
            label: 'Voz',
          ),
          NavigationDestination(
            icon: Icon(Icons.credit_card_outlined),
            selectedIcon: Icon(Icons.credit_card),
            label: 'Cuentas',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Presupuesto',
          ),
          NavigationDestination(
            icon: Icon(Icons.spa_outlined),
            selectedIcon: Icon(Icons.spa_rounded),
            label: 'Ahorro',
          ),
        ],
      ),
    );
  }
}

class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    return Row(
      children: [
        IconButton(
          onPressed: () => c.shiftMonth(-1),
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Mes anterior',
        ),
        Expanded(
          child: Text(
            formatYearMonthLabel(c.yearMonth),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        IconButton(
          onPressed: () => c.shiftMonth(1),
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Mes siguiente',
        ),
      ],
    );
  }
}
