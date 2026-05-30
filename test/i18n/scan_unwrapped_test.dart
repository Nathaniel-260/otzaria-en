import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/i18n/scan_unwrapped.dart';

void main() {
  group('scanSource', () {
    test('מזהה מחרוזת עברית לא-עטופה', () {
      final r = scanSource("Text('שלום');");
      expect(r.count, 1);
      expect(r.findings.first.isInterpolation, isFalse);
    });

    test('מתעלם ממחרוזת עטופה ב-.tr()', () {
      final r = scanSource("Text('שלום'.tr());");
      expect(r.count, 0);
    });

    test('מתעלם ממחרוזת עטופה ב-.tr() עם args', () {
      final r = scanSource("Text('שלום {n}'.tr(args: {'n': '1'}));");
      expect(r.count, 0);
    });

    test('מסמן אינטרפולציה בנפרד', () {
      final r = scanSource(r"Text('נמצאו $count תוצאות');");
      expect(r.count, 1);
      expect(r.findings.first.isInterpolation, isTrue);
    });

    test('מתעלם ממחרוזות לא-עבריות', () {
      final r = scanSource("Text('hello world');");
      expect(r.count, 0);
    });

    test('מתעלם מהערת שורה', () {
      final r = scanSource("// הערה בעברית עם 'מחרוזת'");
      expect(r.count, 0);
    });

    test('מתעלם מ-import/export', () {
      expect(scanSource("import 'package:foo/בדיקה.dart';").count, 0);
      expect(scanSource("export 'package:foo/בדיקה.dart';").count, 0);
    });

    test('מתעלם מ-debugPrint', () {
      final r = scanSource("debugPrint('שגיאה כלשהי');");
      expect(r.count, 0);
    });

    test('מתעלם מ-i18n-ignore', () {
      final r = scanSource("const s = 'התעלם'; // i18n-ignore");
      expect(r.count, 0);
    });

    test('סופר כמה מחרוזות באותה שורה', () {
      final r = scanSource("foo('אחד', 'שתיים');");
      expect(r.count, 2);
    });

    test('מתעלם ממחרוזת עטופה כש-.tr() נשבר לשורה הבאה', () {
      final r = scanSource("Text(\n  'מחרוזת ארוכה'\n      .tr(),\n);");
      expect(r.count, 0);
    });

    test('מחרוזת שמסיימת שורה ללא .tr() עדיין נספרת', () {
      final r = scanSource("final x = 'עברית'\n    .toUpperCase();");
      expect(r.count, 1);
    });
  });

  group('ratchet — literals עבריים לא-עטופים לא עולים מעל baseline', () {
    test('סך הכול תחת lib/ <= baseline', () {
      final baselineFile = File(baselineRelativePath);
      expect(
        baselineFile.existsSync(),
        isTrue,
        reason: 'חסר baseline — הרץ: '
            'dart run tool/i18n/scan_unwrapped.dart --write-baseline',
      );
      final baseline = int.parse(baselineFile.readAsStringSync().trim());

      final results = scanDirectory(Directory(libRootRelativePath));
      final total = totalUnwrapped(results);

      expect(
        total,
        lessThanOrEqualTo(baseline),
        reason: 'שורות חדשות עם טקסט ממשק עברי חייבות להיעטף ב-.tr() '
            '(נוכחי=$total, baseline=$baseline). אם ההפחתה מכוונת — '
            'עדכן baseline עם --write-baseline.',
      );
    });
  });
}
