import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/categorization_service.dart';
import '../services/transaction_voice_parser.dart';
import '../state/app_controller.dart';
import '../util/money_format.dart';

class AddMovementScreen extends StatefulWidget {
  const AddMovementScreen({super.key, this.initialText});

  /// Texto ya dictado (ej. proveniente de un Atajo de Siri vía deep link).
  final String? initialText;

  @override
  State<AddMovementScreen> createState() => _AddMovementScreenState();
}

class _AddMovementScreenState extends State<AddMovementScreen> {
  final _speech = stt.SpeechToText();
  final _textCtrl = TextEditingController();
  final _amountOverrideCtrl = TextEditingController();

  bool _speechReady = false;
  bool _listening = false;
  TransactionType _type = TransactionType.gasto;
  String? _categoryId;
  String? _accountId;
  bool _accountAutoSelected = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null) _textCtrl.text = widget.initialText!;
    _initSpeech();
    _textCtrl.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onTextChanged());
  }

  Future<void> _initSpeech() async {
    final ok = await _speech.initialize(
      onStatus: (s) {
        if (s == 'notListening' && mounted) setState(() => _listening = false);
      },
      onError: (_) {},
    );
    if (mounted) setState(() => _speechReady = ok);
  }

  void _onTextChanged() {
    final controller = context.read<AppController>();
    final parsed = TransactionVoiceParser.parse(_textCtrl.text, accounts: controller.accounts);

    final cats = controller.categories.where((c) => c.appliesTo(_type)).toList();
    if (cats.isNotEmpty) {
      final suggested = CategorizationService.suggestCategoryId(_textCtrl.text, cats);
      if (suggested != _categoryId && cats.any((c) => c.id == suggested)) {
        setState(() => _categoryId = suggested);
      }
    }

    if (parsed.accountId != null && parsed.accountId != _accountId) {
      setState(() {
        _accountId = parsed.accountId;
        _accountAutoSelected = true;
      });
    }
  }

  @override
  void dispose() {
    _textCtrl.removeListener(_onTextChanged);
    _textCtrl.dispose();
    _amountOverrideCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleListen() async {
    if (!_speechReady) return;
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (r) {
        if (!mounted) return;
        setState(() => _textCtrl.text = r.recognizedWords);
      },
      localeId: 'es_MX',
    );
  }

  ParsedVoiceTransaction _parsed(AppController controller) =>
      TransactionVoiceParser.parse(_textCtrl.text, accounts: controller.accounts);

  int? _resolveAmountCents(AppController controller) {
    final override = _amountOverrideCtrl.text.trim().replaceAll(',', '.');
    if (override.isNotEmpty) {
      final v = double.tryParse(override);
      if (v != null && v > 0) return (v * 100).round();
    }
    return _parsed(controller).amountCents;
  }

  String _resolveNote(AppController controller) {
    final parsed = _parsed(controller);
    if (parsed.note.isNotEmpty) return parsed.note;
    return _textCtrl.text.trim();
  }

  Future<void> _save() async {
    final controller = context.read<AppController>();
    final amount = _resolveAmountCents(controller);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica un importe válido (por voz o en el campo).')),
      );
      return;
    }
    if (_accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige la cuenta o tarjeta del movimiento.')),
      );
      return;
    }
    final note = _resolveNote(controller);
    await controller.addTransaction(
      type: _type,
      amountCents: amount,
      note: note,
      categoryId: _categoryId,
      accountId: _accountId!,
    );
    if (!mounted) return;
    _textCtrl.clear();
    _amountOverrideCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _type == TransactionType.gasto ? 'Gasto guardado.' : 'Ingreso guardado.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.watch<AppController>();
    final parsed = _parsed(c);
    final categories = c.categories.where((cat) => cat.appliesTo(_type)).toList();

    if (_accountId == null && c.accounts.isNotEmpty && !_accountAutoSelected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _accountId == null) setState(() => _accountId = c.accounts.first.id);
      });
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            'Nuevo movimiento',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Di algo como: «compra de un rastrillo Gillette de 25 pesos, tarjeta de crédito banco azteca». Todo se procesa en el teléfono.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 20),
          SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(
                value: TransactionType.gasto,
                label: Text('Gasto'),
                icon: Icon(Icons.remove_circle_outline),
              ),
              ButtonSegment(
                value: TransactionType.ingreso,
                label: Text('Ingreso'),
                icon: Icon(Icons.add_circle_outline),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (s) {
              setState(() {
                _type = s.first;
                _categoryId = null;
              });
              _onTextChanged();
            },
          ),
          const SizedBox(height: 24),
          Center(
            child: Semantics(
              button: true,
              label: _listening ? 'Detener dictado' : 'Iniciar dictado',
              child: Material(
                color: _listening
                    ? theme.colorScheme.error.withValues(alpha: 0.12)
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _speechReady ? _toggleListen : null,
                  child: SizedBox(
                    width: 112,
                    height: 112,
                    child: Icon(
                      _listening ? Icons.stop_rounded : Icons.mic_rounded,
                      size: 48,
                      color: _listening ? theme.colorScheme.error : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              !_speechReady
                  ? 'Permite el micrófono y el reconocimiento de voz en Ajustes.'
                  : _listening
                      ? 'Escuchando…'
                      : 'Pulsa para dictar',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _textCtrl,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Texto del movimiento',
              hintText: 'Ej.: 250 pesos de súper, tarjeta Nu Crédito',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountOverrideCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Importe manual (opcional)',
              hintText: 'Sobrescribe el importe detectado',
            ),
          ),
          const SizedBox(height: 16),
          if (parsed.amountCents != null)
            Text(
              'Detectado: ${formatMxnCents(parsed.amountCents!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 20),
          Text(
            'Cuenta o tarjeta',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (c.accounts.isEmpty)
            Text(
              'Da de alta una cuenta en la pestaña Cuentas primero.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: c.accounts.map((a) {
                final selected = _accountId == a.id;
                return ChoiceChip(
                  label: Text(a.name),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    _accountId = a.id;
                    _accountAutoSelected = true;
                  }),
                );
              }).toList(),
            ),
          const SizedBox(height: 20),
          Text(
            'Categoría',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...categories.map((cat) => _CategoryTile(
                category: cat,
                selected: _categoryId == cat.id,
                onTap: () => setState(() => _categoryId = cat.id),
              )),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Guardar movimiento'),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final CategoryModel category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? theme.colorScheme.primary.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  category.icon,
                  color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected) Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
