import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/localization/app_language.dart';

class LanguageProvider extends ChangeNotifier {
  static const _preferenceKey = 'app_language';

  LanguageProvider(this._preferences) {
    _languageCode =
        _preferences.getString(_preferenceKey) ?? AppLanguage.english;
  }

  final SharedPreferences _preferences;
  late String _languageCode;

  String get languageCode => _languageCode;
  Locale get locale => _languageCode == AppLanguage.cantonese
      ? const Locale('zh', 'HK')
      : const Locale('en');
  bool get isCantonese => _languageCode == AppLanguage.cantonese;

  Future<void> setLanguage(String languageCode) async {
    if (languageCode != AppLanguage.english &&
        languageCode != AppLanguage.cantonese) {
      return;
    }
    if (_languageCode == languageCode) return;
    _languageCode = languageCode;
    notifyListeners();
    await _preferences.setString(_preferenceKey, languageCode);
  }
}
