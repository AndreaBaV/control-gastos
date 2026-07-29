import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../state/app_controller.dart';
import '../util/money_format.dart';

/// Desglose de los movimientos de una categoría en el mes activo — se abre
/// al tocar una rebanada de la gráfica de pastel en ReportsScreen.
class CategoryTransactionsScreen extends StatelessWidget {
  const CategoryTransactionsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  final String categoryId;
  final String categoryName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.watch<AppController>();
    final items = c.transactions.where((t) => t.categoryId == categoryId).toList();
    final total = items.fold<int>(0, (s, t) => s + t.amountCents);

    return Scaffold(
      appBar: AppBar(title: Text(categoryName)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      formatYearMonthLabel(c.yearMonth),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    formatMxnCents(total),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        'Sin movimientos de esta categoría este mes.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final tx = items[i];
                        final account = c.accountById(tx.accountId);
                        final isExpense = tx.type == TransactionType.gasto;
                        final color = isExpense ? theme.colorScheme.error : theme.colorScheme.primary;
                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.note.isEmpty ? 'Sin descripción' : tx.note,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${account?.name ?? 'Cuenta'} · ${DateFormat.MMMd('es_MX').format(tx.createdAt)}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${isExpense ? '-' : '+'}${formatMxnCents(tx.amountCents)}',
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: color),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
