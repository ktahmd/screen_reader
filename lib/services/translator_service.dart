import 'package:translator/translator.dart';

class TranslationService {
  static final GoogleTranslator _translator = GoogleTranslator();

  /// Translates a given text.
  /// Defaults: English ('en') to Arabic ('ar')
  static Future<String> translateText(String text, {String from = 'en', String to = 'ar'}) async {
    try {
      if (text.trim().isEmpty) return "";
      
      final translation = await _translator.translate(text, from: from, to: to);
      return translation.text;
    } catch (e) {
      return "Translation error. Please check your connection.";
    }
  }
}