# תוכנית עבודה: תמיכה רב-לשונית (i18n) באוצריא

> **קובץ זה הוא מקור האמת לכל המשימה.** כל סשן עבודה מתחיל בקריאת הקובץ הזה מתחילתו ומסתיים בעדכון "יומן ההתקדמות" שבסופו.

---

## 0. הוראות ל-AI (קרא בכל סשן)

1. **ענה ועבוד בעברית** — לפי `CLAUDE.md`.
2. **קרא קובץ זה במלואו** לפני שאתה נוגע בקוד. אתר את השלב הראשון שעדיין `⬜ פתוח` ביומן ההתקדמות (סעיף 9) — שם אתה ממשיך.
3. **עבוד שלב אחד / batch אחד בכל פעם.** אל תיקח שלב חדש לפני שהקודם סומן `✅ הושלם` ביומן.
4. **בסיום כל batch — חובה, בסדר הזה:**
   - `flutter analyze` → אפס שגיאות/אזהרות.
   - `dart run tool/i18n/extract_keys.dart` → מלא `en.json` עד "חסרים: 0".
   - `flutter test` על הקבצים הרלוונטיים בלבד (ראה מפת הטסטים ב-`CLAUDE.md`).
   - `dart format` על הקבצים ששינית בלבד.
   - עדכן את **יומן ההתקדמות** (סעיף 9): סמן צ'קבוקסים, כתוב מה עשית, כמה קבצים, ותאריך.
5. **אל תשבור את ה-fallback לעברית.** מחרוזת שלא עטופה ב-`.tr()` חייבת להמשיך להציג עברית. אסור שתופיע מחרוזת ריקה אי-פעם.
6. **תרגם במקביל לעטיפה** (עודכן 2026-05-29 לבקשת המשתמש — מבטל את ההנחה הקודמת של "תרגום בסוף"). בכל batch, אחרי עטיפת המחרוזות: הרץ `dart run tool/i18n/extract_keys.dart`, ומלא ב-`assets/translations/en.json` תרגום אנגלי אמיתי לכל מפתח חדש. יעד: `extract_keys` תמיד מדווח "חסרים: 0". שמור על placeholders (`{name}`) ו-`\n` בתרגום.
7. **PR-ים קטנים** — feature אחד לכל PR. אל תיצור PR ענק אחד.
8. אם אתה תקוע או מגלה שההנחה בקובץ שגויה — **עצור, עדכן את הקובץ, ושאל את המשתמש** בהודעה אחת עם כל מה שחסר.

---

## 1. המטרה

לאפשר החלפת שפת הממשק (לא תוכן הספרים) — עברית כברירת מחדל, אנגלית/צרפתית כתוספת — בלי לפגוע בקריאוּת הקוד ובלי PR ענק אחד.

**לא בהיקף:** תרגום תוכן הספרים עצמם. רק מחרוזות הממשק (כפתורים, תפריטים, דיאלוגים, הודעות, settings).

---

## 2. ההחלטה הארכיטקטונית: gettext-style

**המחרוזת העברית עצמה היא המפתח וגם ברירת המחדל.**

```dart
Text('שמור'.tr())   // עברית: אין קובץ → נופל חזרה למפתח "שמור"
                     // אנגלית: מחפש "שמור" בקובץ → "Save"
```

קובץ תרגום (אנגלית בלבד — אין קובץ עברית):
```json
{ "שמור": "Save", "ביטול": "Cancel" }
```

**למה זה נבחר (ולא ARB/intl הסטנדרטי):**
- הקוד נשאר קריא בעברית — המפתח *הוא* הטקסט העברי, לא `key_4821`.
- אין בעיית "מפתח חסר": בלי תרגום מקבלים את המפתח (עברית), לעולם לא ריק.
- מיגרציה הדרגתית: כל מחרוזת לא-עטופה פשוט נשארת עברית. אין רגע "שבור".
- ניתן למצוא מה שנותר ברג'קס: literal עברי שלא עטוף ב-`.tr()`.

---

## 3. ה-API (חוזה קבוע — אל תשנה אחרי שלב 0)

```dart
'שמור'.tr()                                  // פשוט
'נמצאו {count} תוצאות'.tr(args: {'count': '$n'})  // עם פרמטרים
```

