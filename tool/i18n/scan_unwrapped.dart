// ignore_for_file: avoid_print
//
// סורק את כל קבצי ה-Dart תחת lib/ ומדווח על מחרוזות literal עבריות
// שאינן עטופות ב-`.tr()` — מחרוזות ממשק שטרם עברו מיגרציה ל-i18n.
//
// שימוש:
//   dart run tool/i18n/scan_unwrapped.dart            # דוח מפורט לכל קובץ
//   dart run tool/i18n/scan_unwrapped.dart --count    # מספר כולל בלבד
//   dart run tool/i18n/scan_unwrapped.dart --check    # משווה ל-baseline; exit 1 אם המספר עלה
//   dart run tool/i18n/scan_unwrapped.dart --write-baseline  # שומר את המספר הנוכחי כ-baseline
//
// הלוגיקה (`scanSource`) טהורה וניתנת לבדיקה ב-test/i18n/.
// היא לא מנתח Dart מלא — היוריסטיקה מבוססת regex שמספיקה ל-ratchet
// (העיקר: דטרמיניסטית, ושהמספר רק יורד עם הזמן).

import 'dart:io';

/// תיקיית השורש שנסרקת.
const String libRootRelativePath = 'lib';

/// קובץ ה-baseline (מספר ה-literals הלא-עטופים שאסור לעלות מעליו).
const String baselineRelativePath = 'tool/i18n/baseline.txt';

/// תו עברי בודד (טווח Unicode של עברית).
final RegExp _hebrewChar = RegExp(r'[֐-׿]');

/// מחרוזת literal ב-Dart בגרשיים בודדים או כפולים, בשורה אחת.
/// תופסת escape פנימי (`\'`, `\\` וכו'). לא תופסת מחרוזות רב-שורתיות.
final RegExp _stringLiteral = RegExp(
  '\'(?:\\\\.|[^\'\\\\\n])*\'|"(?:\\\\.|[^"\\\\\n])*"',
);

/// סימן אינטרפולציה לא-escaped (`\$var` / `\${...}`).
final RegExp _interpolation = RegExp(r'(?<!\\)\$');

/// ממצא בודד: מחרוזת עברית לא-עטופה.
class Finding {
  final int line;
  final String value;
  final bool isInterpolation;

  const Finding(this.line, this.value, this.isInterpolation);
}

/// תוצאת סריקה של קובץ בודד.
class FileScanResult {
  final List<Finding> findings;

  const FileScanResult(this.findings);

  int get count => findings.length;

  int get interpolationCount => findings.where((f) => f.isInterpolation).length;
}

/// בודק אם השורה היא הקשר שאין לעטוף בו (לוג / import / annotation).
bool _isExcludedContext(String trimmed) {
  return trimmed.startsWith('import ') ||
      trimmed.startsWith('export ') ||
      trimmed.startsWith('part ') ||
      trimmed.startsWith('library ') ||
      trimmed.startsWith('@') ||
      trimmed.contains('debugPrint(') ||
      trimmed.contains('developer.log(') ||
      trimmed.contains('// i18n-ignore');
}

