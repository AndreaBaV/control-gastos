import 'package:intl/intl.dart';

String formatMxnCents(int cents) {
  final fmt = NumberFormat.currency(
    locale: 'es_MX',
    symbol: r'$',
    decimalDigits: 2,
  );
  return fmt.format(cents / 100.0);
}

String formatYearMonthLabel(String yearMonth) {
  final d = DateTime.parse('$yearMonth-01');
  return DateFormat.yMMMM('es_MX').format(d);
}
