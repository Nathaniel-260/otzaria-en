import 'package:flutter/material.dart';
import 'dart:io';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/l10n/app_translations.dart';
import 'package:otzaria/l10n/tr_extension.dart';
import 'package:otzaria/settings/engine/settings_engine_exports.dart';
import 'package:otzaria/settings/search/settings_anchor.dart';
import 'package:otzaria/settings/search/settings_search_models.dart';
import 'package:otzaria/settings/view/settings_screen.dart';
import 'package:otzaria/shortcuts/view/custom_shortcut_dialog.dart';
import 'package:otzaria/shortcuts/view/shortcut_dropdown_tile.dart';
import 'package:otzaria/shortcuts/shortcut_validator.dart';
import 'package:otzaria/widgets/widgets_exports.dart';
import 'package:otzaria/core/ui_snack.dart';
import 'package:otzaria/settings/settings_card.dart';
import 'package:otzaria/tour/tour_target_keys.dart';

/// טאב קיצורי מקלדת — מוצג רק בדסקטופ.
class ShortcutsSettingsTab extends StatelessWidget {
  const ShortcutsSettingsTab({super.key});

  /// פריטי חיפוש בהגדרות. נסרק על-ידי tool/generate_search_index.dart.
  static const List<SettingsSearchEntry> searchEntries = [
    SettingsSearchEntry(
      id: 'shortcuts.reset',
      title: 'איפוס קיצורי מקשים',
      subtitle: 'החזרת כל קיצורי המקלדת לברירת המחדל',
      tab: SettingsTab.shortcuts,
      cardId: 'shortcuts.main',
      keywords: ['איפוס', 'ברירת מחדל', 'מקלדת'],
    ),
    // ── ניווט כללי ──
    SettingsSearchEntry(
      id: 'shortcuts.nav.library',
      title: 'קיצור לספרייה',
      subtitle: 'פתיחת מסך הספרייה',
      tab: SettingsTab.shortcuts,
      cardId: 'shortcuts.main',
      keywords: ['ספרייה', 'ctrl+l', 'מקלדת'],
    ),
    SettingsSearchEntry(
      id: 'shortcuts.nav.find_ref',
      title: 'קיצור לאיתור',
      subtitle: 'פתיחת מסך איתור מהיר',
      tab: SettingsTab.shortcuts,
      cardId: 'shortcuts.main',
      keywords: ['איתור', 'ctrl+o', 'מקלדת'],
    ),
    SettingsSearchEntry(
      id: 'shortcuts.nav.reading',
      title: 'קיצור לעיון',
      subtitle: 'פתיחת מסך העיון בספרים',
      tab: SettingsTab.shortcuts,
      cardId: 'shortcuts.main',
      keywords: ['עיון', 'ctrl+r', 'מקלדת'],
    ),
    SettingsSearchEntry(
      id: 'shortcuts.nav.search_window',
      title: 'קיצור לחלון חיפוש חדש',
      subtitle: 'פתיחת חלון חיפוש',
      tab: SettingsTab.shortcuts,
      cardId: 'shortcuts.main',
      keywords: ['חיפוש', 'ctrl+q', 'מקלדת'],
    ),
    SettingsSearchEntry(
      id: 'shortcuts.nav.settings',
      title: 'קיצור להגדרות',
      subtitle: 'פתיחת מסך ההגדרות',
      tab: SettingsTab.shortcuts,
      cardId: 'shortcuts.main',
      keywords: ['הגדרות', 'ctrl+comma', 'מקלדת'],
    ),
    SettingsSearchEntry(
      id: 'shortcuts.nav.tools',
      title: 'קיצור לכלים',
      subtitle: 'פתיחת מסך הכלים',
      tab: SettingsTab.shortcuts,
      cardId: 'shortcuts.main',
      keywords: ['כלים', 'ctrl+m', 'מקלדת'],
    ),
    SettingsSearchEntry(
      id: 'shortcuts.nav.bookmarks',
      title: 'קיצור לסימניות',
      subtitle: 'פתיחת מסך הסימניות',
      tab: SettingsTab.shortcuts,
      cardId: 'shortcuts.main',
      keywords: ['סימניות', 'ctrl+shift+b', 'מקלדת'],
    ),
    SettingsSearchEntry(
      id: 'shortcuts.nav.history',
      title: 'קיצור להיסטוריה',
      subtitle: 'פתיחת מסך ההיסטוריה',
      tab: SettingsTab.shortcuts,
      cardId: 'shortcuts.main',
      keywords: ['היסטוריה', 'ctrl+h', 'מקלדת'],
    ),
    SettingsSearchEntry(
      id: 'shortcuts.nav.workspace',
      title: 'קיצור להחלף שולחן עבודה',
      subtitle: 'מעבר בין שולחנות עבודה',
      tab: SettingsTab.shortcuts,
      cardId: 'shortcuts.main',
      keywords: ['שולחן עבודה', 'workspace', 'ctrl+k', 'מקלדת'],
    ),
    // ── תצוגת ספר ──
    SettingsSearchEntry(
      id: 'shortcuts.book.search_in_book',
      title: 'קיצור לחיפוש בחלון הנוכחי',
      subtitle: 'משמש לחיפוש מהיר במסכי תוכן וכלים תומכים',
      tab: SettingsTab.shortcuts,
      cardId: 'shortcuts.main',
      keywords: ['חיפוש', 'בספר', 'ctrl+f', 'מקלדת'],
    ),
    SettingsSearchEntry(
      id: 'shortcuts.book.print',
      title: 'קיצור להדפסה',
      subtitle: 'הדפסת התוכן הנוכחי',
      tab: SettingsTab.shortcuts,
      cardId: 'shortcuts.main',
      keywords: ['הדפסה', 'ctrl+p', 'מקלדת'],
    ),
    SettingsSearchEntry(
      id: 'shortcuts.book.bookmark',
      title: 'קיצור להוסף סימניה',
      subtitle: 'שמירת סימניה במיקום הנוכחי',
      tab: SettingsTab.shortcuts,
      cardId: 'shortcuts.main',
      keywords: ['סימניה', 'הוסף סימניה', 'ctrl+b', 'מקלדת'],
    ),
    SettingsSearchEntry(
      id: 'shortcuts.book.note',
      title: 'קיצור להוספת הערה',
      subtitle: 'הוספת הערה אישית',
      tab: SettingsTab.shortcuts,
      cardId: 'shortcuts.main',
      keywords: ['הערה', 'אישית', 'ctrl+n', 'מקלדת'],
    ),
    SettingsSearchEntry(
      id: 'shortcuts.book.close',
      title: 'קיצור לסגור ספר נוכחי',
      subtitle: 'סגירת הספר הפתוח',
      tab: SettingsTab.shortcuts,
      cardId: 'shortcuts.main',
      keywords: ['סגור ספר', 'ctrl+w', 'מקלדת'],
    ),
    SettingsSearchEntry(
      id: 'shortcuts.book.close_all',
      title: 'קיצור לסגור כל הספרים',
      subtitle: 'סגירת כל הספרים הפתוחים',
      tab: SettingsTab.shortcuts,
      cardId: 'shortcuts.main',
      keywords: ['סגור הכל', 'ctrl+shift+w', 'מקלדת'],
    ),
    SettingsSearchEntry(
      id: 'shortcuts.book.toggle_nav_pane',
      title: 'קיצור לפתח/סגור חלונית ניווט',
      subtitle: 'טוגל לחלונית הניווט הצדדית',
      tab: SettingsTab.shortcuts,
      cardId: 'shortcuts.main',
      keywords: ['ניווט', 'חלונית', 'ctrl+shift+l', 'מקלדת'],
    ),
    SettingsSearchEntry(
      id: 'shortcuts.book.toggle_commentators_pane',
      title: 'קיצור לפתח/סגור חלונית מפרשים',
      subtitle: 'טוגל לחלונית המפרשים בצד',
      tab: SettingsTab.shortcuts,
      cardId: 'shortcuts.main',
      keywords: ['מפרשים', 'חלונית', 'ctrl+shift+c', 'מקלדת'],
    ),
    SettingsSearchEntry(
      id: 'shortcuts.book.open_commentators_tab',
      title: 'קיצור לפתיחת כרטיסיית מפרשים',
      subtitle: 'פתיחת המפרשים בכרטיסייה נפרדת ליד הספר הנוכחי',
      tab: SettingsTab.shortcuts,
      cardId: 'shortcuts.main',
      keywords: ['מפרשים', 'כרטיסייה', 'טאב', 'מקלדת'],
    ),
    SettingsSearchEntry(
      id: 'shortcuts.book.toggle_pdf_view',
      title: 'קיצור להחלפת מצב תצוגה PDF/טקסט',
      subtitle: 'מעבר בין תצוגת PDF לתצוגת טקסט',
      tab: SettingsTab.shortcuts,
      cardId: 'shortcuts.main',
      keywords: ['PDF', 'טקסט', 'תצוגה', 'מקלדת', 'ctrl+shift+p'],
    ),
    SettingsSearchEntry(
      id: 'shortcuts.calendar.toggle_times',
      title: 'קיצור לפתיחה/סגירה זמני היום בלוח שנה',
      subtitle: 'הצגה/הסתרה של זמני היום',
      tab: SettingsTab.shortcuts,
      cardId: 'shortcuts.main',
      keywords: ['לוח שנה', 'זמנים', 'זמני היום', 'מקלדת'],
    ),
    SettingsSearchEntry(
      id: 'shortcuts.calendar.toggle_events',
      title: 'קיצור לפתיחה/סגירה אירועים בלוח שנה',
      subtitle: 'הצגה/הסתרה של אירועים',
      tab: SettingsTab.shortcuts,
      cardId: 'shortcuts.main',
      keywords: ['לוח שנה', 'אירועים', 'מקלדת'],
    ),
    SettingsSearchEntry(
      id: 'shortcuts.calendar.today',
      title: 'קיצור למעבר להיום בלוח שנה',
      subtitle: 'ניווט מהיר לתאריך היום',
      tab: SettingsTab.shortcuts,
      cardId: 'shortcuts.main',
      keywords: ['לוח שנה', 'היום', 'מקלדת'],
    ),
    SettingsSearchEntry(
      id: 'shortcuts.calendar.create_event',
      title: 'קיצור ליצירת אירוע בלוח שנה',
      subtitle: 'פתיחת חלון יצירת אירוע',
      tab: SettingsTab.shortcuts,
      cardId: 'shortcuts.main',
      keywords: ['לוח שנה', 'אירוע', 'יצירה', 'מקלדת'],
    ),
    SettingsSearchEntry(
      id: 'shortcuts.calendar.toggle_view',
      title: 'קיצור למעבר בין תצוגות לוח שנה',
      subtitle: 'החלפה בין תצוגות שונות',
      tab: SettingsTab.shortcuts,
      cardId: 'shortcuts.main',
      keywords: ['לוח שנה', 'תצוגה', 'מקלדת'],
    ),
    SettingsSearchEntry(
      id: 'shortcuts.shamor_zachor.cycle_filter',
      title: 'קיצור למעבר בין סינונים בשמור וזכור',
      subtitle: 'מחזור בין הסינונים השונים',
      tab: SettingsTab.shortcuts,
      cardId: 'shortcuts.main',
      keywords: ['שמור וזכור', 'סינון', 'מקלדת'],
    ),
  ];

