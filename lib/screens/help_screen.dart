import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar por voz con Siri')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(
              'iPhone: Atajo con frase personalizada',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Puedes decir “Oye Siri, Joel” (o el nombre que quieras) para dictar un '
              'movimiento sin abrir la app. Configúralo una sola vez en la app Atajos:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            const _Step(n: 1, text: 'Abre la app Atajos → “+” para crear un atajo nuevo.'),
            const _Step(n: 2, text: 'Agrega la acción “Dictar texto” (idioma: Español de México).'),
            const _Step(
              n: 3,
              text: 'Agrega la acción “Texto” y escribe:\n'
                  'controlgastos://movimiento?texto=[Texto dictado codificado]\n'
                  '(usa “Codificar URL” sobre el texto dictado antes de concatenarlo).',
            ),
            const _Step(n: 4, text: 'Agrega la acción “Abrir URLs” usando ese texto.'),
            const _Step(
              n: 5,
              text: 'En los ajustes del atajo (ícono ⓘ), toca “Añadir a Siri” y graba una '
                  'frase corta, por ejemplo “Joel”. A partir de ahí, “Oye Siri, Joel” abre '
                  'la app con el movimiento ya interpretado, listo para confirmar.',
            ),
            const _Step(
              n: 6,
              text: 'Repite el atajo con otro nombre (“Martha”, “Juan”…) si varias personas '
                  'de la casa quieren su propia frase — cada una abre el mismo flujo.',
            ),
            const SizedBox(height: 24),
            Text(
              'Android',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Google Assistant no permite hoy frases de invocación personalizadas para '
              'apps de terceros sin publicarla y verificarla con Google. Por ahora, en '
              'Android usa el botón de dictado dentro de la pestaña “Voz” de la app.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'La app nunca guarda un movimiento en silencio: aunque venga de un atajo de '
              'voz, siempre te muestra la pantalla de confirmación antes de guardar.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.text});

  final int n;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            child: Text(
              '$n',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
