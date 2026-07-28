import '../models/category_model.dart';

class CategorizationService {
  static const Map<String, List<String>> _keywords = {
    'cat_food': [
      'comida',
      'super',
      'mercado',
      'restaurante',
      'café',
      'cafe',
      'bar',
      'cenar',
      'cena',
      'almuerzo',
      'desayuno',
      'pan',
      'fruta',
      'verdura',
    ],
    'cat_transport': [
      'taxi',
      'uber',
      'cabify',
      'bolt',
      'gasolina',
      'gasol',
      'diesel',
      'parking',
      'aparcamiento',
      'metro',
      'bus',
      'autobús',
      'tren',
      'billete',
      'peaje',
      'itv',
      'taller',
    ],
    'cat_home': [
      'casa',
      'luz',
      'agua',
      'gas',
      'internet',
      'wifi',
      'alquiler',
      'hipoteca',
      'comunidad',
      'seguro hogar',
      'hogar',
    ],
    'cat_fun': [
      'ocio',
      'cine',
      'netflix',
      'spotify',
      'juego',
      'concierto',
      'teatro',
      'viaje',
      'hotel',
    ],
    'cat_health': [
      'farmacia',
      'médico',
      'medico',
      'dentista',
      'gimnasio',
      'salud',
      'mutua',
      'seguro salud',
    ],
    'cat_shopping': [
      'ropa',
      'zapatos',
      'amazon',
      'regalo',
      'electrónica',
      'electronica',
      'compras',
    ],
  };

  static String suggestCategoryId(String text, List<CategoryModel> categories) {
    final t = text.toLowerCase();
    var bestId = 'cat_other';
    var bestScore = 0;
    for (final e in _keywords.entries) {
      for (final kw in e.value) {
        if (t.contains(kw) && kw.length > bestScore) {
          bestScore = kw.length;
          bestId = e.key;
        }
      }
    }
    if (categories.any((c) => c.id == bestId)) return bestId;
    for (final c in categories) {
      if (c.id == 'cat_other') return c.id;
    }
    return categories.first.id;
  }
}
