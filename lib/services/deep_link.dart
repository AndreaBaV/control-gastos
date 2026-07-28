/// Extrae el texto dictado de un link `controlgastos://movimiento?texto=...`
/// (el que genera el Atajo de Siri). Devuelve null si el link no aplica.
String? voiceTextFromDeepLink(Uri? uri) {
  if (uri == null) return null;
  if (uri.scheme != 'controlgastos' || uri.host != 'movimiento') return null;
  final texto = uri.queryParameters['texto'];
  if (texto == null || texto.trim().isEmpty) return null;
  return texto;
}
