import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central place for the app's language state.
///
/// easy_localization drives the actual UI translations, but non-widget code
/// (e.g. the Dio [ApiInterceptor]) has no BuildContext, so we also keep the
/// active language code here and persist it in SharedPreferences.
class LocaleService {
  static const String _prefsKey = 'app_lang';

  static const Locale english = Locale('en');
  static const Locale hindi = Locale('hi');
  static const Locale gujarati = Locale('gu');
  static const List<Locale> supportedLocales = [english, hindi, gujarati];
  static const Locale fallbackLocale = english;

  static const List<String> _codes = ['en', 'hi', 'gu'];

  /// Current language code (en/hi/gu). Read by the API interceptor for the
  /// `Accept-Language` header.
  static String currentCode = 'en';

  /// Loads the saved language code before the app builds. Returns the locale
  /// to start easy_localization with.
  static Future<Locale> loadStartLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefsKey);
      if (code != null && _codes.contains(code)) {
        currentCode = code;
      }
    } catch (_) {}
    return Locale(currentCode);
  }

  /// Switches the app language: updates the UI, keeps [currentCode] in sync and
  /// persists the choice so it survives relaunch.
  static Future<void> setLanguage(BuildContext context, String code) async {
    final safe = _codes.contains(code) ? code : 'en';
    currentCode = safe;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, safe);
    } catch (_) {}
    if (context.mounted) {
      await context.setLocale(Locale(safe));
    }
  }

  /// Native label for a language code (always shown in its own script).
  static String nativeLabel(String code) {
    switch (code) {
      case 'hi':
        return 'हिन्दी';
      case 'gu':
        return 'ગુજરાતી';
      default:
        return 'English';
    }
  }
}
