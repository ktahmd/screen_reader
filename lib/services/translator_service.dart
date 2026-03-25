import 'package:translator/translator.dart';

class TranslationService {
  final GoogleTranslator _translator = GoogleTranslator();

  /// Translates a given text.
  /// Defaults: English ('en') to Arabic ('ar')
  Future<String> translateText(String text, {String from = 'en', String to = 'ar'}) async {
    try {
      if (text.trim().isEmpty) return "";
      
      final translation = await _translator.translate(text, from: from, to: to);
      return translation.text;
    } catch (e) {
      throw ("Translation failed. Check connection or API limits.");
    }
  }
}