- Extension על `String` בשם `.tr()`.
- מחזיק מפה סטטית של ה-locale הנוכחי (singleton), מתעדכן בהחלפת שפה — **כדי שלא צריך `context` בכל call site** (קריטי למיגרציה של 297 קבצים).
- פרמטרים: placeholder בסגנון `{name}` שמוחלף מ-`args`.

### 3.1 טיפול באינטרפולציה (החלק העדין)
מחרוזת עם `$var` **לא יכולה** להיות מפתח סטטי. ההמרה:
```dart
// לפני:
Text('נמצאו $count תוצאות')
// אחרי:
Text('נמצאו {count} תוצאות'.tr(args: {'count': '$count'}))
```
הסקריפט (שלב 1) חייב **לסמן** מחרוזות אינטרפולציה בנפרד — הן דורשות עריכה ידנית, לא עטיפה אוטומטית.

### 3.2 מה *לא* עוטפים
- מחרוזות לוג/`debugPrint`, מפתחות פנימיים, שמות נתיבים, מזהי assets.
- מחרוזות תוכן ספרים.
- מחרוזות באורך תו אחד / סימני פיסוק.
- כל מה שלא נראה למשתמש ב-UI.

---

## 4. מבנה קבצים (ייווצר בשלב 0)

```
assets/translations/
  en.json            # אנגלית (נטען בזמן ריצה; רשום ב-pubspec)
  fr.json            # צרפתית (בהמשך)
lib/l10n/
  app_translations.dart   # ה-singleton + טעינת JSON + localeFor
  tr_extension.dart       # extension .tr() על String
                          # (delegate לא נדרש — ה-SettingsBloc טוען לפני emit)
tool/i18n/
  scan_unwrapped.dart     # סורק literals עבריים לא-עטופים (+ baseline/ratchet)
  extract_keys.dart       # מחלץ מפתחות עטופים → en.template.json
  baseline.txt            # מספר ה-literals הלא-עטופים (ratchet)
  en.template.json        # תבנית מלאה לכל המפתחות (ארטיפקט פיתוח, לא ב-bundle)
```

---

## 5. נקודות עיגון קיימות בקוד

| מה | איפה |
|---|---|
| `MaterialApp` (locale קשיח `he-IL`) | `lib/app.dart:57-68` |
| נקודת כניסה | `lib/main.dart`, `lib/app.dart` |
| Settings (אין עדיין הגדרת שפה) | `lib/settings/` |
| סקריפטים | `tool/` |
| הודעות משתמש | `lib/core/ui_snack.dart` |

---

## 6. RTL / LTR

- ה-`MaterialApp` קובע כיוון ambient נכון לפי ה-locale (עברית→RTL, אנגלית→LTR) דרך `GlobalWidgetsLocalizations`.
- **⚠️ הנחה קודמת שהתבררה כשגויה (QA 2026-05-29):** הכיוון **לא** נגזר אוטומטית בפועל. בקוד הקיים יש **436 מופעי `TextDirection.rtl` קשיחים ב-113 קבצים** (33 עוטפי `Directionality` מבניים + ~400 על `Text`/`Row`) שגוברים על ה-locale. בלי תיקונם, בחירת אנגלית מציגה טקסט אנגלי בפריסת RTL.
- **הפתרון שנבחר (תשתית + תיקון הדרגתי לפי שלב):**
  - תשתית: `AppTranslations.textDirection` (getter נגזר-locale: `he`→rtl, אחרת→ltr).
  - בכל שלב מיגרציה: להמיר `Directionality(textDirection: TextDirection.rtl)` ו-`textDirection: TextDirection.rtl` על ווידג'טי **ממשק** → `AppTranslations.textDirection`.
  - **חריג — תוכן:** מחרוזת שהיא תוכן עברי (כותרת ספר, מטא-דאטה, ציטוט) נשארת `TextDirection.rtl` קשיח תמיד (סעיף 3.2). רק chrome/labels של הממשק מתהפכים.
- **זהו החסם האמיתי** (לפי @asz, מפתח) — לא טכנולוגיית התרגום. לכן ההדגמה החזותית היא שער שלב 0 (ראה שלב 0).
- **החלטת מוצר פתוחה:** במסך עיון, באנגלית — ניווט בימין (כמו עברית) או בשמאל (כמו אנגלית)? להחליט במסגרת אישור הדגמת שלב 0, לפני מיגרציה המונית.

