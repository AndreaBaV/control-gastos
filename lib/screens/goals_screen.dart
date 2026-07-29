import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/goal_model.dart';
import '../state/app_controller.dart';
import '../util/money_format.dart';
import 'goal_detail_screen.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Metas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openGoalSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva meta'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          children: [
            Text(
              'Ahorra para algo concreto: pon un monto objetivo y registra tus aportaciones.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 20),
            if (c.goals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'Sin metas todavía.\nToca “Nueva meta” para crear la primera.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              )
            else
              ...c.goals.map((g) => _GoalCard(goal: g, progressCents: c.goalProgressCents[g.id] ?? 0)),
          ],
        ),
      ),
    );
  }

  static void _openGoalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _GoalFormSheet(),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.progressCents});

  final GoalModel goal;
  final int progressCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = goal.targetCents > 0 ? (progressCents / goal.targetCents).clamp(0.0, 1.0) : 0.0;
    final reached = progressCents >= goal.targetCents;
    final daysLeft = goal.targetDate?.difference(DateTime.now()).inDays;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => GoalDetailScreen(goalId: goal.id)),
          ),
          onLongPress: () => _confirmDelete(context, goal),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      reached ? Icons.emoji_events : Icons.savings_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        goal.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (daysLeft != null)
                      Text(
                        daysLeft >= 0 ? 'Faltan $daysLeft días' : 'Vencida',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: daysLeft >= 0
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.45)
                              : theme.colorScheme.error,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                    color: reached ? Colors.green : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${formatMxnCents(progressCents)} de ${formatMxnCents(goal.targetCents)} '
                  '(${(ratio * 100).round()}%)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _confirmDelete(BuildContext context, GoalModel goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar meta'),
        content: Text('¿Eliminar “${goal.name}”? Esto no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await context.read<AppController>().deleteGoal(goal.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Meta eliminada.' : 'Esta meta tiene aportaciones, no se puede eliminar.',
        ),
      ),
    );
  }
}

class _GoalFormSheet extends StatefulWidget {
  const _GoalFormSheet();

  @override
  State<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends State<_GoalFormSheet> {
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  DateTime? _targetDate;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final targetText = _targetCtrl.text.trim().replaceAll(',', '.');
    final target = double.tryParse(targetText);
    if (name.isEmpty || target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ponle un nombre y un monto objetivo válido.')),
      );
      return;
    }
    await context.read<AppController>().addGoal(
          name: name,
          targetCents: (target * 100).round(),
          targetDate: _targetDate,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
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
                'Nueva meta',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej.: Vacaciones, Fondo de emergencia',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _targetCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                decoration: const InputDecoration(
                  labelText: 'Monto objetivo',
                  hintText: 'Ej.: 10000',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _targetDate == null
                          ? 'Sin fecha límite (opcional)'
                          : 'Fecha límite: ${DateFormat.yMMMd('es_MX').format(_targetDate!)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  TextButton(onPressed: _pickDate, child: const Text('Elegir fecha')),
                  if (_targetDate != null)
                    IconButton(
                      onPressed: () => setState(() => _targetDate = null),
                      icon: const Icon(Icons.close),
                      tooltip: 'Quitar fecha',
                    ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Crear meta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
