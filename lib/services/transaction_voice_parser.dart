import '../models/account_model.dart';
import '../models/transaction_model.dart';

class ParsedVoiceTransaction {
  const ParsedVoiceTransaction({
    required this.rawText,
    required this.type,
    this.amountCents,
    this.note = '',
    this.accountId,
  });

  final String rawText;
  final TransactionType type;
  final int? amountCents;
  final String note;
  final String? accountId;
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

  static ParsedVoiceTransaction parse(
    String raw, {
    List<AccountModel> accounts = const [],
  }) {
    final trimmedRaw = raw.trim();
    if (trimmedRaw.isEmpty) {
      return ParsedVoiceTransaction(rawText: raw, type: TransactionType.gasto);
    }

    final withoutWake = trimmedRaw.replaceFirst(_wakePrefix, '');
    var remainder = _stripAccents(withoutWake.toLowerCase());

    var type = TransactionType.gasto;
    for (final kw in _incomeKeywords) {
      final idx = remainder.indexOf(kw);
      if (idx != -1) {
        type = TransactionType.ingreso;
        remainder = remainder.replaceRange(idx, idx + kw.length, ' ');
        break;
      }
    }

    int? cents;
    final m1 = _amountWithUnit.firstMatch(remainder);
    if (m1 != null) {
      cents = _toCents(m1.group(1)!);
      remainder = remainder.replaceRange(m1.start, m1.end, ' ');
    }
    cents ??= () {
      final m2 = _verbAmount.firstMatch(remainder);
      if (m2 != null) {
        final c = _toCents(m2.group(1)!);
        if (c != null) {
          remainder = remainder.replaceRange(m2.start, m2.end, ' ');
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
          remainder = remainder.replaceAll(phrase, ' ');
        }
      }
    }

    final note = remainder
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^(en|de|para|por|con|a)\s+'), '')
        .trim();

    return ParsedVoiceTransaction(
      rawText: raw,
      type: type,
      amountCents: cents,
      note: note.isEmpty ? _stripAccents(withoutWake.toLowerCase()).trim() : note,
      accountId: accountId,
    );
  }

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
