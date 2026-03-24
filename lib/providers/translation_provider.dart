import 'package:flutter/material.dart';

class TranslationProvider extends ChangeNotifier {
  //default languages can be changed by user in the future
  //TODO: shared preferences can be used to persist user choices in the future
  String _sourceLang = "English";
  String _targetLang = "Arabic";

  String get sourceLang => _sourceLang;
  String get targetLang => _targetLang;

  String get sourceLangCode => _getLangCode(_sourceLang);
  String get targetLangCode => _getLangCode(_targetLang);

  void setSourceLanguage(String lang) {
    _sourceLang = lang;
    notifyListeners();
  }

  void setTargetLanguage(String lang) {
    _targetLang = lang;
    notifyListeners();
  }

  void swapLanguages() {
    final temp = _sourceLang;
    _sourceLang = _targetLang;
    _targetLang = temp;
    notifyListeners();
  }

  //TODO: constant map can be moved to app constants if needed in the future
  String _getLangCode(String languageName) {
    switch (languageName) {
      case "Arabic": return "ar";
      case "Spanish": return "es";
      case "French": return "fr";
      case "German": return "de";
      case "Japanese": return "ja";
      case "Korean": return "ko";
      case "Chinese": return "zh-cn";
      case "English": 
      default: return "en";
    }
  }
}