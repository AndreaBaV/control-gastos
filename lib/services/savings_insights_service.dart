import 'package:flutter/material.dart';

import '../data/app_database.dart' show globalBudgetCategoryId;
import '../models/budget_model.dart';
import '../models/category_model.dart';

class SavingsInsight {
  const SavingsInsight({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;
}

class SavingsInsightsService {
  static List<SavingsInsight> build({
    required int totalSpentCents,
    required Map<String, int> spentByCategory,
    required List<CategoryModel> categories,
    required List<BudgetModel> budgets,
  }) {
    final out = <SavingsInsight>[];

    final budgetByCat = {for (final b in budgets) b.categoryId: b.amountCents};

    final global = budgetByCat[globalBudgetCategoryId];
    if (global != null && global > 0) {
      final ratio = totalSpentCents / global;
      if (ratio >= 1) {
        out.add(
          const SavingsInsight(
            title: 'Presupuesto global superado',
            body:
                'Este mes superaste tu tope total. Revisa los gastos de “Otros” y posibles suscripciones duplicadas.',
            icon: Icons.warning_amber_rounded,
          ),
        );
      } else if (ratio >= 0.85) {
        out.add(
          SavingsInsight(
            title: 'Cerca del límite total',
            body:
                'Llevas el ${(ratio * 100).round()}% del presupuesto mensual global. Prioriza lo esencial hasta fin de mes.',
            icon: Icons.trending_up,
          ),
        );
      }
    }

    for (final cat in categories) {
      final limit = budgetByCat[cat.id];
      if (limit == null || limit <= 0) continue;
      final spent = spentByCategory[cat.id] ?? 0;
      final r = spent / limit;
      if (r >= 0.9) {
        out.add(
          SavingsInsight(
            title: 'Revisa ${cat.name}',
            body:
                'Has usado más del 90% del presupuesto de esta categoría. Un día sin gasto aquí suma al ahorro.',
            icon: cat.icon,
          ),
        );
      }
    }

    final sorted = categories
        .map((c) => MapEntry(c, spentByCategory[c.id] ?? 0))
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isNotEmpty) {
      final top = sorted.first;
      if (top.value > 0 && totalSpentCents > 0) {
        final share = top.value / totalSpentCents;
        if (share >= 0.35) {
          out.add(
            SavingsInsight(
              title: 'Concentración en ${top.key.name}',
              body:
                  'Cerca del ${(share * 100).round()}% de tus gastos van a una sola categoría. Pequeños recortes ahí se notan mucho.',
              icon: Icons.pie_chart_outline,
            ),
          );
        }
      }
    }

    out.addAll(_staticTips());

    final seen = <String>{};
    final deduped = <SavingsInsight>[];
    for (final i in out) {
      final k = '${i.title}|${i.body}';
      if (seen.add(k)) deduped.add(i);
    }
    return deduped.take(8).toList();
  }

  static List<SavingsInsight> _staticTips() {
    const tips = [
      SavingsInsight(
        title: 'Regla de las 24 horas',
        body:
            'Antes de compras no esenciales, espera un día. Muchas veces el impulso desaparece y ahorras sin esfuerzo.',
        icon: Icons.schedule,
      ),
      SavingsInsight(
        title: 'Suma de microgastos',
        body:
            'Cafés y snacks sueltos parecen poco, pero al mes suman. Llevarlos aquí con la voz ayuda a ver el total real.',
        icon: Icons.local_cafe_outlined,
      ),
      SavingsInsight(
        title: 'Tope semanal',
        body:
            'Divide tu presupuesto mensual entre cuatro. Si una semana te pasas, compensa la siguiente: es más manejable.',
        icon: Icons.calendar_view_week,
      ),
      SavingsInsight(
        title: 'Meta visible',
        body:
            'Define un número concreto de ahorro mensual y trátalo como un gasto más: primero aparta, luego gasta lo que queda.',
        icon: Icons.savings_outlined,
      ),
    ];
    final i = DateTime.now().millisecondsSinceEpoch % tips.length;
    return [tips[i], tips[(i + 1) % tips.length]];
  }
}
