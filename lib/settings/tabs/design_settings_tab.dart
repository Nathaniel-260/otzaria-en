import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart'
    hide SwitchSettingsTile;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:window_manager/window_manager.dart';
import 'package:otzaria/l10n/tr_extension.dart';
import 'package:otzaria/settings/dialogs/settings_dialogs_exports.dart';
import 'package:otzaria/settings/engine/settings_engine_exports.dart';
import 'package:otzaria/settings/search/settings_anchor.dart';
import 'package:otzaria/settings/search/settings_search_models.dart';
import 'package:otzaria/settings/services/per_book_settings_service.dart';
import 'package:otzaria/settings/settings_card.dart';
import 'package:otzaria/settings/view/settings_screen.dart';
import 'package:otzaria/theme/theme_exports.dart';
import 'package:otzaria/widgets/widgets_exports.dart';

enum _SidebarMode { pinned, openOnBook, closed }

enum _ThemeMode { light, system, dark }

/// טאב הגדרות עיצוב
class DesignSettingsTab extends StatelessWidget {
  const DesignSettingsTab({super.key});

  /// פריטים בעלי הגדרות לחיפוש בהגדרות. נסרק על-ידי
  /// tool/generate_search_index.dart בעת בנייה ומשולב באינדקס המאוחד.
  static const List<SettingsSearchEntry> searchEntries = [
    SettingsSearchEntry(
      id: 'design.display.fullscreen',
      title: 'מסך מלא',
      subtitle: 'החלף מצב מסך מלא',
      tab: SettingsTab.design,
      cardId: 'design.display',
      keywords: ['מסך מלא', 'fullscreen', 'מופעל', 'לא מופעל'],
    ),
    SettingsSearchEntry(
      id: 'design.theme.follow_system',
      title: 'מעקב אחר צבע המערכת',
      subtitle: 'התאמת ערכת הנושא לצבע מערכת ההפעלה',
      tab: SettingsTab.design,
      cardId: 'design.theme',
      keywords: ['ערכת נושא', 'מערכת', 'מופעל', 'לא מופעל'],
    ),
    SettingsSearchEntry(
      id: 'design.theme.dark_mode',
      title: 'מצב כהה',
      subtitle: 'מעבר בין מצב בהיר למצב כהה',
      tab: SettingsTab.design,
      cardId: 'design.theme',
      keywords: [
        'ערכת נושא',
        'בהיר',
        'אפל',
        'dark mode',
        'מופעל',
        'לא מופעל',
      ],
    ),
    SettingsSearchEntry(
      id: 'design.theme.seed_color',
      title: 'צבע בסיס',
      subtitle: 'צבע ראשי של ערכת הנושא',
      tab: SettingsTab.design,
      cardId: 'design.theme',
      keywords: ['צבע', 'ערכת נושא'],
    ),
    SettingsSearchEntry(
      id: 'design.pdf.book_view',
      title: 'תצוגת ספר בPDF',
      subtitle: 'פתיחת ספרי PDF בתצוגת ספר או רגילה',
      tab: SettingsTab.design,
      cardId: 'design.pdf',
      keywords: ['pdf', 'תצוגה', 'תצוגת ספר', 'רגילה', 'מופעל', 'לא מופעל'],
    ),
    SettingsSearchEntry(
      id: 'design.tabs.compact',
      title: 'תפריטים קומפקטיים',
      subtitle: 'צפיפות תפריטים בסגנון Chrome',
      tab: SettingsTab.design,
      cardId: 'design.tabs',
      keywords: [
        'קומפקטי',
        'צפוף',
        'chrome',
        'נוח',
        'מרווח',
        'מופעל',
        'לא מופעל',
      ],
    ),
    SettingsSearchEntry(
      id: 'design.layout.sidebar_mode',
      title: 'חלונית ניווט בין כותרות',
      subtitle: 'הצגה / אוטומטי / הסתרה של חלונית הניווט',
      tab: SettingsTab.design,
      cardId: 'design.layout',
      keywords: [
        'סייד-בר',
        'תפריט',
        'הצגה',
        'אוטומטי',
        'הסתרה',
        'קבוע',
        'גלילה',
      ],
    ),
    SettingsSearchEntry(
      id: 'design.layout.notes_collapsed',
      title: 'פתיחת הערות אישיות במצב סגור',
      subtitle: 'תצוגת רשימות הערות בפתיחה',
      tab: SettingsTab.design,
      cardId: 'design.layout',
      keywords: [
        'הערות',
        'אישיות',
        'סגורות',
        'פתוחות',
        'מופעל',
        'לא מופעל',
      ],
    ),
    SettingsSearchEntry(
      id: 'design.layout.split_view',
      title: 'הצגת המפרשים בחלונית בצד',
      subtitle: 'מפרשים בחלונית מפוצלת או בתוך הטקסט',
      tab: SettingsTab.design,
      cardId: 'design.layout',
      keywords: [
        'מפרשים',
        'מפוצל',
        'מפוצלת',
        'בתוך הטקסט',
        'מופעל',
        'לא מופעל',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return SingleChildScrollView(
          primary: true,
          padding: const EdgeInsets.all(16.0),
          child: ToolPanelWrapper(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // שפת הממשק — הדגמת i18n (תרגום מלא + LTR אוטומטי)
                SettingsCard(
                  title: 'שפת הממשק'.tr(),
                  children: [
                    SegmentedSettingsTile<String>(
                      icon: FluentIcons.translate_24_regular,
                      title: 'שפת הממשק'.tr(),
                      subtitle: 'בחירת שפת הממשק'.tr(),
                      options: [
                        SegmentOption(value: 'he', label: 'עברית'.tr()),
                        const SegmentOption(value: 'en', label: 'English'),
                      ],
                      currentValue: state.language,
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(UpdateLanguage(value));
                      },
                    ),
                  ],
                ),

                kSettingsCardSpacing,

                // מסך מלא (רק בדסקטופ)
                if (!(Platform.isAndroid || Platform.isIOS))
                  SettingsAnchor(
                    cardId: 'design.display',
                    child: SettingsCard(
                      title: 'תצוגה'.tr(),
                      children: [
                        ListTile(
                          leading: Icon(state.isFullscreen
                              ? FluentIcons.full_screen_minimize_24_regular
                              : FluentIcons.full_screen_maximize_24_regular),
                          title:
                              Text('מסך מלא'.tr(), style: kSettingsTitleStyle),
                          subtitle: Text('החלף מצב מסך מלא'.tr(),
                              style: kSettingsSubtitleStyle),
                          trailing: Switch(
                            value: state.isFullscreen,
                            onChanged: (value) async {
                              context
                                  .read<SettingsBloc>()
                                  .add(UpdateIsFullscreen(value));
                              await windowManager.setFullScreen(value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                if (!(Platform.isAndroid || Platform.isIOS))
                  kSettingsCardSpacing,

                // מצב כהה וצבע בסיס
                SettingsAnchor(
                  cardId: 'design.theme',
                  child: SettingsCard(
                    title: 'ערכת נושא'.tr(),
                    children: [
                      SegmentedSettingsTile<_ThemeMode>(
                        icon: FluentIcons.weather_sunny_24_regular,
                        title: 'מצב ערכת נושא'.tr(),
                        subtitle: state.followSystemTheme
                            ? 'התוכנה תתאים את המראה באופן אוטומטי להגדרות מערכת ההפעלה'
                                .tr()
                            : state.isDarkMode
                                ? 'התוכנה תשתמש בצבעים כהים'.tr()
                                : 'התוכנה תשתמש בצבעים בהירים'.tr(),
                        options: [
                          SegmentOption(
                              value: _ThemeMode.light, label: 'בהיר'.tr()),
                          SegmentOption(
                              value: _ThemeMode.system, label: 'מערכת'.tr()),
                          SegmentOption(
                              value: _ThemeMode.dark, label: 'כהה'.tr()),
                        ],
                        currentValue: state.followSystemTheme
                            ? _ThemeMode.system
                            : state.isDarkMode
                                ? _ThemeMode.dark
                                : _ThemeMode.light,
                        onChanged: (mode) {
                          if (mode == _ThemeMode.system) {
                            context
                                .read<SettingsBloc>()
                                .add(UpdateFollowSystemTheme(true));
                          } else {
                            context
                                .read<SettingsBloc>()
                                .add(UpdateFollowSystemTheme(false));
                            context
                                .read<SettingsBloc>()
                                .add(UpdateDarkMode(mode == _ThemeMode.dark));
                          }
                        },
                      ),
                      ColorPickerTile(
                        key: ValueKey(
                            'color-picker-${state.isDarkMode ? 'dark' : 'light'}'),
                        currentColor: state.isDarkMode
                            ? state.darkSeedColor
                            : state.seedColor,
                        defaultColor: state.isDarkMode
                            ? AppSeedColors.defaultDark
                            : AppSeedColors.defaultLight,
                        onChanged: (color) {
                          if (state.isDarkMode) {
                            context
                                .read<SettingsBloc>()
                                .add(UpdateDarkSeedColor(color));
                          } else {
                            context
                                .read<SettingsBloc>()
                                .add(UpdateSeedColor(color));
                          }
                        },
                      ),
                    ],
                  ),
                ),

                kSettingsCardSpacing,

                SettingsAnchor(
                  cardId: 'design.pdf',
                  child: SettingsCard(
                    title: 'תצוגת PDF'.tr(),
                    children: [
                      SwitchSettingsTile(
                        leading: const Icon(FluentIcons.book_open_24_regular),
                        title: Text('תצוגת ספר בPDF'.tr(),
                            style: kSettingsTitleStyle),
                        subtitle: Text(
                          state.enablePerBookSettings
                              ? state.pdfBookViewByDefault
                                  ? 'ספרי PDF ייפתחו בתצוגת ספר'.tr()
                                  : 'ספרי PDF ייפתחו בתצוגה רגילה'.tr()
                              : state.pdfBookViewByDefault
                                  ? 'כל ספרי ה-PDF ייפתחו בתצוגת ספר'.tr()
                                  : 'כל ספרי ה-PDF ייפתחו בתצוגה רגילה'.tr(),
                          style: kSettingsSubtitleStyle,
                        ),
                        value: state.pdfBookViewByDefault,
                        onChanged: (value) {
                          context
                              .read<SettingsBloc>()
                              .add(UpdatePdfBookViewByDefault(value));
                        },
                      ),
                    ],
                  ),
                ),

                kSettingsCardSpacing,

                // הגדרות טאבים
                SettingsAnchor(
                  cardId: 'design.tabs',
                  child: SettingsCard(
                    title: 'כרטיסיות הספרים'.tr(),
                    children: [
                      if (!(Platform.isAndroid || Platform.isIOS))
                        SwitchSettingsTile(
                          leading: const Icon(FluentIcons.list_24_regular),
                          title: Text(
                            'תפריטים קומפקטיים'.tr(),
                            style: kSettingsTitleStyle,
                          ),
                          subtitle: Text(
                            state.compactMenuMode
                                ? 'התפריטים יוצגו בצפיפות עבודה בסגנון Chrome'
                                    .tr()
                                : 'התפריטים יוצגו במרווח נוח ובגרסה הרגילה'
                                    .tr(),
                            style: kSettingsSubtitleStyle,
                          ),
                          value: state.compactMenuMode,
                          onChanged: (value) {
                            context
                                .read<SettingsBloc>()
                                .add(UpdateCompactMenuMode(value));
                          },
                        ),
                    ],
                  ),
                ),

                kSettingsCardSpacing,

                // התנהגות סרגל צד
                SettingsAnchor(
                  cardId: 'design.layout',
                  child: SettingsCard(
                    title: 'חלוניות עזר'.tr(),
                    children: [
                      SegmentedSettingsTile<_SidebarMode>(
                        title: 'חלונית ניווט בין כותרות'.tr(),
                        subtitle: state.pinSidebar
                            ? 'החלונית תוצג באופן קבוע'.tr()
                            : state.defaultSidebarOpen
                                ? 'החלונית תוצג בפתיחת ספר ותיסגר בעת גלילה'
                                    .tr()
                                : 'החלונית לא תוצג אוטומטית עם פתיחת הספר'.tr(),
                        icon: FluentIcons.panel_left_24_regular,
                        options: [
                          SegmentOption(
                              value: _SidebarMode.pinned, label: 'הצגה'.tr()),
                          SegmentOption(
                              value: _SidebarMode.openOnBook,
                              label: 'אוטומטי'.tr()),
                          SegmentOption(
                              value: _SidebarMode.closed, label: 'הסתרה'.tr()),
                        ],
                        currentValue: state.pinSidebar
                            ? _SidebarMode.pinned
                            : state.defaultSidebarOpen
                                ? _SidebarMode.openOnBook
                                : _SidebarMode.closed,
                        onChanged: (mode) {
                          if (mode == _SidebarMode.pinned) {
                            context
                                .read<SettingsBloc>()
                                .add(UpdatePinSidebar(true));
                            context
                                .read<SettingsBloc>()
                                .add(const UpdateDefaultSidebarOpen(true));
                          } else if (mode == _SidebarMode.openOnBook) {
                            context
                                .read<SettingsBloc>()
                                .add(UpdatePinSidebar(false));
                            context
                                .read<SettingsBloc>()
                                .add(const UpdateDefaultSidebarOpen(true));
                          } else {
                            context
                                .read<SettingsBloc>()
                                .add(UpdatePinSidebar(false));
                            context
                                .read<SettingsBloc>()
                                .add(const UpdateDefaultSidebarOpen(false));
                          }
                        },
                      ),
                      SwitchSettingsTile(
                        title: Text('פתיחת הערות אישיות במצב סגור'.tr(),
                            style: kSettingsTitleStyle),
                        subtitle: Text(
                            state.personalNotesCollapsedByDefault
                                ? 'רשימות ההערות יוצגו כשהן סגורות'.tr()
                                : 'רשימות ההערות יוצגו כשהן פתוחות'.tr(),
                            style: kSettingsSubtitleStyle),
                        value: state.personalNotesCollapsedByDefault,
                        onChanged: (value) {
                          context.read<SettingsBloc>().add(
                              UpdatePersonalNotesCollapsedByDefault(value));
                        },
                      ),
                      StatefulBuilder(
                        builder: (context, setState) {
                          final splitedView =
                              Settings.getValue<bool>('key-splited-view') ??
                                  true;
                          return SwitchSettingsTile(
                            title: Text('הצגת המפרשים בחלונית בצד'.tr(),
                                style: kSettingsTitleStyle),
                            subtitle: Text(
                                splitedView
                                    ? 'המפרשים יוצגו בחלונית מפוצלת'.tr()
                                    : 'המפרשים יוצגו בתוך הטקסט'.tr(),
                                style: kSettingsSubtitleStyle),
                            value: splitedView,
                            onChanged: (value) {
                              setState(() {
                                Settings.setValue<bool>(
                                    'key-splited-view', value);
                                final settingsBloc =
                                    context.read<SettingsBloc>();
                                PerBookSettings.cleanupRedundantSettings(
                                  defaultFontSize: settingsBloc.state.fontSize,
                                  defaultRemoveNikud:
                                      settingsBloc.state.defaultRemoveNikud,
                                  defaultShowSplitView: value,
                                );
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
