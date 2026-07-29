import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/app_database.dart' show globalBudgetCategoryId;
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../state/app_controller.dart';
import '../util/money_format.dart';
import 'shell_screen.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final theme = Theme.of(context);
    final catBudgets = c.categories.where((cat) => cat.appliesTo(TransactionType.gasto)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Presupuesto')),
      body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            'Define límites mensuales por categoría y un tope global opcional. Los datos viven solo en tu dispositivo.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 20),
          const MonthSwitcher(),
          const SizedBox(height: 20),
          _GlobalBudgetCard(
            key: ValueKey('${c.yearMonth}-global'),
            cents: c.budgetCentsFor(globalBudgetCategoryId),
            onSave: (euros) => _saveEuros(context, globalBudgetCategoryId, euros),
          ),
          const SizedBox(height: 8),
          Text(
            'Por categoría',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...catBudgets.map(
            (cat) => _CategoryBudgetRow(
              key: ValueKey('${c.yearMonth}-${cat.id}'),
              category: cat,
              cents: c.budgetCentsFor(cat.id),
              spent: c.spentByCategory[cat.id] ?? 0,
              onSave: (euros) => _saveEuros(context, cat.id, euros),
            ),
          ),
        ],
      ),
      ),
    );
  }

  static Future<void> _saveEuros(BuildContext context, String categoryId, double? euros) async {
    final cents = euros == null || euros <= 0 ? 0 : (euros * 100).round();
    await context.read<AppController>().saveBudget(categoryId, cents);
  }
}

class _GlobalBudgetCard extends StatefulWidget {
  const _GlobalBudgetCard({
    super.key,
    required this.cents,
    required this.onSave,
  });

  final int? cents;
  final Future<void> Function(double?) onSave;

  @override
  State<_GlobalBudgetCard> createState() => _GlobalBudgetCardState();
}

class _GlobalBudgetCardState extends State<_GlobalBudgetCard> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _initialText());
  }

  String _initialText() {
    if (widget.cents == null || widget.cents! <= 0) return '';
    return (widget.cents! / 100).toStringAsFixed(0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tope mensual total (opcional)',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                    decoration: const InputDecoration(
                      hintText: 'Ej.: 1200',
                      suffixText: r'$',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: () async {
                    final t = _ctrl.text.trim().replaceAll(',', '.');
                    final v = double.tryParse(t);
                    await widget.onSave(v);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Presupuesto global actualizado.')),
                      );
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBudgetRow extends StatefulWidget {
  const _CategoryBudgetRow({
    super.key,
    required this.category,
    required this.cents,
    required this.spent,
    required this.onSave,
  });

  final CategoryModel category;
  final int? cents;
  final int spent;
  final Future<void> Function(double?) onSave;

  @override
  State<_CategoryBudgetRow> createState() => _CategoryBudgetRowState();
}

class _CategoryBudgetRowState extends State<_CategoryBudgetRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _textFromCents(widget.cents));
  }

  @override
  void didUpdateWidget(covariant _CategoryBudgetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cents != widget.cents) {
      _ctrl.text = _textFromCents(widget.cents);
    }
  }

  String _textFromCents(int? cents) {
    if (cents == null || cents <= 0) return '';
    return (cents / 100).toStringAsFixed(2);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final limit = widget.cents ?? 0;
    final ratio = limit > 0 ? (widget.spent / limit).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(widget.category.icon, color: theme.colorScheme.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.category.name,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    'Gastado ${formatMxnCents(widget.spent)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              if (limit > 0) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio.toDouble(),
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                    color: widget.spent > limit ? theme.colorScheme.error : theme.colorScheme.primary,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                      decoration: const InputDecoration(
                        hintText: 'Límite en pesos',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      _ctrl.clear();
                      await widget.onSave(null);
                    },
                    child: const Text('Quitar'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final t = _ctrl.text.trim().replaceAll(',', '.');
                      final v = double.tryParse(t);
                      await widget.onSave(v);
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
