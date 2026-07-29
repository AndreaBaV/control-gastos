import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/goal_contribution_model.dart';
import '../models/goal_model.dart';
import '../state/app_controller.dart';
import '../util/money_format.dart';

class GoalDetailScreen extends StatefulWidget {
  const GoalDetailScreen({super.key, required this.goalId});

  final String goalId;

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  List<GoalContributionModel> _contributions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await context.read<AppController>().contributionsForGoal(widget.goalId);
    if (!mounted) return;
    setState(() {
      _contributions = list;
      _loading = false;
    });
  }

  Future<void> _deleteContribution(String id) async {
    await context.read<AppController>().deleteContribution(id);
    await _load();
  }

  void _openContributionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContributionFormSheet(goalId: widget.goalId, onSaved: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.watch<AppController>();
    GoalModel? goal;
    for (final g in c.goals) {
      if (g.id == widget.goalId) {
        goal = g;
        break;
      }
    }
    final progressCents = c.goalProgressCents[widget.goalId] ?? 0;

    if (goal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Meta')),
        body: const Center(child: Text('Esta meta ya no existe.')),
      );
    }

    final ratio = goal.targetCents > 0 ? (progressCents / goal.targetCents).clamp(0.0, 1.0) : 0.0;
    final reached = progressCents >= goal.targetCents;

    return Scaffold(
      appBar: AppBar(title: Text(goal.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openContributionSheet,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatMxnCents(progressCents),
                        style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'de ${formatMxnCents(goal.targetCents)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 10,
                          backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                          color: reached ? Colors.green : theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(ratio * 100).round()}%'
                        '${goal.targetDate != null ? ' · límite ${DateFormat.yMMMd('es_MX').format(goal.targetDate!)}' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Aportaciones',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_contributions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Sin aportaciones todavía.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                )
              else
                ..._contributions.map((con) {
                  final isPositive = con.amountCents >= 0;
                  final color = isPositive ? Colors.green : theme.colorScheme.error;
                  return Dismissible(
                    key: Key(con.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                    ),
                    onDismissed: (_) => _deleteContribution(con.id),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Icon(
                                isPositive ? Icons.add_circle_outline : Icons.remove_circle_outline,
                                color: color,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      con.note.isEmpty ? (isPositive ? 'Aportación' : 'Retiro') : con.note,
                                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      DateFormat.yMMMd('es_MX').format(con.createdAt),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isPositive ? '+' : '-'}${formatMxnCents(con.amountCents.abs())}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContributionFormSheet extends StatefulWidget {
  const _ContributionFormSheet({required this.goalId, required this.onSaved});

  final String goalId;
  final VoidCallback onSaved;

  @override
  State<_ContributionFormSheet> createState() => _ContributionFormSheetState();
}

class _ContributionFormSheetState extends State<_ContributionFormSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isWithdrawal = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _amountCtrl.text.trim().replaceAll(',', '.');
    final value = double.tryParse(text);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica un importe válido.')),
      );
      return;
    }
    final cents = (value * 100).round() * (_isWithdrawal ? -1 : 1);
    await context.read<AppController>().addContribution(
          goalId: widget.goalId,
          amountCents: cents,
          note: _noteCtrl.text.trim(),
        );
    widget.onSaved();
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
                'Nueva aportación',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Aportar'), icon: Icon(Icons.add)),
                  ButtonSegment(value: true, label: Text('Retirar'), icon: Icon(Icons.remove)),
                ],
                selected: {_isWithdrawal},
                onSelectionChanged: (s) => setState(() => _isWithdrawal = s.first),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                decoration: const InputDecoration(labelText: 'Importe', hintText: 'Ej.: 500'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nota (opcional)',
                  hintText: 'Ej.: Aguinaldo',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: Text(_isWithdrawal ? 'Registrar retiro' : 'Registrar aportación'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