### הקשר ארגוני (מהדיון בפורום)
- בעלים (@י.-פל., #37): כרגע **לא ימוזג ל-upstream** — לכל היותר fork. הסיבה: "אחרי שקיבלתי משהו אני צריך לתמוך בו". לנהל ציפיות — ייתכן שזו עבודה ל-fork.
- הצוות (@הבל-הבלים, #35): נוטה להכריז "אין תמיכה רשמית", אך פתוח לגישת gettext (עברית קשיחה כברירת מחדל, אנגלית נמשכת מקבצים) — תואם בדיוק את סעיף 2.

---

## 7. שמירה מפני רגרסיה (ratchet)

אחרי שלב 1: טסט/סקריפט ב-CI שסופר literals עבריים לא-עטופים. אם המספר **עולה** מעל baseline — נכשל. כך שורות חדשות חייבות להיעטף, והמספר רק יורד.

---

## 8. השלבים

> כל שלב = batch אחד או יותר. סמן ביומן (סעיף 9).

### שלב 0 — תשתית + הדגמה להחלטה (שער חוסם)
> **תנאי-סף של @asz (#30):** לפני כל מיגרציה המונית (שלבים 2+) חייבת להיות הדגמה *שניתן להציג לצוות* — LTR עובד + עמוד settings אחד מתורגם במלואו — כדי שאפשר יהיה לראות בעיניים איך התוכנה נראית באנגלית ולהחליט. **אסור להתחיל שלב 2 לפני שהצוות אישר את המראה.** החסם האמיתי הוא RTL→LTR, לא טכנולוגיית התרגום.

- [x] להחליט: שכבה עצמית דקה (מומלץ) או `easy_localization`. ברירת מחדל: **שכבה עצמית דקה**.
- [x] ליצור `lib/l10n/` (singleton, extension `.tr()`, delegate).
- [x] לחבר ל-`MaterialApp` ב-`lib/app.dart`: `supportedLocales` (he/en), `localizationsDelegates`, `locale` נשלט מ-settings.
- [x] הגדרת שפה ב-settings (`SegmentedSettingsTile` — עברית/English), נשמר ב-`settings_repository`.
- [x] **LTR:** באנגלית כיוון הממשק מתהפך אוטומטית דרך ה-locale (`Directionality`). לוודא שהמסך הראשי ועמוד ה-settings לא נשברים.
- [x] `assets/translations/en.json` + רישום ב-`pubspec.yaml`.
- [x] **התוצר להחלטה:** עמוד settings אחד מתורגם **במלואו** לאנגלית + LTR, להציג לצוות. רק אחרי אישור — להמשיך לשלב 1+.

### שלב 1 — כלי עבודה
- [x] `tool/i18n/scan_unwrapped.dart` — מדפיס דוח: לכל קובץ, כמה literals עבריים לא-עטופים, ומסמן אינטרפולציה. תומך ב-`--count` / `--check` / `--write-baseline`.
- [x] `tool/i18n/extract_keys.dart` — אוסף כל `.tr()` → `tool/i18n/en.template.json` (ממוזג עם `en.json` הקיים).
- [x] להריץ scan, לשמור baseline ביומן (מספר התחלתי): **7636** (`tool/i18n/baseline.txt`).
- [x] טסט CI ratchet (סעיף 7) — `test/i18n/scan_unwrapped_test.dart` + `extract_keys_test.dart`.

### שלבי מיגרציה (לפי נראוּת למשתמש)
- [ ] שלב 2 — Settings (`lib/settings/`)
- [ ] שלב 3 — תפריט ראשי + סרגל עליון (`app_menu`, `app_top_bar`)
- [ ] שלב 4 — דיאלוגים + `UiSnack` (`lib/widgets/`, `lib/core/ui_snack.dart`)
- [x] שלב 5 — חיפוש (`lib/search/`)
- [ ] שלב 6 — מסך עיון / text_book (`lib/text_book/`)
- [ ] שלב 7 — PDF + הדפסה (`lib/pdf_book/`, `lib/printing/`)
- [ ] שלב 8 — שאר ה-features (bookmarks, history, personal_notes, library, plugins…)

### שלב 9 — מילוי תרגום + ליטוש
- [ ] למלא `en.json` (אפשר AI על התבנית).
- [ ] החלטת RTL/LTR למסך עיון (סעיף 6) + תיקוני כיווניות נקודתיים.
- [ ] scan סופי: 0 literals לא-עטופים שנראים למשתמש.
- [ ] (אופציונלי) `fr.json`.

---

## 9. יומן התקדמות (ה-AI מעדכן בכל batch)

> פורמט: סטטוס · תאריך · מה נעשה · קבצים · הערות. סטטוסים: `⬜ פתוח` · `🟡 בעבודה` · `✅ הושלם`.

| שלב | סטטוס | תאריך | מה נעשה / הערות |
|---|---|---|---|
| 0 — תשתית | ✅ הושלם | 2026-05-29 | נבחרה שכבה עצמית דקה. הדגמה מוכנה להצגה — ממתין לאישור הצוות לפני שלב 1+ |
| 1 — כלי עבודה | ✅ הושלם | 2026-05-29 | baseline (literals לא-עטופים): **7636** (273 קבצים, 509 אינטרפולציה). scan+extract+ratchet test מוכנים |
| 2 — Settings | ✅ הושלם | 2026-05-29 | **כל `lib/settings/` מוגר** — dialogs, view, search, כל ה-panels, כל ה-tabs, כל ה-services. עטיפה + המרת RTL→LTR (`AppTranslations.textDirection`) + **תרגום מלא ל-en.json** (552 מפתחות, 0 חסרים). baseline 7636→**7037**. `flutter analyze` נקי, 116 טסטים (i18n+settings) עברו. נותר תוכן (פסוקים/הנצחות/שמות) כ-rtl במכוון. **לא בוצע קומיט** — לבקשת המשתמש |
| 3 — תפריט/סרגל | ✅ הושלם | 2026-05-29 | ליבה: `main_window_screen`, `custom_title_bar`, `window_controls`, `app_popup_menu`. + ווידג'טים: `favorites_screen`, `commentators_filter_header/button`, `scrollable_tab_bar`, `responsive_action_bar`, `search_pane_base`, `app_dropdown_field`. תרגום en.json **588** (0 חסרים). baseline 7037→**6974**. analyze נקי, טסטים עברו. `app_top_bar` מבני (אין UI) |
| 4 — דיאלוגים/Snack | ✅ הושלם | 2026-05-29 | `core/ui_snack` (11 קבועים → getters עם `.tr()` + כיוון toast נגזר-locale), `app_dialogs`/`confirmation_dialog`/`input_dialog`/`selection_dialog` (תצוגת title/content/buttons עטופה `.tr()` כרשת ביטחון לכל הדיאלוגים), `error_report_sender_email`, `zip_extraction_progress`, `ad_popup` (chrome; שמות ארגונים=תוכן), `action_buttons`. en.json **623** (0 חסרים). baseline 6984→**6932**. analyze נקי, 22 טסטי dialog+i18n עברו |
| 5 — חיפוש | ✅ הושלם | 2026-05-30 | **כל `lib/search/view/` + `bloc/search_bloc` מוגרו.** tantivy_search_results, tantivy_full_text_search, search_dialog, category_tree_selector, search_edit_panel, full_text_facet_filtering, enhanced_search_field, full_text_settings_widgets, advanced_search_controls, search_options_dropdown. en.json **693** (0 חסרים), baseline 6926→**6843**. analyze נקי על כל הפרויקט, 187 טסטי i18n+search עברו. **לא תורגם (לבקשת המשתמש — שלא ישבור חיפוש):** (א) נתוני מנוע (`hebrew_morphology`/`regex_patterns`/`search_query_builder`/`snippet_builder`). (ב) מחרוזות אפשרויות-חיפוש המשמשות כ**מפתחות במפות/sets** (full_text_settings_widgets:280-290, search_options_dropdown:78-85, advanced_search_controls:544-552) — נשארו עברית כ-keys. (ג) `modeString` `'advanced'/'exact'/'fuzzy'` (נשמר ב-Settings). תוויות מצב-חיפוש שמופו לפי **אינדקס/label נפרד** מה-enum כן תורגמו (בטוח) |
| 6 — מסך עיון | 🟡 בעבודה | 2026-05-30 | — |
| 7 — PDF/הדפסה | ⬜ פתוח | — | — |
| 8 — שאר features | ⬜ פתוח | — | — |
| 9 — תרגום+ליטוש | ⬜ פתוח | — | — |

### יומן מפורט (append-only — כל סשן מוסיף שורה למטה)
- `[2026-05-29] שלב 0 (שוחזר)`: קוד שלב 0 נמחק מקומית (תיקיות `lib/l10n`, `assets/translations`, `tool/i18n` היו ריקות; אפס `.tr()` בקוד). נבנה מחדש במלואו לפי המפרט: `lib/l10n/app_translations.dart` (singleton + טעינת JSON + `localeFor`) ו-`lib/l10n/tr_extension.dart` (`.tr()` עם `args`). `assets/translations/en.json` + רישום ב-`pubspec.yaml`. הוספת `language` (ברירת מחדל `he`) ל-state/event/repository/bloc — ה-bloc טוען `AppTranslations.load` לפני emit הן ב-`LoadSettings` והן ב-`UpdateLanguage`. `lib/app.dart`: `en` ל-supportedLocales, locale נשלט מ-state, LTR אוטומטי דרך `GlobalWidgetsLocalizations`. הדגמה: `design_settings_tab.dart` עטוף במלואו ב-`.tr()` + בורר שפה עברית/English. `dart analyze` נקי. טסטים: `test/unit/settings/` + `segmented_settings_tile_test` — 54/54 עברו. `dart format` הורץ. **שים לב לשער החוסם: עדיין ממתין לאישור צוות על המראה (LTR) לפני מיגרציה המונית.**
- `[2026-05-29] שלב 2 (חלקי — בעבודה)`: התחלת מיגרציית `lib/settings/` (אושר ע"י המשתמש לעקוף את השער החוסם). **עטיפה בלבד ב-`.tr()`, ללא תרגום** (סעיף 0.6). הושלמו 11 קבצים: `dialogs/{reading_settings_dialog, color_picker_dialog, books_list_dialog}`, `view/settings_screen` (labels של טאבים/קבוצות הומרו ל-getters לתרגום דינמי), `search/{settings_search_results_view, settings_search_field, settings_search_models}` (תווי נרמול `׳`/`״` סומנו `// i18n-ignore`), `panels/{editor_settings_panel, library_settings_panel}`. אינטרפולציות הומרו ל-`{name}` (למשל הודעות שמירת CSV). `searchEntries` (const, מוזנים ל-generator) נשארו בעברית — ייטופלו בנפרד. baseline **7636→7569**. `dart analyze` נקי; טסטים: `test/unit/settings/` + `test/i18n/` (69 + 17 עברו); `dart format` הורץ. נותר: `panels/{calendar(116), gematria(73), tools_management(65)}`, `tabs/{system(303), shortcuts(167), text(137), about_dev(135), library(79)}`, `services/{custom_folders, safer_mode, backup}`.
- `[2026-05-29] שלב 1`: נבנו כלי העבודה. `tool/i18n/scan_unwrapped.dart` — סורק literals עבריים לא-עטופים (היוריסטיקת regex, מחריג הערות/import/debugPrint/`// i18n-ignore`, מסמן אינטרפולציה בנפרד); תומך `--count`/`--check`/`--write-baseline`. `tool/i18n/extract_keys.dart` — אוסף מפתחות `.tr()` → `tool/i18n/en.template.json` (ממוזג עם `en.json`, 34 מפתחות, כולם מתורגמים). **baseline=7636** נשמר ב-`tool/i18n/baseline.txt`. טסט ratchet ב-`test/i18n/` (17 בדיקות, עברו). `dart analyze` נקי, `dart format` הורץ. הערה: התבנית הועברה מ-`assets/translations/` ל-`tool/i18n/` כדי לא לנפח את ה-bundle (תבנית = ארטיפקט פיתוח).
- `[2026-05-29] שלב 2 — tabs/text`: `tabs/text_settings_tab` מוגר במלואו (גופנים, ניקוד, העתקת כותרות, הגדרות לפי ספר, sliders). אין RTL קשיח. labels כפולים (narrow/wide) טופלו ב-replace_all; רשימות `const` (SegmentOption/AppMenuEntry/TextSpan) הוסר מהן const; אינטרפולציה `{value}`. en.json מולא ל-**330 מפתחות, 0 חסרים**. baseline 7362→**7299**. analyze נקי, format הורץ.
- `[2026-05-29] שלב 4 — דיאלוגים + UiSnack`: `core/ui_snack` — 11 קבועי `static const String` הוסבו ל-getters עם `.tr()` (תרגום בזמן גישה, ללא שינוי בקוראים `UiSnack.textCopied`), וכיוון ה-toast → `AppTranslations.textDirection`. `app_dialogs` (SingleAction/TwoActions/Warning) — **תצוגת** title/content/subtitle/buttons עטופה ב-`.tr()` כרשת ביטחון: כל דיאלוג באפליקציה מתרגם אוטומטית (כולל קוראים שטרם מוגרו וברירות מחדל const). אותו דפוס ב-`confirmation_dialog`/`input_dialog`/`selection_dialog`. `error_report_sender_email` (subtitle/labelText; שדה אימייל נשאר LTR), `zip_extraction_progress`, `ad_popup` (tooltip/snooze/section titles — **שמות ארגוני סיוע ופרטיהם נשארו כתוכן**), `action_buttons`. en.json 588→**623** (0 חסרים). baseline 6984→**6932**. analyze נקי, 22 טסטים עברו.
- `[2026-05-29] שלב 3 — תפריט ראשי + סרגל עליון (ליבה)`: מוגרו ארבעת קבצי ה-chrome המרכזיים. `main_window_screen` (2930 שורות, רובו לוגיקה): 6 תוויות ניווט (`_navData`) נעטפו בנקודת השימוש `item.label.tr()` (bar+rail), דיאלוג איפוס אינדקס, snacks של ספר-לא-נמצא (אינטרפולציה `{id}`), work-status אינדוקס, דיאלוג "תוסף כבר קיים"; שמות ספרים לתור (`'בראשית'`/`'שמות'`) נשארו כמזהי lookup (לא UI). `custom_title_bar`: כותרות מסכים, tooltips (אינטרפולציה `{shortcut}`), תפריט הקשר של טאבים — **שים לב:** `menuItemKeysByLabel: {'הצג לצד'.tr(): ...}` נעטף יחד עם ה-label התואם כדי שהתאמת הסיור תישבר לא. `window_controls`, `app_popup_menu` (ברירת מחדל `'חיפוש'` const → i18n-ignore). `flutter analyze` נקי (תוקנו 3 אזהרות אינטרפולציה מיותרת), en.json 552→**583** (0 חסרים), baseline 7037→**6984**, 38 טסטים עברו, format הורץ. **`app_top_bar.dart` — אין בו מחרוזות UI (מבני בלבד).** + תיקון QA קטן: `settings_search_field` textAlign קוּבע ל-`TextAlign.start` (נגזר-locale) במקום `.right`.
- `[2026-05-29] שלב 2 — סיום (calendar+shortcuts+system) + אימות`: הושלמו שלושת הקבצים הגדולים האחרונים. `panels/calendar_settings_panel`: סוגי לוח, התראות, אינטגרציית Google Calendar (כולל דיאלוג בחירה רב-ערכי), אינטרפולציות `{count}`/`{time}`, ברירות מחדל `'חיפוש...'` סומנו i18n-ignore. `tabs/shortcuts_settings_tab`: ~24 labels של קיצורים, דיאלוג בחירת פעולה, snacks; ה-map `_shortcutsList` (CTRL+...) ASCII — לא נגעתי. `tabs/system_settings_tab` (2061 שורות): גרסאות, רשת, דיווחי טעויות (תור/שליחה/עריכה), גיבוי/שחזור, מצב סייפר, סיור, איפוס, דיאלוג יומן שינויים; ~13 אינטרפולציות; נתיב asset עברי + ברירות מחדל const סומנו i18n-ignore; הוסר `const` מ-InputDecoration שעטף labelText; תוכן (כותרות ספרים בדיווחים, פסוקים) נשאר rtl. **תרגום en.json הושלם ל-552 מפתחות, 0 חסרים.** baseline 7202→7037 (calendar) →... →**7037 סופי**. **אימות סופי: `flutter analyze` נקי על כל הפרויקט (286s), 116 טסטי i18n+settings עברו, format הורץ.** שלב 2 הושלם במלואו. לא בוצע קומיט (לבקשת המשתמש — להשלים את כל הפיצ'ר תחילה).
- `[2026-05-29] שלב 2 — tabs/about_dev + שדרוג כלים`: `tabs/about_dev_tab` מוגר — כל ה-UI (כרטיסים, ActionTiles, מקורות, הערות); **תוכן נשאר לא-עטוף ב-rtl** (שמות תורמים/מפתחים const, הנצחות `_MemorialCard`, וציטוט הסיום `_ClosingQuote` כולל ה-`Directionality` שלו — פסוקים). אינטרפולציה `{label}`. **תיקון תשתית חשוב:** גילוי ש-`dart format` שובר `'מחרוזת ארוכה'.tr()` לשתי שורות, וגם `scan` וגם `extract` פספסו זאת → מחרוזות "עטופות" נשארו בפועל לא-מתורגמות. שודרגו שני הכלים לזהות `.tr(` בשורת המשך (+טסטים). זה חשף 24 מפתחות נסתרים מקבצים קודמים. מולא `en.json` ל-**274 מפתחות, 0 חסרים**. baseline 7419→**7362**. analyze נקי, 20 טסטי i18n עברו, format הורץ.
- `[2026-05-29] שלב 2 — tabs/library + תרגום en.json`: `tabs/library_settings_tab` מוגר (snacks/דיאלוגים/labels/כפתורי אינדקס; 5 אינטרפולציות→`{name}`; 3 מופעי RTL→`AppTranslations.textDirection`; כפילויות בשני בוני-מיקום טופלו ב-replace_all). **שינוי נוהל לבקשת המשתמש: תרגום במקביל.** מולא `assets/translations/en.json` בתרגום אנגלי אמיתי לכל 221 המפתחות שנעטפו עד כה (כל הסשן + קודמים) — `extract_keys` מדווח **חסרים: 0**. baseline 7454→**7419**. analyze נקי, טסטי i18n + settings_repository עברו, format הורץ. עודכנו סעיף 0.6 ו-step 4 בנוהל.
- `[2026-05-29] שלב 2 — services/custom_folders`: הושלמה קבוצת services. `bloc/custom_folders_bloc`: הודעות message/error למשתמש נעטפו, 7 אינטרפולציות הומרו ל-`{name}` (added/updated/error/count/failed); השוואת `'ספרים אישיים'` (מפתח קטגוריה פנימי ב-DB) סומנה `// i18n-ignore` באותה שורה; 2 `Exception` נעטפו. `custom_folders_tile`: snacks/דיאלוגים/tooltips/כפתורים נעטפו, 4 אינטרפולציות הומרו, `static const` notice הוסב ל-getter עם `.tr()`, מופע RTL→`AppTranslations.textDirection`. baseline 7486→**7454**. analyze נקי, טסט `custom_folders_bloc` (2) + 17 טסטי i18n עברו, format הורץ. הטסט בודק `contains('db failed')` — האינטרפולציה משמרת זאת ב-he.
- `[2026-05-29] שלב 2 — המשך עטיפה (services)`: מוגרו 3 קבצים. `services/backup_service`: 2 הודעות `Exception` משתמש נעטפו. `services/safer_mode/protected_settings_wrapper`: title/hint של דיאלוג, labels, 4 מופעי RTL→`AppTranslations.textDirection`. `services/safer_mode/password_verification_dialog`: שני דיאלוגים — snacks, labels/hints של שדות, כפתורים; אינטרפולציה (`שגיאה בשמירת הסיסמה: {error}`); הוסר `const` מ-`Row` עוטף כדי לעטוף; ברירת מחדל `const` של `title` סומנה `// i18n-ignore` (הקוראים מעבירים title מתורגם). baseline 7516→**7486**. analyze נקי, 17 טסטי i18n עברו, format הורץ.
- `[2026-05-29] שלב 2 — המשך עטיפה (panels)`: מוגרו שני קבצים נוספים עם הדפוס המשולב (עטיפה + המרת RTL לפי שלב). `panels/gematria_settings_panel`: נעטפו כל מחרוזות ה-UI (אין RTL קשיח בקובץ). `panels/tools_management_panel`: נעטפו titles/subtitles, snacks, דיאלוג המחיקה, labels של ActionBar/badges; 2 אינטרפולציות הומרו ל-`{name}` (מונה בחירה `{count} נבחרו`, תוכן דיאלוג `{count}`/`{names}`); הוסר `const` מרשימת PopupMenu כדי לעטוף; 5 מופעי `TextDirection.rtl` הומרו ל-`AppTranslations.textDirection` (מונה/hint/badge/שורות) — כולם labels/פריסה, לא תוכן. `searchEntries` (const) נשארו. baseline 7569→**7516**. analyze נקי, 17 טסטי i18n עברו, format הורץ.
- `[2026-05-29] שלב 2 — QA + תיקון RTL→LTR`: בוצע QA על שלבים 0–2. תקין: תשתית l10n, חיווט `language`, `app.dart`, `flutter analyze` נקי, 71 טסטים עברו, scan=7569=baseline. **ממצא קריטי:** ההנחה ש"LTR נגזר אוטומטית" שגויה — 436 מופעי `TextDirection.rtl` קשיחים (33 `Directionality` מבניים + ~400 `Text`/`Row`) גוברים על ה-locale, כולל `settings_screen.dart` שעוטף את כל המסך וחוסם את הדגמת שלב 0. **תוקן** (אושר ע"י המשתמש — תשתית + הדרגתי): נוסף `AppTranslations.textDirection` (getter נגזר-locale); הומרו עוטפי הכיוון בקבצי שלב 2 שמוגרו — `settings_screen` (עוטף המסך), `color_picker_dialog` (9 מופעים: labels+Row), `books_list_dialog` (עוטף הדיאלוג; כותרות ספרים נשארו rtl כתוכן), `settings_search_results_view` (RichText). עודכן סעיף 6 בתוכנית. analyze נקי, 69 טסטים עברו, format הורץ. נותר בשלב 2: המרת ה-RTL הקשיח בקבצים שטרם מוגרו (calendar/tools_management/about_dev/system/shortcuts/safer_mode/library_tab) בזמן עטיפתם.
- `[2026-05-30] שלב 5 — חיפוש (הושלם)`: מוגרו כל קבצי `lib/search/view/` + `bloc/search_bloc`. נעטפו tooltips/labels/hints/snacks/כותרות-טאב/הודעות-שגיאה; אינטרפולציות הומרו ל-`{count}`/`{total}`/`{names}`/`{book}`/`{query}`; מופעי RTL קשיחים של תוויות UI הומרו ל-`AppTranslations.textDirection` (תוכן: כותרות ספרים/קטגוריות, מילות-חיפוש, פסוקים נשארו rtl). **שמירה על תקינות החיפוש (לבקשת המשתמש):** מחרוזות אפשרויות-חיפוש המשמשות כ**מפתחות במפות/sets** (`'קידומות'`/`'סיומות'`/`'כתיב מלא/חסר'` וכו') נשארו עברית — תרגומן היה שובר `globalSearchOptions`/`searchOptions`/`optionAbbreviations`/`suffixOptions`; `modeString` הנשמר ב-Settings (`'advanced'/'exact'/'fuzzy'`) לא נגע. תוויות מצב-חיפוש שמופו לפי **אינדקס** (ToggleSwitch) או לפי **label נפרד** מה-enum (ChoiceChip/NavButton/SearchMode tuples) כן תורגמו — בטוח. הוסר `const` מבלוקים שעטפו `.tr()` (Center/InputDecoration/labels list). en.json 627→**693** (66 חדשים, 0 חסרים). baseline 6926→**6843**. `flutter analyze` נקי על כל הפרויקט (289s), 187 טסטי i18n+search עברו, format הורץ. לא בוצע קומיט.
- `[2026-05-29] שלב 0`: נבנתה שכבת l10n עצמית (gettext-style). קבצים: `lib/l10n/app_translations.dart` (singleton + טעינת JSON + `localeFor`), `lib/l10n/tr_extension.dart` (`.tr()`). נוסף `assets/translations/en.json` + רישום ב-`pubspec.yaml`. הגדרת שפה (`language`, ברירת מחדל `he`) ב-state/event/repository/bloc — ה-bloc טוען תרגומים לפני emit הן ב-`LoadSettings` והן ב-`UpdateLanguage`. `lib/app.dart`: נוסף `en` ל-supportedLocales, ה-locale נשלט מההגדרה, LTR אוטומטי. הדגמה: `design_settings_tab.dart` תורגם במלואו + בורר שפה עברית/English. `flutter analyze` נקי. טסטים: `test/unit/settings/` + `segmented_settings_tile_test` — 52/52 עברו. **ממתין להחלטת הצוות על המראה (LTR + עמוד מתורגם) לפני שלב 1.**
