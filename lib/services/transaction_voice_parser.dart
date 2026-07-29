import '../models/account_model.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import 'categorization_service.dart';

class ParsedVoiceTransaction {
  const ParsedVoiceTransaction({
    required this.rawText,
    required this.type,
    this.amountCents,
    this.note = '',
    this.accountId,
    this.categoryId,
  });

  final String rawText;
  final TransactionType type;
  final int? amountCents;
  final String note;
  final String? accountId;
  final String? categoryId;
}

class TransactionVoiceParser {
  static final _wakePrefix = RegExp(
    r'^\s*(?:oye|hey|ok(?:ay)?)\s+\w+[,:]?\s*',
    caseSensitive: false,
  );

  static final _amountWithUnit = RegExp(
    r'(\d+(?:[.,]\d+)?)\s*(?:pesos?|mxn|\$)',
    caseSensitive: false,
  );
  static final _verbAmount = RegExp(
    r'(?:gast[ée]|pagu[ée]|pagado|pagamos|cost[oó]|son|ser[íi]an?|vale|cuestan?)\s+(\d+(?:[.,]\d+)?)',
    caseSensitive: false,
  );
  static final _leadingNumber = RegExp(r'(?:^|\s)(\d+(?:[.,]\d+)?)(?:\s|$)');

  static const _incomeKeywords = [
    'ingreso', 'ingrese', 'cobre', 'deposite', 'deposito',
    'sueldo', 'nomina', 'recibi', 'abono', 'abone',
  ];

  // Palabras de relleno que no aportan al concepto/nota: verbos de comando,
  // artículos, preposiciones y términos genéricos de cuenta/tarjeta (la
  // cuenta ya se identifica por separado en accountId).
  static const _stopWords = {
    'oye', 'hey', 'ok', 'okay',
    'registra', 'registrar', 'anota', 'anotar', 'agrega', 'agregar',
    'guarda', 'guardar', 'apunta', 'apuntar', 'pon', 'poner', 'favor',
    'compra', 'compre', 'comprar', 'compras', 'gasto', 'gastos',
    'pago', 'pagos', 'pague', 'pagar',
    'un', 'una', 'unos', 'unas', 'el', 'la', 'los', 'las', 'lo',
    'de', 'del', 'en', 'para', 'por', 'con', 'a', 'al', 'y', 'que',
    'tarjeta', 'tarjetas', 'cuenta', 'cuentas',
    'debito', 'credito', 'banco', 'efectivo',
  };

  static final _wordPattern = RegExp(r'\S+');
  static final _edgePunctuation = RegExp(r'^[,.;:!?()"“”«»]+|[,.;:!?()"“”«»]+$');

