import 'package:otzaria/l10n/app_translations.dart';

/// הרחבה על [String] לתרגום מחרוזות ממשק בסגנון gettext.
///
/// המחרוזת העברית היא המפתח — בלי תרגום מקבלים אותה בחזרה (לעולם לא ריק):
/// ```dart
/// Text('שמור'.tr())                                   // פשוט
/// Text('נמצאו {count} תוצאות'.tr(args: {'count': '$n'})) // עם פרמטרים
/// ```
extension TrExtension on String {
  /// מתרגם את המחרוזת לפי שפת הממשק הנוכחית.
  ///
  /// [args] ממלא placeholders בסגנון `{name}`.
  String tr({Map<String, String>? args}) =>
      AppTranslations.translate(this, args: args);
}
