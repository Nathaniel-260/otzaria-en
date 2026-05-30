import 'package:flutter_test/flutter_test.dart';

import '../../tool/i18n/extract_keys.dart';

void main() {
  group('extractKeysFromSource', () {
    test('מחלץ מפתח עברי עטוף ב-.tr()', () {
      final keys = extractKeysFromSource("Text('שמור'.tr());");
      expect(keys, {'שמור'});
    });

    test('מתעלם ממחרוזת עברית לא-עטופה', () {
      final keys = extractKeysFromSource("Text('שמור');");
      expect(keys, isEmpty);
    });

    test('מתעלם ממחרוזת עטופה לא-עברית', () {
      final keys = extractKeysFromSource("Text('save'.tr());");
      expect(keys, isEmpty);
    });

    test('מחלץ כמה מפתחות וממזג כפילויות', () {
      final keys = extractKeysFromSource(
        "a('שמור'.tr()); b('ביטול'.tr()); c('שמור'.tr());",
      );
      expect(keys, {'שמור', 'ביטול'});
    });

    test('מטפל ב-.tr() עם args', () {
      final keys =
          extractKeysFromSource("Text('נמצאו {n}'.tr(args: {'n': '1'}));");
      expect(keys, {'נמצאו {n}'});
    });

    test('מבצע unescape לגרש מוברח', () {
      final keys = extractKeysFromSource(r"Text('אות \'א\''.tr());");
      expect(keys, {"אות 'א'"});
    });

    test('מחלץ מפתח כש-.tr() נשבר לשורה הבאה', () {
      final keys =
          extractKeysFromSource("Text(\n  'מחרוזת ארוכה'\n      .tr(),\n);");
      expect(keys, {'מחרוזת ארוכה'});
    });
  });
}
