import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../state/app_controller.dart';
import '../util/money_format.dart';

/// Genera y comparte (hoja de compartir de iOS/Android) un reporte del mes
/// activo del [AppController], en PDF o CSV.
class ReportExportService {
  static CategoryModel? _categoryFor(AppController controller, String? id) {
    if (id == null) return null;
    for (final c in controller.categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  static Future<void> exportPdf({required AppController controller}) async {
    final doc = pw.Document();
    final monthLabel = formatYearMonthLabel(controller.yearMonth);

    final categoryRows = <List<String>>[];
    final sortedEntries = controller.spentByCategory.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sortedEntries) {
      final name = _categoryFor(controller, entry.key)?.name ?? 'Otros';
      categoryRows.add([name, formatMxnCents(entry.value)]);
    }

    doc.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Control Gastos · Reporte',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(monthLabel),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Ingresos: ${formatMxnCents(controller.monthIncomeCents)}'),
                pw.Text('Gastos: ${formatMxnCents(controller.monthExpenseCents)}'),
                pw.Text(
                  'Neto: ${formatMxnCents(controller.monthIncomeCents - controller.monthExpenseCents)}',
                ),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Text('Gasto por categoría', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            if (categoryRows.isEmpty)
              pw.Text('Sin gastos este mes.')
            else
              pw.TableHelper.fromTextArray(headers: const ['Categoría', 'Importe'], data: categoryRows),
          ],
        ),
      ),
    );

    final bytes = await doc.save();
    await Printing.sharePdf(bytes: bytes, filename: 'reporte-${controller.yearMonth}.pdf');
  }

  static Future<void> exportCsv({required AppController controller}) async {
    final rows = <List<String>>[
      ['Fecha', 'Tipo', 'Cuenta', 'Categoría', 'Nota', 'Importe'],
    ];
    for (final tx in controller.transactions) {
      final account = controller.accountById(tx.accountId);
      final category = _categoryFor(controller, tx.categoryId);
      rows.add([
        tx.createdAt.toIso8601String(),
        transactionTypeToString(tx.type),
        account?.name ?? '',
        category?.name ?? '',
        tx.note,
        (tx.amountCents / 100).toStringAsFixed(2),
      ]);
    }

    final content = csv.encode(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/reporte-${controller.yearMonth}.csv');
    await file.writeAsString(content);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Reporte ${controller.yearMonth}',
      ),
    );
  }
}