/// סורק תוכן של קובץ Dart ומחזיר את כל המחרוזות העבריות שאינן עטופות
/// ב-`.tr()`. מחרוזות עם אינטרפולציה (`$var`) מסומנות בנפרד — הן דורשות
/// המרה ידנית ל-`{name}` ולא עטיפה אוטומטית.
FileScanResult scanSource(String source) {
  final findings = <Finding>[];
  final lines = source.split('\n');
  var inBlockComment = false;

  // `dart format` עלול לשבור `'מחרוזת ארוכה'.tr()` לשתי שורות — המחרוזת
  // מסיימת שורה אחת ו-`.tr(` פותח את השורה הבאה. נחשיב זאת כעטוף.
  bool trOnNextNonBlankLine(int i) {
    for (var j = i + 1; j < lines.length; j++) {
      final t = lines[j].trimLeft();
      if (t.isEmpty) continue;
      return t.startsWith('.tr(');
    }
    return false;
  }

  for (var i = 0; i < lines.length; i++) {
    final raw = lines[i];
    final trimmed = raw.trimLeft();

    // בלוק הערה /* ... */
    if (inBlockComment) {
      if (trimmed.contains('*/')) inBlockComment = false;
      continue;
    }
    if (trimmed.startsWith('/*')) {
      if (!trimmed.contains('*/')) inBlockComment = true;
      continue;
    }

    // הערת שורה
    if (trimmed.startsWith('//') || trimmed.startsWith('///')) continue;

    // הקשר מוחרג (לוג / import / annotation)
    if (_isExcludedContext(trimmed)) continue;

    for (final m in _stringLiteral.allMatches(raw)) {
      final literal = m.group(0)!;
      if (literal.length < 2) continue;
      final inner = literal.substring(1, literal.length - 1);

      // רק מחרוזות שמכילות עברית
      if (!_hebrewChar.hasMatch(inner)) continue;

      // כבר עטוף ב-.tr()? בודקים מה בא אחרי הגרש הסוגר.
      final after = raw.substring(m.end).trimLeft();
      if (after.startsWith('.tr(')) continue;
      // מחרוזת שמסיימת שורה ו-.tr( ממשיך בשורה הבאה (שבירת format).
      if (after.isEmpty && trOnNextNonBlankLine(i)) continue;

      final isInterp = _interpolation.hasMatch(inner);
      findings.add(Finding(i + 1, literal, isInterp));
    }
  }

  return FileScanResult(findings);
}

/// סורק את כל קבצי ה-Dart תחת [root] (פרט לקבצים מחוללים `*.g.dart`).
/// מחזיר מפה: נתיב קובץ יחסי → תוצאת סריקה (רק קבצים עם ממצאים).
Map<String, FileScanResult> scanDirectory(Directory root) {
  final results = <String, FileScanResult>{};
  if (!root.existsSync()) return results;

  final files = root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.endsWith('.g.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final result = scanSource(file.readAsStringSync());
    if (result.count > 0) {
      results[file.path.replaceAll('\\', '/')] = result;
    }
  }
  return results;
}

/// סופר את סך כל ה-literals הלא-עטופים תחת [root].
int totalUnwrapped(Map<String, FileScanResult> results) =>
    results.values.fold(0, (sum, r) => sum + r.count);

int _readBaseline() {
  final file = File(baselineRelativePath);
  if (!file.existsSync()) return -1;
  return int.tryParse(file.readAsStringSync().trim()) ?? -1;
}

void main(List<String> args) {
  final root = Directory(libRootRelativePath);
  if (!root.existsSync()) {
    stderr.writeln('lib/ directory not found at $libRootRelativePath');
    exit(2);
  }

  final results = scanDirectory(root);
  final total = totalUnwrapped(results);
  final interp =
      results.values.fold<int>(0, (s, r) => s + r.interpolationCount);

  if (args.contains('--count')) {
    print(total);
    return;
  }

  if (args.contains('--write-baseline')) {
    File(baselineRelativePath).writeAsStringSync('$total\n');
    print('Baseline written: $total');
    return;
  }

  if (args.contains('--check')) {
    final baseline = _readBaseline();
    if (baseline < 0) {
      stderr.writeln(
          'No baseline found at $baselineRelativePath. Run with --write-baseline first.');
      exit(2);
    }
    if (total > baseline) {
      stderr.writeln(
          '❌ literals עבריים לא-עטופים עלו: $total > baseline $baseline.\n'
          'שורות חדשות עם טקסט ממשק עברי חייבות להיעטף ב-.tr().');
      exit(1);
    }
    print('✅ unwrapped=$total <= baseline=$baseline');
    if (total < baseline) {
      print('💡 ירד מתחת ל-baseline — אפשר לעדכן: '
          'dart run tool/i18n/scan_unwrapped.dart --write-baseline');
    }
    return;
  }

  // דוח מפורט
  for (final entry in results.entries) {
    print('${entry.key}: ${entry.value.count} '
        '(אינטרפולציה: ${entry.value.interpolationCount})');
  }
  print('');
  print('סה"כ קבצים עם ממצאים: ${results.length}');
  print('סה"כ literals עבריים לא-עטופים: $total');
  print('מתוכם עם אינטרפולציה (דורש המרה ידנית ל-{name}): $interp');
}
