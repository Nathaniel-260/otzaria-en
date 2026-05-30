import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// שכבת תרגום עצמית בסגנון gettext עבור מחרוזות הממשק.
///
/// העיקרון: **המחרוזת העברית עצמה היא המפתח וגם ברירת המחדל.**
/// - עברית — אין קובץ תרגום; כל מחרוזת נופלת חזרה למפתח (העברית). לעולם לא ריק.
/// - שפה אחרת — נטען קובץ JSON שממפה `"עברית" → "תרגום"`.
///
/// המפה מוחזקת סטטית עבור ה-locale הנוכחי כדי שלא יידרש `context` בכל
/// קריאת `.tr()` — קריטי למיגרציה הדרגתית של מאות קבצים.
class AppTranslations {
  AppTranslations._();

  /// מפת התרגום של ה-locale הנוכחי. עברית = ריק (fallback למפתח).
  static Map<String, String> _current = const <String, String>{};

  /// קוד השפה הנוכחי בממשק (`he` / `en` ...).
  static String _languageCode = 'he';

  /// קוד השפה הנוכחי בממשק.
  static String get languageCode => _languageCode;

  /// כיוון הממשק הנגזר מהשפה הנוכחית: עברית → RTL, אנגלית → LTR.
  ///
  /// משמש להחלפת `TextDirection.rtl` קשיח בקוד הקיים בכיוון נגזר-locale,
  /// כדי שהממשק יתהפך אוטומטית בהחלפת שפה. נקרא בלי `context`.
  static TextDirection get textDirection =>
      _languageCode == 'he' ? TextDirection.rtl : TextDirection.ltr;

  /// השפות הנתמכות בממשק (עברית כברירת מחדל).
  static const List<String> supportedLanguages = <String>['he', 'en'];

  /// טוען את קובץ התרגום עבור [languageCode] ומעדכן את המפה הנוכחית.
  ///
  /// עברית — אין קובץ; המפה מתאפסת והכול נופל חזרה למפתח העברי.
  /// קובץ חסר/לא תקין — נשארים בעברית כדי לא לשבור את ה-UI.
  static Future<void> load(String languageCode) async {
    _languageCode = languageCode;
    if (languageCode == 'he') {
      _current = const <String, String>{};
      return;
    }
    try {
      final raw =
          await rootBundle.loadString('assets/translations/$languageCode.json');
      final decoded = json.decode(raw) as Map<String, dynamic>;
      _current = decoded.map(
        (key, value) => MapEntry(key, value.toString()),
      );
    } catch (e) {
      debugPrint('AppTranslations: failed to load "$languageCode": $e');
      _current = const <String, String>{};
    }
  }

  /// מתרגם את [key] לפי ה-locale הנוכחי.
  ///
  /// אם אין תרגום — מחזיר את המפתח עצמו (עברית), לעולם לא ריק.
  /// [args] ממלא placeholders בסגנון `{name}`.
  static String translate(String key, {Map<String, String>? args}) {
    var result = _current[key] ?? key;
    if (args != null) {
      args.forEach((name, value) {
        result = result.replaceAll('{$name}', value);
      });
    }
    return result;
  }

  /// ממיר קוד שפה ל-[Locale] עבור `MaterialApp`.
  static Locale localeFor(String languageCode) {
    switch (languageCode) {
      case 'en':
        return const Locale('en');
      case 'he':
      default:
        return const Locale('he', 'IL');
    }
  }
}