  static ParsedVoiceTransaction parse(
    String raw, {
    List<AccountModel> accounts = const [],
    List<CategoryModel> categories = const [],
  }) {
    final trimmedRaw = raw.trim();
    if (trimmedRaw.isEmpty) {
      return ParsedVoiceTransaction(rawText: raw, type: TransactionType.gasto);
    }

    // `display` conserva mayúsculas y acentos tal cual se dictaron (para la
    // nota final); `remainder` es su versión normalizada (minúsculas, sin
    // acentos) usada solo para detectar palabras clave/importe/cuenta. Ambas
    // cadenas se mantienen del mismo largo, así que cada rango encontrado en
    // `remainder` se puede aplicar tal cual sobre `display`.
    var display = _withoutWakePrefix(trimmedRaw);
    var remainder = _stripAccents(display.toLowerCase());

    var type = TransactionType.gasto;
    for (final kw in _incomeKeywords) {
      final idx = remainder.indexOf(kw);
      if (idx != -1) {
        type = TransactionType.ingreso;
        remainder = remainder.replaceRange(idx, idx + kw.length, ' ');
        display = display.replaceRange(idx, idx + kw.length, ' ');
        break;
      }
    }

    String? categoryId;
    final categoriesForType = categories.where((c) => c.appliesTo(type)).toList();
    if (categoriesForType.isNotEmpty) {
      categoryId = CategorizationService.suggestCategoryId(display, categoriesForType);
    }

    int? cents;
    final m1 = _amountWithUnit.firstMatch(remainder);
    if (m1 != null) {
      cents = _toCents(m1.group(1)!);
      remainder = remainder.replaceRange(m1.start, m1.end, ' ');
      display = display.replaceRange(m1.start, m1.end, ' ');
    }
    cents ??= () {
      final m2 = _verbAmount.firstMatch(remainder);
      if (m2 != null) {
        final c = _toCents(m2.group(1)!);
        if (c != null) {
          remainder = remainder.replaceRange(m2.start, m2.end, ' ');
          display = display.replaceRange(m2.start, m2.end, ' ');
          return c;
        }
      }
      return null;
    }();
    cents ??= () {
      final m3 = _leadingNumber.firstMatch(remainder.trimLeft());
      if (m3 != null) {
        final c = _toCents(m3.group(1)!);
        if (c != null && c > 0) {
          remainder = remainder.replaceRange(m3.start, m3.end, ' ');
          display = display.replaceRange(m3.start, m3.end, ' ');
          return c;
        }
      }
      return null;
    }();

    String? accountId;
    if (accounts.isNotEmpty) {
      final match = _detectAccount(remainder, accounts);
      if (match != null) {
        accountId = match.account.id;
        for (final phrase in match.phrasesToRemove) {
          final idx = remainder.indexOf(phrase);
          if (idx == -1) continue;
          final end = idx + phrase.length;
          remainder = remainder.replaceRange(idx, end, ' ');
          display = display.replaceRange(idx, end, ' ');
        }
      }
    }

    final note = _keyConcept(display: display, remainder: remainder);

    return ParsedVoiceTransaction(
      rawText: raw,
      type: type,
      amountCents: cents,
      note: note.isEmpty ? _withoutWakePrefix(trimmedRaw).trim() : note,
      accountId: accountId,
      categoryId: categoryId,
    );
  }

  /// Reconstruye solo las palabras "clave" del texto restante: recorre
  /// `remainder` palabra por palabra, descarta rellenos (stopwords) y
  /// fragmentos vacíos, y toma cada palabra sobreviviente de `display`
  /// (mismos índices) para conservar su mayúscula/acento original.
  static String _keyConcept({required String display, required String remainder}) {
    final kept = <String>[];
    for (final m in _wordPattern.allMatches(remainder)) {
      final normalizedWord = m.group(0)!.replaceAll(_edgePunctuation, '');
      if (normalizedWord.isEmpty || _stopWords.contains(normalizedWord)) continue;
      final originalWord = display.substring(m.start, m.end).replaceAll(_edgePunctuation, '');
      if (originalWord.isNotEmpty) kept.add(originalWord);
    }
    return kept.join(' ');
  }

  static String _withoutWakePrefix(String text) => text.replaceFirst(_wakePrefix, '');

  static ({AccountModel account, List<String> phrasesToRemove})? _detectAccount(
    String normalizedText,
    List<AccountModel> accounts,
  ) {
    AccountModel? bestAccount;
    List<String> bestPhrases = const [];
    var bestScore = 0;

    for (final acc in accounts) {
      final accNorm = _stripAccents(acc.name.toLowerCase());
      if (accNorm.isEmpty) continue;

      if (normalizedText.contains(accNorm)) {
        final score = accNorm.length * 2;
        if (score > bestScore) {
          bestScore = score;
          bestAccount = acc;
          bestPhrases = [accNorm];
        }
        continue;
      }

      final tokens = accNorm.split(RegExp(r'\s+')).where((t) => t.length >= 3);
      final matchedTokens = tokens.where(normalizedText.contains).toList();
      if (matchedTokens.isNotEmpty) {
        final score = matchedTokens.fold<int>(0, (s, t) => s + t.length);
        if (score > bestScore) {
          bestScore = score;
          bestAccount = acc;
          bestPhrases = matchedTokens;
        }
      }
    }

    if (bestAccount == null) return null;
    return (account: bestAccount, phrasesToRemove: bestPhrases);
  }

  static String _stripAccents(String input) {
    const from = 'áéíóúüñÁÉÍÓÚÜÑ';
    const to = 'aeiouunAEIOUUN';
    var out = input;
    for (var i = 0; i < from.length; i++) {
      out = out.replaceAll(from[i], to[i]);
    }
    return out;
  }

  static int? _toCents(String s) {
    final normalized = s.replaceAll(',', '.');
    final v = double.tryParse(normalized);
    if (v == null || v <= 0) return null;
    return (v * 100).round();
  }
}
