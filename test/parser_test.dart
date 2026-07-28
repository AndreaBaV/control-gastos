import 'package:control_gastos/models/account_model.dart';
import 'package:control_gastos/models/category_model.dart';
import 'package:control_gastos/models/transaction_model.dart';
import 'package:control_gastos/services/categorization_service.dart';
import 'package:control_gastos/services/transaction_voice_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sampleCategories = [
    CategoryModel(
      id: 'cat_food',
      name: 'Comida',
      iconKey: 'restaurant',
      sortOrder: 0,
    ),
    CategoryModel(
      id: 'cat_transport',
      name: 'Transporte',
      iconKey: 'directions_car',
      sortOrder: 1,
    ),
    CategoryModel(
      id: 'cat_other',
      name: 'Otros',
      iconKey: 'category',
      sortOrder: 6,
    ),
  ];

  final sampleAccounts = [
    AccountModel(
      id: 'acc_nu',
      name: 'Nu Crédito',
      kind: AccountKind.credito,
      balanceCents: 0,
      debtCents: 0,
      sortOrder: 0,
      createdAt: DateTime(2026, 1, 1),
    ),
    AccountModel(
      id: 'acc_azteca',
      name: 'Banco Azteca Crédito',
      kind: AccountKind.credito,
      balanceCents: 0,
      debtCents: 0,
      sortOrder: 1,
      createdAt: DateTime(2026, 1, 1),
    ),
    AccountModel(
      id: 'acc_efectivo',
      name: 'Efectivo',
      kind: AccountKind.efectivo,
      balanceCents: 0,
      debtCents: 0,
      sortOrder: 2,
      createdAt: DateTime(2026, 1, 1),
    ),
  ];

  test('parsea importe en pesos', () {
    final p = TransactionVoiceParser.parse('12.50 pesos en gasolina');
    expect(p.amountCents, 1250);
    expect(p.note.toLowerCase(), contains('gasolina'));
    expect(p.type, TransactionType.gasto);
  });

  test('parsea verbo gasté', () {
    final p = TransactionVoiceParser.parse('gasté 8 en el café');
    expect(p.amountCents, 800);
  });

  test('ejemplo del usuario: compra con tarjeta detectada', () {
    final p = TransactionVoiceParser.parse(
      'Oye Joel, registra una compra de un rastrillo Gillette de 25 pesos, tarjeta de crédito banco azteca',
      accounts: sampleAccounts,
    );
    expect(p.amountCents, 2500);
    expect(p.type, TransactionType.gasto);
    expect(p.accountId, 'acc_azteca');
    expect(p.note.toLowerCase(), contains('gillette'));
  });

  test('detecta ingreso por palabra clave', () {
    final p = TransactionVoiceParser.parse(
      'ingreso de sueldo 5000 pesos a efectivo',
      accounts: sampleAccounts,
    );
    expect(p.type, TransactionType.ingreso);
    expect(p.amountCents, 500000);
    expect(p.accountId, 'acc_efectivo');
  });

  test('sugiere transporte por palabra clave', () {
    final id = CategorizationService.suggestCategoryId(
      'pago de taxi al aeropuerto',
      sampleCategories,
    );
    expect(id, 'cat_transport');
  });
}
