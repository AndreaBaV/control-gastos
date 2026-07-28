import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/account_model.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';

const _globalBudgetCategoryId = '__global__';
const _defaultAccountId = 'acc_default_efectivo';

String get globalBudgetCategoryId => _globalBudgetCategoryId;
String get defaultAccountId => _defaultAccountId;

(int startMs, int endExclusiveMs) _monthRangeMillis(String yearMonth) {
  final d = DateTime.parse('$yearMonth-01');
  final end = DateTime(d.year, d.month + 1, 1);
  return (d.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
}

class AccountHasTransactionsException implements Exception {
  const AccountHasTransactionsException();
}

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;
  final _uuid = const Uuid();

  /// Cierra la base de datos (útil en tests).
  Future<void> closeForTesting() async {
    await _db?.close();
    _db = null;
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'control_gastos.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createV2Schema(db);
        await _seedCategories(db);
        await _seedDefaultAccount(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _migrateV1ToV2(db);
        }
      },
    );
  }

  Future<void> _createV2Schema(Database db) async {
    await db.execute('''
CREATE TABLE categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  icon_code TEXT NOT NULL,
  sort_order INTEGER NOT NULL,
  kind TEXT NOT NULL DEFAULT 'gasto'
)''');
    await db.execute('''
CREATE TABLE accounts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  kind TEXT NOT NULL,
  balance_cents INTEGER NOT NULL DEFAULT 0,
  debt_cents INTEGER NOT NULL DEFAULT 0,
  credit_limit_cents INTEGER,
  sort_order INTEGER NOT NULL,
  created_at INTEGER NOT NULL
)''');
    await db.execute('''
CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  amount_cents INTEGER NOT NULL,
  note TEXT NOT NULL,
  category_id TEXT,
  account_id TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (category_id) REFERENCES categories (id),
  FOREIGN KEY (account_id) REFERENCES accounts (id)
)''');
    await db.execute('''
CREATE TABLE monthly_budgets (
  id TEXT PRIMARY KEY,
  category_id TEXT NOT NULL,
  year_month TEXT NOT NULL,
  amount_cents INTEGER NOT NULL,
  UNIQUE(category_id, year_month)
)''');
  }

  Future<void> _migrateV1ToV2(Database db) async {
    await db.execute('ALTER TABLE categories ADD COLUMN kind TEXT NOT NULL DEFAULT \'gasto\'');
    await db.execute('''
CREATE TABLE accounts (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  kind TEXT NOT NULL,
  balance_cents INTEGER NOT NULL DEFAULT 0,
  debt_cents INTEGER NOT NULL DEFAULT 0,
  credit_limit_cents INTEGER,
  sort_order INTEGER NOT NULL,
  created_at INTEGER NOT NULL
)''');
    await db.execute('''
CREATE TABLE transactions (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  amount_cents INTEGER NOT NULL,
  note TEXT NOT NULL,
  category_id TEXT,
  account_id TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (category_id) REFERENCES categories (id),
  FOREIGN KEY (account_id) REFERENCES accounts (id)
)''');
    await _seedDefaultAccount(db);
    await db.execute('''
INSERT INTO transactions (id, type, amount_cents, note, category_id, account_id, created_at)
SELECT id, 'gasto', amount_cents, note, category_id, ?, created_at FROM expenses
''', [_defaultAccountId]);
    await db.execute('DROP TABLE expenses');
    await _seedIncomeCategories(db);
  }

  Future<void> _seedDefaultAccount(Database db) async {
    await db.insert('accounts', {
      'id': _defaultAccountId,
      'name': 'Efectivo',
      'kind': accountKindToString(AccountKind.efectivo),
      'balance_cents': 0,
      'debt_cents': 0,
      'credit_limit_cents': null,
      'sort_order': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _seedCategories(Database db) async {
    final defaults = <(String id, String name, String iconKey, int order)>[
      ('cat_food', 'Comida', 'restaurant', 0),
      ('cat_transport', 'Transporte', 'directions_car', 1),
      ('cat_home', 'Casa', 'home', 2),
      ('cat_fun', 'Ocio', 'movie', 3),
      ('cat_health', 'Salud', 'favorite', 4),
      ('cat_shopping', 'Compras', 'shopping_bag', 5),
      ('cat_other', 'Otros', 'category', 6),
    ];
    for (final row in defaults) {
      await db.insert('categories', {
        'id': row.$1,
        'name': row.$2,
        'icon_code': row.$3,
        'sort_order': row.$4,
        'kind': categoryKindToString(CategoryKind.gasto),
      });
    }
    await _seedIncomeCategories(db);
  }

  Future<void> _seedIncomeCategories(Database db) async {
    final defaults = <(String id, String name, String iconKey, int order)>[
      ('cat_income_salary', 'Sueldo', 'work_outline', 100),
      ('cat_income_freelance', 'Freelance', 'laptop_mac', 101),
      ('cat_income_other', 'Otro ingreso', 'savings_outlined', 102),
    ];
    for (final row in defaults) {
      await db.insert(
        'categories',
        {
          'id': row.$1,
          'name': row.$2,
          'icon_code': row.$3,
          'sort_order': row.$4,
          'kind': categoryKindToString(CategoryKind.ingreso),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<List<CategoryModel>> getCategories() async {
    final db = await database;
    final rows = await db.query('categories', orderBy: 'sort_order ASC');
    return rows.map(CategoryModel.fromMap).toList();
  }

  // ---- Accounts ----

  Future<List<AccountModel>> getAccounts() async {
    final db = await database;
    final rows = await db.query('accounts', orderBy: 'sort_order ASC, created_at ASC');
    return rows.map(AccountModel.fromMap).toList();
  }

  Future<AccountModel?> getAccount(String id) async {
    final db = await database;
    final rows = await db.query('accounts', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return AccountModel.fromMap(rows.first);
  }

  Future<String> insertAccount({
    required String name,
    required AccountKind kind,
    int initialBalanceCents = 0,
    int initialDebtCents = 0,
    int? creditLimitCents,
  }) async {
    final db = await database;
    final rows = await db.query('accounts');
    final id = _uuid.v4();
    await db.insert('accounts', {
      'id': id,
      'name': name.trim(),
      'kind': accountKindToString(kind),
      'balance_cents': kind == AccountKind.credito ? 0 : initialBalanceCents,
      'debt_cents': kind == AccountKind.credito ? initialDebtCents : 0,
      'credit_limit_cents': kind == AccountKind.credito ? creditLimitCents : null,
      'sort_order': rows.length,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    return id;
  }

  Future<void> updateAccount({
    required String id,
    required String name,
    int? creditLimitCents,
  }) async {
    final db = await database;
    await db.update(
      'accounts',
      {'name': name.trim(), 'credit_limit_cents': creditLimitCents},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAccount(String id) async {
    final db = await database;
    final refs = await db.query(
      'transactions',
      where: 'account_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (refs.isNotEmpty) {
      throw const AccountHasTransactionsException();
    }
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _applyAccountEffect({
    required String accountId,
    required TransactionType type,
    required int amountCents,
    required bool reverse,
  }) async {
    final db = await database;
    final account = await getAccount(accountId);
    if (account == null) return;
    final sign = reverse ? -1 : 1;
    if (account.kind == AccountKind.credito) {
      final delta = type == TransactionType.gasto ? amountCents * sign : -amountCents * sign;
      final newDebt = account.debtCents + delta;
      await db.update(
        'accounts',
        {'debt_cents': newDebt < 0 ? 0 : newDebt},
        where: 'id = ?',
        whereArgs: [accountId],
      );
    } else {
      final delta = type == TransactionType.gasto ? -amountCents * sign : amountCents * sign;
      await db.rawUpdate(
        'UPDATE accounts SET balance_cents = balance_cents + ? WHERE id = ?',
        [delta, accountId],
      );
    }
  }

  // ---- Transactions ----

  Future<List<TransactionModel>> transactionsForMonth(String yearMonth) async {
    final db = await database;
    final (start, endMs) = _monthRangeMillis(yearMonth);
    final rows = await db.query(
      'transactions',
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [start, endMs],
      orderBy: 'created_at DESC',
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<int> sumForMonth(String yearMonth, TransactionType type) async {
    final db = await database;
    final (start, endMs) = _monthRangeMillis(yearMonth);
    final res = await db.rawQuery(
      'SELECT COALESCE(SUM(amount_cents), 0) AS t FROM transactions '
      'WHERE created_at >= ? AND created_at < ? AND type = ?',
      [start, endMs, transactionTypeToString(type)],
    );
    return (res.first['t'] as int?) ?? 0;
  }

  Future<Map<String, int>> sumByCategoryForMonth(String yearMonth) async {
    final db = await database;
    final (start, endMs) = _monthRangeMillis(yearMonth);
    final rows = await db.rawQuery(
      '''
SELECT category_id, COALESCE(SUM(amount_cents), 0) AS t
FROM transactions
WHERE created_at >= ? AND created_at < ? AND type = 'gasto'
GROUP BY category_id''',
      [start, endMs],
    );
    final map = <String, int>{};
    for (final r in rows) {
      final catId = r['category_id'] as String?;
      if (catId == null) continue;
      map[catId] = r['t']! as int;
    }
    return map;
  }

  Future<void> insertTransaction({
    required TransactionType type,
    required int amountCents,
    required String note,
    String? categoryId,
    required String accountId,
    DateTime? createdAt,
  }) async {
    final db = await database;
    await db.insert('transactions', {
      'id': _uuid.v4(),
      'type': transactionTypeToString(type),
      'amount_cents': amountCents,
      'note': note.trim(),
      'category_id': categoryId,
      'account_id': accountId,
      'created_at': (createdAt ?? DateTime.now()).millisecondsSinceEpoch,
    });
    await _applyAccountEffect(
      accountId: accountId,
      type: type,
      amountCents: amountCents,
      reverse: false,
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    final rows = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return;
    final tx = TransactionModel.fromMap(rows.first);
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    await _applyAccountEffect(
      accountId: tx.accountId,
      type: tx.type,
      amountCents: tx.amountCents,
      reverse: true,
    );
  }

  Future<List<BudgetModel>> budgetsForMonth(String yearMonth) async {
    final db = await database;
    final rows = await db.query(
      'monthly_budgets',
      where: 'year_month = ?',
      whereArgs: [yearMonth],
    );
    return rows.map(BudgetModel.fromMap).toList();
  }

  Future<void> upsertBudget({
    required String categoryId,
    required String yearMonth,
    required int amountCents,
  }) async {
    final db = await database;
    final existing = await db.query(
      'monthly_budgets',
      where: 'category_id = ? AND year_month = ?',
      whereArgs: [categoryId, yearMonth],
    );
    if (amountCents <= 0) {
      if (existing.isNotEmpty) {
        await db.delete(
          'monthly_budgets',
          where: 'category_id = ? AND year_month = ?',
          whereArgs: [categoryId, yearMonth],
        );
      }
      return;
    }
    if (existing.isEmpty) {
      await db.insert('monthly_budgets', {
        'id': _uuid.v4(),
        'category_id': categoryId,
        'year_month': yearMonth,
        'amount_cents': amountCents,
      });
    } else {
      await db.update(
        'monthly_budgets',
        {'amount_cents': amountCents},
        where: 'category_id = ? AND year_month = ?',
        whereArgs: [categoryId, yearMonth],
      );
    }
  }
}
