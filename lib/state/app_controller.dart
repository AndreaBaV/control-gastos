import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../models/account_model.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';

class AppController extends ChangeNotifier {
  AppController(this._db);

  final AppDatabase _db;

  bool ready = false;
  String yearMonth = _yearMonth(DateTime.now());
  List<CategoryModel> categories = [];
  List<AccountModel> accounts = [];
  List<TransactionModel> transactions = [];
  List<BudgetModel> budgets = [];
  int monthExpenseCents = 0;
  int monthIncomeCents = 0;
  Map<String, int> spentByCategory = {};

  static String _yearMonth(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  Future<void> init() async {
    await _db.database;
    ready = true;
    await refresh();
  }

  Future<void> refresh() async {
    categories = await _db.getCategories();
    accounts = await _db.getAccounts();
    transactions = await _db.transactionsForMonth(yearMonth);
    budgets = await _db.budgetsForMonth(yearMonth);
    monthExpenseCents = await _db.sumForMonth(yearMonth, TransactionType.gasto);
    monthIncomeCents = await _db.sumForMonth(yearMonth, TransactionType.ingreso);
    spentByCategory = await _db.sumByCategoryForMonth(yearMonth);
    notifyListeners();
  }

  Future<void> setYearMonth(String ym) async {
    yearMonth = ym;
    await refresh();
  }

  Future<void> shiftMonth(int deltaMonths) async {
    final p = yearMonth.split('-');
    final d = DateTime(int.parse(p[0]), int.parse(p[1]), 1);
    final n = DateTime(d.year, d.month + deltaMonths, 1);
    yearMonth = _yearMonth(n);
    await refresh();
  }

  Future<void> addTransaction({
    required TransactionType type,
    required int amountCents,
    required String note,
    String? categoryId,
    required String accountId,
    DateTime? createdAt,
  }) async {
    await _db.insertTransaction(
      type: type,
      amountCents: amountCents,
      note: note,
      categoryId: categoryId,
      accountId: accountId,
      createdAt: createdAt,
    );
    await refresh();
  }

  Future<void> deleteTransaction(String id) async {
    await _db.deleteTransaction(id);
    await refresh();
  }

  Future<void> saveBudget(String categoryId, int amountCents) async {
    await _db.upsertBudget(
      categoryId: categoryId,
      yearMonth: yearMonth,
      amountCents: amountCents,
    );
    await refresh();
  }

  int? budgetCentsFor(String categoryId) {
    for (final b in budgets) {
      if (b.categoryId == categoryId) return b.amountCents;
    }
    return null;
  }

  AccountModel? accountById(String id) {
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  Future<String> addAccount({
    required String name,
    required AccountKind kind,
    int initialBalanceCents = 0,
    int initialDebtCents = 0,
    int? creditLimitCents,
  }) async {
    final id = await _db.insertAccount(
      name: name,
      kind: kind,
      initialBalanceCents: initialBalanceCents,
      initialDebtCents: initialDebtCents,
      creditLimitCents: creditLimitCents,
    );
    await refresh();
    return id;
  }

  Future<void> updateAccount({
    required String id,
    required String name,
    int? creditLimitCents,
  }) async {
    await _db.updateAccount(id: id, name: name, creditLimitCents: creditLimitCents);
    await refresh();
  }

  /// Devuelve false si la cuenta tiene movimientos y no se pudo borrar.
  Future<bool> deleteAccount(String id) async {
    try {
      await _db.deleteAccount(id);
      await refresh();
      return true;
    } on AccountHasTransactionsException {
      return false;
    }
  }
}
