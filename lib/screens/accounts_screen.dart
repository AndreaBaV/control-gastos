import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/account_model.dart';
import '../state/app_controller.dart';
import '../util/money_format.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final theme = Theme.of(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openAccountSheet(context),
          icon: const Icon(Icons.add),
          label: const Text('Nueva cuenta'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          children: [
            Text(
              'Tus cuentas',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tarjetas y cuentas donde registras tus movimientos. Saldo para débito/efectivo, deuda para crédito.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 20),
            if (c.accounts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'Sin cuentas todavía.\nToca “Nueva cuenta” para dar de alta tu primera tarjeta.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              )
            else
              ...c.accounts.map((a) => _AccountCard(account: a)),
          ],
        ),
      ),
    );
  }

  static void _openAccountSheet(BuildContext context, {AccountModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AccountFormSheet(existing: existing),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account});

  final AccountModel account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit = account.kind == AccountKind.credito;
    final amountLabel = isCredit ? 'Deuda' : 'Saldo';
    final amountValue = isCredit ? account.debtCents : account.balanceCents;
    final amountColor = isCredit
        ? (account.debtCents > 0 ? theme.colorScheme.error : theme.colorScheme.primary)
        : (account.balanceCents < 0 ? theme.colorScheme.error : theme.colorScheme.primary);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => AccountsScreen._openAccountSheet(context, existing: account),
          onLongPress: () => _confirmDelete(context, account),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_iconFor(account.kind), color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        account.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      _kindLabel(account.kind),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          amountLabel,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        Text(
                          formatMxnCents(amountValue),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: amountColor,
                          ),
                        ),
                      ],
                    ),
                    if (isCredit && account.creditLimitCents != null) ...[
                      const SizedBox(width: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Disponible',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          Text(
                            formatMxnCents(account.availableCreditCents!),
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(AccountKind kind) => switch (kind) {
        AccountKind.credito => Icons.credit_card,
        AccountKind.debito => Icons.payment,
        AccountKind.efectivo => Icons.payments_outlined,
      };

  static String _kindLabel(AccountKind kind) => switch (kind) {
        AccountKind.credito => 'Crédito',
        AccountKind.debito => 'Débito',
        AccountKind.efectivo => 'Efectivo',
      };

  static Future<void> _confirmDelete(BuildContext context, AccountModel account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Text('¿Eliminar “${account.name}”? Esto no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await context.read<AppController>().deleteAccount(account.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Cuenta eliminada.'
              : 'Esta cuenta tiene movimientos, no se puede eliminar.',
        ),
      ),
    );
  }
}

class _AccountFormSheet extends StatefulWidget {
  const _AccountFormSheet({this.existing});

  final AccountModel? existing;

  @override
  State<_AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<_AccountFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _initialCtrl;
  late final TextEditingController _limitCtrl;
  late AccountKind _kind;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _kind = e?.kind ?? AccountKind.debito;
    _initialCtrl = TextEditingController(
      text: e == null
          ? ''
          : (e.kind == AccountKind.credito ? e.debtCents : e.balanceCents) == 0
              ? ''
              : ((e.kind == AccountKind.credito ? e.debtCents : e.balanceCents) / 100)
                  .toStringAsFixed(2),
    );
    _limitCtrl = TextEditingController(
      text: e?.creditLimitCents == null ? '' : (e!.creditLimitCents! / 100).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _initialCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  int? _centsFrom(TextEditingController ctrl) {
    final t = ctrl.text.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    final v = double.tryParse(t);
    if (v == null) return null;
    return (v * 100).round();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ponle un nombre a la cuenta.')),
      );
      return;
    }
    final controller = context.read<AppController>();
    if (_isEditing) {
      await controller.updateAccount(
        id: widget.existing!.id,
        name: name,
        creditLimitCents: _kind == AccountKind.credito ? _centsFrom(_limitCtrl) : null,
      );
    } else {
      final initial = _centsFrom(_initialCtrl) ?? 0;
      await controller.addAccount(
        name: name,
        kind: _kind,
        initialBalanceCents: _kind == AccountKind.credito ? 0 : initial,
        initialDebtCents: _kind == AccountKind.credito ? initial : 0,
        creditLimitCents: _kind == AccountKind.credito ? _centsFrom(_limitCtrl) : null,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit = _kind == AccountKind.credito;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'Editar cuenta' : 'Nueva cuenta',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej.: Nu Crédito, Banco Azteca Débito',
                ),
              ),
              const SizedBox(height: 12),
              if (!_isEditing) ...[
                Text(
                  'Tipo',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: AccountKind.values.map((k) {
                    final selected = _kind == k;
                    return ChoiceChip(
                      label: Text(_labelFor(k)),
                      selected: selected,
                      onSelected: (_) => setState(() => _kind = k),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _initialCtrl,
                enabled: !_isEditing,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                decoration: InputDecoration(
                  labelText: isCredit ? 'Deuda inicial (opcional)' : 'Saldo inicial (opcional)',
                  hintText: 'Ej.: 1500',
                ),
              ),
              if (isCredit) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _limitCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  decoration: const InputDecoration(
                    labelText: 'Límite de crédito (opcional)',
                    hintText: 'Ej.: 20000',
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  static String _labelFor(AccountKind k) => switch (k) {
        AccountKind.efectivo => 'Efectivo',
        AccountKind.debito => 'Débito',
        AccountKind.credito => 'Crédito',
      };
}
