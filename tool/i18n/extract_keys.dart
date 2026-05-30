// ignore_for_file: avoid_print
//
// אוסף את כל המחרוזות העטופות ב-`.tr()` תחת lib/ ומחולל תבנית תרגום
// `assets/translations/en.template.json` — מפה של כל מפתח עברי לתרגום שלו.
//
// מיזוג: אם `assets/translations/en.json` קיים, תרגומים שכבר מולאו נשמרים;
// מפתחות חדשים מקבלים ערך ריק "" (לסימון "טרם תורגם").
//
// שימוש:
//   dart run tool/i18n/extract_keys.dart            # כותב en.template.json
//   dart run tool/i18n/extract_keys.dart --count    # מספר המפתחות בלבד
//
// הלוגיקה (`extractKeysFromSource`) טהורה וניתנת לבדיקה ב-test/i18n/.

import 'dart:convert';
import 'dart:io';

const String libRootRelativePath = 'lib';
const String translationsDir = 'assets/translations';
const String enJsonPath = '$translationsDir/en.json';

/// התבנית היא ארטיפקט פיתוח (לא asset ריצה) ולכן נשמרת תחת tool/.
const String templateDir = 'tool/i18n';
const String templatePath = '$templateDir/en.template.json';

/// תו עברי בודד.
final RegExp _hebrewChar = RegExp(r'[֐-׿]');

/// מחרוזת literal בשורה אחת (גרשיים בודדים/כפולים) עם תפיסת escape.
final RegExp _stringLiteral = RegExp(
  '\'(?:\\\\.|[^\'\\\\\n])*\'|"(?:\\\\.|[^"\\\\\n])*"',
);

/// המרת escape-ים נפוצים לערך הסמנטי שישמש כמפתח JSON.
/// `\n`→שורה חדשה, `\t`→טאב, וכל `\x` אחר (כולל `\'`, `\"`, `\\`, `\$`)→`x`.
String _unescape(String inner) {
  return inner.replaceAllMapped(RegExp(r'\\(.)'), (m) {
    switch (m.group(1)) {
      case 'n':
        return '\n';
      case 't':
        return '\t';
      default:
        return m.group(1)!;
    }
  });
}

/// מחלץ את כל מפתחות ה-`.tr()` מתוך תוכן קובץ Dart בודד.
Set<String> extractKeysFromSource(String source) {
  final keys = <String>{};
  final lines = source.split('\n');

  // `dart format` עלול לשבור `'מחרוזת ארוכה'.tr()` — המחרוזת מסיימת שורה
  // ו-`.tr(` פותח את הבאה. נזהה גם מקרה זה כמפתח עטוף.
  bool trOnNextNonBlankLine(int i) {
    for (var j = i + 1; j < lines.length; j++) {
      final t = lines[j].trimLeft();
      if (t.isEmpty) continue;
      return t.startsWith('.tr(');
    }
    return false;
  }

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.trimLeft().startsWith('//')) continue;
    for (final m in _stringLiteral.allMatches(line)) {
      final after = line.substring(m.end).trimLeft();
      final wrapped =
          after.startsWith('.tr(') || (after.isEmpty && trOnNextNonBlankLine(i));
      if (!wrapped) continue;
      final literal = m.group(0)!;
      if (literal.length < 2) continue;
      final inner = _unescape(literal.substring(1, literal.length - 1));
      if (!_hebrewChar.hasMatch(inner)) continue;
      keys.add(inner);
    }
  }
  return keys;
}

/// מחלץ את כל מפתחות ה-`.tr()` תחת [root] (מדלג על `*.g.dart`).
Set<String> extractKeys(Directory root) {
  final keys = <String>{};
  if (!root.existsSync()) return keys;
  final files = root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'));
  for (final file in files) {
    keys.addAll(extractKeysFromSource(file.readAsStringSync()));
  }
  return keys;
}

Map<String, String> _loadExisting(String path) {
  final file = File(path);
  if (!file.existsSync()) return {};
  try {
    final decoded =
        json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v.toString()));
  } catch (_) {
    return {};
  }
}

void main(List<String> args) {
  final keys = extractKeys(Directory(libRootRelativePath)).toList()..sort();

  if (args.contains('--count')) {
    print(keys.length);
    return;
  }

  final existing = _loadExisting(enJsonPath);
  final template = <String, String>{};
  for (final key in keys) {
    template[key] = existing[key] ?? '';
  }

  const encoder = JsonEncoder.withIndent('  ');
  Directory(templateDir).createSync(recursive: true);
  File(templatePath).writeAsStringSync('${encoder.convert(template)}\n');

  final translated = template.values.where((v) => v.isNotEmpty).length;
  print('נכתב $templatePath');
  print('סה"כ מפתחות: ${keys.length} | מתורגמים: $translated | '
      'חסרים: ${keys.length - translated}');
}