  static const Map<String, String> _shortcutsList = {
    'ctrl+a': 'CTRL + A',
    'ctrl+b': 'CTRL + B',
    'ctrl+c': 'CTRL + C',
    'ctrl+d': 'CTRL + D',
    'ctrl+e': 'CTRL + E',
    'ctrl+f': 'CTRL + F',
    'ctrl+g': 'CTRL + G',
    'ctrl+h': 'CTRL + H',
    'ctrl+i': 'CTRL + I',
    'ctrl+j': 'CTRL + J',
    'ctrl+k': 'CTRL + K',
    'ctrl+l': 'CTRL + L',
    'ctrl+m': 'CTRL + M',
    'ctrl+n': 'CTRL + N',
    'ctrl+o': 'CTRL + O',
    'ctrl+p': 'CTRL + P',
    'ctrl+q': 'CTRL + Q',
    'ctrl+r': 'CTRL + R',
    'ctrl+s': 'CTRL + S',
    'ctrl+t': 'CTRL + T',
    'ctrl+u': 'CTRL + U',
    'ctrl+v': 'CTRL + V',
    'ctrl+w': 'CTRL + W',
    'ctrl+x': 'CTRL + X',
    'ctrl+y': 'CTRL + Y',
    'ctrl+z': 'CTRL + Z',
    'ctrl+0': 'CTRL + 0',
    'ctrl+1': 'CTRL + 1',
    'ctrl+2': 'CTRL + 2',
    'ctrl+3': 'CTRL + 3',
    'ctrl+4': 'CTRL + 4',
    'ctrl+5': 'CTRL + 5',
    'ctrl+6': 'CTRL + 6',
    'ctrl+7': 'CTRL + 7',
    'ctrl+8': 'CTRL + 8',
    'ctrl+9': 'CTRL + 9',
    'ctrl+comma': 'CTRL + ,',
    'ctrl+shift+b': 'CTRL + SHIFT + B',
    'ctrl+shift+c': 'CTRL + SHIFT + C',
    'ctrl+shift+e': 'CTRL + SHIFT + E',
    'ctrl+shift+l': 'CTRL + SHIFT + L',
    'ctrl+shift+n': 'CTRL + SHIFT + N',
    'ctrl+shift+p': 'CTRL + SHIFT + P',
    'ctrl+shift+w': 'CTRL + SHIFT + W',
  };

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      return Center(child: Text('קיצורי מקשים זמינים רק בדסקטופ'.tr()));
    }

    return SingleChildScrollView(
      primary: true,
      padding: const EdgeInsets.all(16.0),
      child: ToolPanelWrapper(
        key: tourShortcutsSettingsTargetKey,
        // עוטף ב-BlocBuilder כדי לרענן את רשימת הטיילים והכרטיס "הוסף קיצור"
        // מיד עם שינוי הקיצורים (פעולה זמינה -> מוגדרת ולהיפך).
        child: BlocBuilder<SettingsBloc, SettingsState>(
          buildWhen: (previous, current) =>
              previous.shortcuts != current.shortcuts,
          builder: (context, _) => _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final unconfiguredKeys = ShortcutValidator.shortcutKeys
        .where((k) => (ShortcutValidator.getShortcutValue(k) ?? '').isEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── כללי (איפוס) ──────────────────────────────────────────────
        SettingsAnchor(
          cardId: 'shortcuts.main',
          child: SettingsCard(
            title: 'כללי'.tr(),
            children: [
              ListTile(
                leading: const Icon(FluentIcons.arrow_reset_24_regular),
                title:
                    Text('איפוס קיצורי מקשים'.tr(), style: kSettingsTitleStyle),
                subtitle: Text(
                  'החזר את כל קיצורי המקשים לברירת המחדל'.tr(),
                  style: kSettingsSubtitleStyle,
                ),
                trailing: NeutralActionButton(
                  text: 'איפוס'.tr(),
                  onPressed: () => _resetShortcuts(context),
                ),
              ),
            ],
          ),
        ),

        kSettingsCardSpacing,

        // ── ניווט כללי ────────────────────────────────────────────────
        SettingsCard(
          title: 'ניווט כללי'.tr(),
          children: _onlyConfigured([
            _ShortcutTile(
              settingKey: 'key-shortcut-open-library-browser',
              label: 'ספרייה'.tr(),
              defaultShortcut: 'ctrl+l',
              icon: FluentIcons.library_24_regular,
              allShortcuts: _shortcutsList,
            ),
            _ShortcutTile(
              settingKey: 'key-shortcut-open-find-ref',
              label: 'איתור'.tr(),
              defaultShortcut: 'ctrl+o',
              icon: FluentIcons.book_search_24_regular,
              allShortcuts: _shortcutsList,
            ),
            _ShortcutTile(
              settingKey: 'key-shortcut-open-reading-screen',
              label: 'עיון'.tr(),
              defaultShortcut: 'ctrl+r',
              icon: FluentIcons.book_open_24_regular,
              allShortcuts: _shortcutsList,
            ),
            _ShortcutTile(
              settingKey: 'key-shortcut-open-new-search',
              label: 'חלון חיפוש חדש'.tr(),
              defaultShortcut: 'ctrl+q',
              icon: FluentIcons.search_24_regular,
              allShortcuts: _shortcutsList,
            ),
            _ShortcutTile(
              settingKey: 'key-shortcut-open-settings',
              label: 'הגדרות'.tr(),
              defaultShortcut: 'ctrl+comma',
              icon: FluentIcons.settings_24_regular,
              allShortcuts: _shortcutsList,
            ),
            _ShortcutTile(
              settingKey: 'key-shortcut-open-more',
              label: 'כלים'.tr(),
              defaultShortcut: 'ctrl+m',
              icon: FluentIcons.apps_24_regular,
              allShortcuts: _shortcutsList,
            ),
            _ShortcutTile(
              settingKey: 'key-shortcut-open-bookmarks',
              label: 'סימניות'.tr(),
              defaultShortcut: 'ctrl+shift+b',
              icon: FluentIcons.bookmark_24_regular,
              allShortcuts: _shortcutsList,
            ),
            _ShortcutTile(
              settingKey: 'key-shortcut-open-history',
              label: 'היסטוריה'.tr(),
              defaultShortcut: 'ctrl+h',
              icon: FluentIcons.history_24_regular,
              allShortcuts: _shortcutsList,
            ),
            _ShortcutTile(
              settingKey: 'key-shortcut-switch-workspace',
              label: 'החלף שולחן עבודה'.tr(),
              defaultShortcut: 'ctrl+k',
              icon: FluentIcons.grid_24_regular,
              allShortcuts: _shortcutsList,
            ),
          ]),
        ),

        kSettingsCardSpacing,

        // ── תצוגת ספר ─────────────────────────────────────────────────
        SettingsCard(
          title: 'תצוגת ספר'.tr(),
          children: _onlyConfigured([
            _ShortcutTile(
              settingKey: ShortcutValidator.currentWindowSearchKey,
              label: 'חיפוש בחלון הנוכחי'.tr(),
              subtitle: 'משמש לחיפוש מהיר במסכי תוכן וכלים תומכים'.tr(),
              defaultShortcut: 'ctrl+f',
              icon: FluentIcons.search_24_regular,
              allShortcuts: _shortcutsList,
            ),
            _ShortcutTile(
              settingKey: 'key-shortcut-print',
              label: 'הדפסה'.tr(),
              defaultShortcut: 'ctrl+p',
              icon: FluentIcons.print_24_regular,
              allShortcuts: _shortcutsList,
            ),
            _ShortcutTile(
              settingKey: 'key-shortcut-add-bookmark',
              label: 'הוסף סימניה'.tr(),
              defaultShortcut: 'ctrl+b',
              icon: FluentIcons.bookmark_24_regular,
              allShortcuts: _shortcutsList,
            ),
            _ShortcutTile(
              settingKey: 'key-shortcut-add-note',
              label: 'הוספת הערה'.tr(),
              defaultShortcut: 'ctrl+n',
              icon: FluentIcons.note_24_regular,
              allShortcuts: _shortcutsList,
            ),
            _ShortcutTile(
              settingKey: 'key-shortcut-close-tab',
              label: 'סגור ספר נוכחי'.tr(),
              defaultShortcut: 'ctrl+w',
              icon: FluentIcons.dismiss_circle_24_regular,
              allShortcuts: _shortcutsList,
            ),
            _ShortcutTile(
              settingKey: 'key-shortcut-close-all-tabs',
              label: 'סגור כל הספרים'.tr(),
              defaultShortcut: 'ctrl+shift+w',
              icon: FluentIcons.dismiss_24_regular,
              allShortcuts: _shortcutsList,
            ),
            _ShortcutTile(
              settingKey: 'key-shortcut-toggle-nav-pane',
              label: 'פתח/סגור חלונית ניווט'.tr(),
              defaultShortcut: 'ctrl+shift+l',
              icon: FluentIcons.panel_left_24_regular,
              allShortcuts: _shortcutsList,
            ),
            _ShortcutTile(
              settingKey: 'key-shortcut-toggle-commentators-pane',
              label: 'פתח/סגור חלונית מפרשים'.tr(),
              defaultShortcut: 'ctrl+shift+c',
              icon: FluentIcons.book_open_24_regular,
              allShortcuts: _shortcutsList,
            ),
            _ShortcutTile(
              settingKey: 'key-shortcut-toggle-pdf-view',
              label: 'החלף מצב תצוגה (PDF/טקסט)'.tr(),
              defaultShortcut: 'ctrl+shift+p',
              icon: FluentIcons.document_pdf_24_regular,
              allShortcuts: _shortcutsList,
            ),
            _ShortcutTile(
              settingKey: 'key-shortcut-open-commentators-tab',
              label: 'פתח כרטיסיית מפרשים'.tr(),
              defaultShortcut: '',
              icon: FluentIcons.open_24_regular,
              allShortcuts: _shortcutsList,
            ),
          ]),
        ),

        kSettingsCardSpacing,

        // ── לוח שנה ושמור וזכור ───────────────────────────────────────
        SettingsCard(
          title: 'לוח שנה ושמור וזכור'.tr(),
          children: _onlyConfigured([
            _ShortcutTile(
              settingKey: 'key-shortcut-calendar-toggle-times',
              label: 'לוח שנה: פתיחה/סגירה זמני היום'.tr(),
              defaultShortcut: 'ctrl+e',
              icon: FluentIcons.clock_24_regular,
              allShortcuts: _shortcutsList,
            ),
            _ShortcutTile(
              settingKey: 'key-shortcut-calendar-toggle-events',
              label: 'לוח שנה: פתיחה/סגירה אירועים'.tr(),
              defaultShortcut: 'ctrl+n',
              icon: FluentIcons.calendar_24_regular,
              allShortcuts: _shortcutsList,
            ),
            _ShortcutTile(
              settingKey: 'key-shortcut-calendar-today',
              label: 'לוח שנה: מעבר להיום'.tr(),
              defaultShortcut: 'ctrl+d',
              icon: FluentIcons.calendar_today_24_regular,
              allShortcuts: _shortcutsList,
            ),
            _ShortcutTile(
              settingKey: 'key-shortcut-calendar-create-event',
              label: 'לוח שנה: יצירת אירוע'.tr(),
              defaultShortcut: 'ctrl+shift+n',
              icon: FluentIcons.calendar_add_24_regular,
              allShortcuts: _shortcutsList,
            ),
            _ShortcutTile(
              settingKey: 'key-shortcut-calendar-toggle-view',
              label: 'לוח שנה: מעבר בין תצוגות'.tr(),
              defaultShortcut: 'ctrl+shift+e',
              icon: FluentIcons.calendar_multiple_24_regular,
              allShortcuts: _shortcutsList,
            ),
            _ShortcutTile(
              settingKey: 'key-shortcut-shamor-zachor-cycle-filter',
              label: 'שמור וזכור: מעבר בין הסינונים'.tr(),
              defaultShortcut: 'ctrl+e',
              icon: FluentIcons.filter_24_regular,
              allShortcuts: _shortcutsList,
            ),
          ]),
        ),

        // ── פעולות זמינות להגדרת קיצור ────────────────────────────────
        if (unconfiguredKeys.isNotEmpty) ...[
          kSettingsCardSpacing,
          SettingsCard(
            title: 'פעולות זמינות לקיצור'.tr(),
            subtitle:
                'פעולות הקיימות באפליקציה ועדיין לא הוגדר להן קיצור מקלדת'.tr(),
            children: [
              ListTile(
                leading: const Icon(FluentIcons.add_24_regular),
                title: Text('הוסף קיצור לפעולה זמינה'.tr(),
                    style: kSettingsTitleStyle),
                subtitle: Text(
                  '{count} פעולות זמינות'
                      .tr(args: {'count': '${unconfiguredKeys.length}'}),
                  style: kSettingsSubtitleStyle,
                ),
                trailing: RecommendedActionButton(
                  text: 'הוסף קיצור'.tr(),
                  onPressed: () => _addShortcut(context, unconfiguredKeys),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// משאיר רק טיילים של קיצורים שכבר הוגדר להם ערך לא-ריק.
  /// קיצורים ללא ערך מוצגים תחת "פעולות זמינות לקיצור".
  List<Widget> _onlyConfigured(List<Widget> tiles) {
    return tiles.where((tile) {
      if (tile is _ShortcutTile) {
        final value = ShortcutValidator.getShortcutValue(tile.settingKey) ?? '';
        return value.isNotEmpty;
      }
      return true;
    }).toList();
  }

  Future<void> _addShortcut(
      BuildContext context, List<String> unconfiguredKeys) async {
    final settingsBloc = context.read<SettingsBloc>();

    final selectedKey = await showDialog<String>(
      context: context,
      builder: (_) => _PickActionDialog(actionKeys: unconfiguredKeys),
    );
    if (selectedKey == null || !context.mounted) return;

    final shortcut = await showDialog<String>(
      context: context,
      builder: (_) => const CustomShortcutDialog(),
    );
    if (shortcut == null || shortcut.isEmpty) return;

    // חישוב קונפליקטים *לפני* שליחת UpdateShortcut: הוא אסינכרוני (ה-bloc
    // עושה await על repository.updateShortcut), ולכן checkConflicts שירוץ
    // אחריו עלול לקרוא ערכים ישנים מ-Settings ולפספס כפילות.
    final conflictingNames = <String>[];
    for (final key in ShortcutValidator.shortcutKeys) {
      if (key == selectedKey) continue;
      if (ShortcutValidator.canShareShortcut(selectedKey, key)) continue;
      final existingValue = ShortcutValidator.getShortcutValue(key) ?? '';
      if (existingValue == shortcut) {
        conflictingNames.add(ShortcutValidator.shortcutNames[key] ?? key);
      }
    }

    if (conflictingNames.isNotEmpty) {
      UiSnack.showError(
        'קיצור זה כבר בשימוש עבור: {names}'
            .tr(args: {'names': conflictingNames.join(', ')}),
      );
      return;
    }

    settingsBloc.add(UpdateShortcut(selectedKey, shortcut));
  }

  Future<void> _resetShortcuts(BuildContext context) async {
    final confirmed = await showWarningDialog(
      context: context,
      title: 'איפוס קיצורי מקשים?'.tr(),
      content: 'כל קיצורי המקשים המותאמים אישית יאופסו לברירת המחדל.'.tr(),
      subtitle: 'פעולה זו אינה הפיכה'.tr(),
    );
    if (confirmed == true && context.mounted) {
      context.read<SettingsBloc>().add(ResetShortcuts());
      UiSnack.showSuccess('קיצורי המקשים אופסו בהצלחה'.tr());
    }
  }
}

// ── _ShortcutTile ─────────────────────────────────────────────────────────────
// פה מחקנו את כל עטיפות ה-Theme המסורבלות
class _ShortcutTile extends StatelessWidget {
  final String settingKey;
  final String label;
  final String? subtitle;
  final String defaultShortcut;
  final IconData icon;
  final Map<String, String> allShortcuts;

  const _ShortcutTile({
    required this.settingKey,
    required this.label,
    this.subtitle,
    required this.defaultShortcut,
    required this.icon,
    required this.allShortcuts,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: DefaultTextStyle.of(context).style.merge(kSettingsTitleStyle),
      child: ShortcutDropDownTile(
        settingKey: settingKey,
        title: label,
        subtitle: subtitle,
        selected: defaultShortcut,
        allShortcuts: allShortcuts,
        leading: Icon(icon),
      ),
    );
  }
}

// ── _PickActionDialog ────────────────────────────────────────────────────────
/// דיאלוג לבחירת פעולה מתוך רשימת הפעולות הזמינות להגדרת קיצור.
/// מחזיר את ה-`settingKey` שנבחר ([ShortcutValidator.shortcutKeys]),
/// או null אם בוטל.
///
/// הקומפוננטות הקנוניות ב-`app_dialogs.dart` (SingleActionDialog וכו') בנויות
/// סביב כפתור confirm/cancel — לא מתאימות ל-picker שבו כל פריט הוא הפעולה
/// עצמה. במקום זאת אנחנו מיישרים קו עם אותו AlertDialog + צבעי המשטח
/// (`surfaceContainerHigh`) ואותם סגנונות לכפתורי הביטול (FilledButton.tonal).
class _PickActionDialog extends StatelessWidget {
  final List<String> actionKeys;

  const _PickActionDialog({required this.actionKeys});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      backgroundColor: cs.surfaceContainerHigh,
      title: Text(
        'בחר פעולה להוספת קיצור'.tr(),
        textDirection: AppTranslations.textDirection,
      ),
      content: SizedBox(
        width: 420,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: actionKeys.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final key = actionKeys[i];
            final name = ShortcutValidator.shortcutNames[key] ?? key;
            return ListTile(
              title: Text(name, textDirection: AppTranslations.textDirection),
              trailing: const Icon(FluentIcons.chevron_right_24_regular),
              onTap: () => Navigator.of(context).pop(key),
            );
          },
        ),
      ),
      actions: [
        FilledButton.tonal(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: cs.secondaryContainer,
            foregroundColor: cs.onSecondaryContainer,
          ),
          child: Text('ביטול'.tr()),
        ),
      ],
    );
  }
}
