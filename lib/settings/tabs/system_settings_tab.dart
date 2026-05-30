import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart'
    hide SettingsGroup, SwitchSettingsTile;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
// import 'package:path/path.dart' as p;
// import 'package:otzaria/data/constants/database_constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:otzaria/core/app_runtime_reset.dart';
import 'package:otzaria/l10n/app_translations.dart';
import 'package:otzaria/l10n/tr_extension.dart';
import 'package:otzaria/settings/engine/settings_engine_exports.dart';
import 'package:otzaria/settings/search/settings_anchor.dart';
import 'package:otzaria/settings/search/settings_search_models.dart';
import 'package:otzaria/settings/view/settings_screen.dart';
import 'package:otzaria/settings/dialogs/books_list_dialog.dart';
import 'package:otzaria/settings/services/safer_mode/password_verification_dialog.dart';
import 'package:otzaria/settings/services/safer_mode/protected_settings_wrapper.dart';
import 'package:otzaria/settings/services/backup_service.dart';
import 'package:otzaria/core/ui_snack.dart';
import 'package:otzaria/empty_library/bloc/empty_library_bloc.dart';
import 'package:otzaria/empty_library/bloc/empty_library_event.dart';
import 'package:otzaria/empty_library/bloc/empty_library_state.dart';
import 'package:otzaria/library/bloc/library_bloc.dart';
import 'package:otzaria/library/bloc/library_event.dart';
import 'package:otzaria/navigation/bloc/navigation_bloc.dart';
import 'package:otzaria/navigation/bloc/navigation_event.dart';
import 'package:otzaria/models/direct_error_report.dart';
import 'package:otzaria/services/direct_error_report_service.dart';
import 'package:otzaria/services/data_collection_service.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/widgets/widgets_exports.dart';
import 'package:otzaria/widgets/dialogs/error_report_sender_email_dialog.dart';
import 'package:otzaria/widgets/text/rtl_text_field.dart';
import 'package:otzaria/settings/settings_card.dart';
import 'package:otzaria/theme/theme_exports.dart';
import 'package:otzaria/text_book/view/error_report_dialog.dart';
import 'package:otzaria/tour/bloc/tour_cubit.dart';
import 'package:otzaria/tour/tour_target_keys.dart';
import 'package:otzaria/plugins/view/webview_environment_holder.dart';
import 'package:otzaria/widgets/misc/restart_widget.dart';
import 'package:url_launcher/url_launcher.dart';

/// טאב "אוצריא" — גרסאות, נתיב ספרייה, גיבוי, מצב סייפר, איפוס.
class SystemSettingsTab extends StatefulWidget {
  const SystemSettingsTab({super.key});

  /// פריטי חיפוש בהגדרות. נסרק על-ידי tool/generate_search_index.dart.
  static const List<SettingsSearchEntry> searchEntries = [
    SettingsSearchEntry(
      id: 'system.versions.app',
      title: 'גרסת תוכנה',
      subtitle: 'גרסת אוצריא המותקנת',
      tab: SettingsTab.system,
      cardId: 'system.versions',
      keywords: ['גרסה', 'version'],
    ),
    SettingsSearchEntry(
      id: 'system.versions.library',
      title: 'גרסת ספרייה',
      subtitle: 'גרסת מאגר הספרים',
      tab: SettingsTab.system,
      cardId: 'system.versions',
      keywords: ['גרסה', 'ספריה'],
    ),
    SettingsSearchEntry(
      id: 'system.versions.book_count',
      title: 'מספר ספרים',
      subtitle: 'כמות הספרים בספרייה',
      tab: SettingsTab.system,
      cardId: 'system.versions',
      keywords: ['ספרים', 'כמות'],
    ),
    SettingsSearchEntry(
      id: 'system.updates.network_mode',
      title: 'סינכרון ומצב רשת',
      subtitle: 'מקוון / מנותק לחלוטין מהרשת',
      tab: SettingsTab.system,
      cardId: 'system.updates',
      keywords: ['רשת', 'אופליין', 'אונליין', 'מקוון', 'מנותק'],
    ),
    SettingsSearchEntry(
      id: 'system.updates.software',
      title: 'עדכוני תוכנה וספרים',
      subtitle: 'הפעלת עדכוני תוכנה וספרים אוטומטיים',
      tab: SettingsTab.system,
      cardId: 'system.updates',
      keywords: ['עדכון', 'גרסה', 'מופעל', 'לא מופעל'],
    ),
    SettingsSearchEntry(
      id: 'system.updates.library_sync',
      title: 'סינכרון הספרייה באופן אוטומטי',
      subtitle: 'עדכון מסד הנתונים של הספרייה אוטומטית',
      tab: SettingsTab.system,
      cardId: 'system.updates',
      keywords: ['סנכרון', 'ספריה', 'אוטומטי', 'מופעל', 'לא מופעל'],
    ),
    SettingsSearchEntry(
      id: 'system.updates.dev_channel',
      title: 'עדכון לגרסאות מפתחים',
      subtitle: 'קבלת גרסאות בדיקה (Beta)',
      tab: SettingsTab.system,
      cardId: 'system.updates',
      keywords: ['בטא', 'מפתחים', 'יציבה', 'מופעל', 'לא מופעל'],
    ),
    SettingsSearchEntry(
      id: 'system.reports.email',
      title: 'כתובת מייל לזיהוי',
      subtitle: 'מייל לזיהוי בדיווחי טעויות',
      tab: SettingsTab.system,
      cardId: 'system.reports',
      keywords: ['מייל', 'דיווח', 'דואר אלקטרוני', 'email'],
    ),
    SettingsSearchEntry(
      id: 'system.reports.queue_offline',
      title: 'שמירת דיווחים אוטומטית כשאין חיבור',
      subtitle: 'תור אוטומטי לדיווחים במצב אופליין',
      tab: SettingsTab.system,
      cardId: 'system.reports',
      keywords: ['דיווח', 'אופליין', 'תור', 'מופעל', 'לא מופעל'],
    ),
    SettingsSearchEntry(
      id: 'system.reports.pending',
      title: 'ניהול דיווחים שמורים',
      subtitle: 'צפיה ושליחה של דיווחים שעדיין לא נשלחו',
      tab: SettingsTab.system,
      cardId: 'system.reports',
      keywords: ['דיווח', 'תור', 'שליחה'],
    ),
    SettingsSearchEntry(
      id: 'system.reports.sent',
      title: 'דיווחים שנשלחו',
      subtitle: 'היסטוריית דיווחים שנשלחו',
      tab: SettingsTab.system,
      cardId: 'system.reports',
      keywords: ['דיווח', 'היסטוריה'],
    ),
    SettingsSearchEntry(
      id: 'system.advanced.backup',
      title: 'גיבוי אוטומטי',
      subtitle: 'תדירות גיבוי + יצירה ושחזור גיבוי',
      tab: SettingsTab.system,
      cardId: 'system.advanced',
      keywords: [
        'גיבוי',
        'שחזור',
        'backup',
        'ללא',
        'שבועי',
        'חודשי',
        'תדירות',
      ],
    ),
    SettingsSearchEntry(
      id: 'system.advanced.backup.mode',
      title: 'מצב גיבוי',
      subtitle: 'גבה הכל / מותאם אישית',
      tab: SettingsTab.system,
      cardId: 'system.advanced',
      keywords: ['גיבוי', 'הכל', 'מותאם אישית'],
    ),
    SettingsSearchEntry(
      id: 'system.advanced.backup.settings',
      title: 'גיבוי הגדרות',
      subtitle: 'כולל את כלל הגדרות התוכנה',
      tab: SettingsTab.system,
      cardId: 'system.advanced',
      keywords: ['גיבוי', 'הגדרות'],
    ),
    SettingsSearchEntry(
      id: 'system.advanced.backup.bookmarks',
      title: 'גיבוי סימניות',
      subtitle: 'כל הסימניות שנשמרו',
      tab: SettingsTab.system,
      cardId: 'system.advanced',
      keywords: ['גיבוי', 'סימניות'],
    ),
    SettingsSearchEntry(
      id: 'system.advanced.backup.history',
      title: 'גיבוי היסטוריה',
      subtitle: 'היסטוריית הלימוד',
      tab: SettingsTab.system,
      cardId: 'system.advanced',
      keywords: ['גיבוי', 'היסטוריה', 'לימוד'],
    ),
    SettingsSearchEntry(
      id: 'system.advanced.backup.notes',
      title: 'גיבוי הערות אישיות',
      subtitle: 'כל ההערות האישיות שלך',
      tab: SettingsTab.system,
      cardId: 'system.advanced',
      keywords: ['גיבוי', 'הערות'],
    ),
    SettingsSearchEntry(
      id: 'system.advanced.backup.workspaces',
      title: 'גיבוי שולחנות עבודה',
      subtitle: 'כל שולחנות העבודה',
      tab: SettingsTab.system,
      cardId: 'system.advanced',
      keywords: ['גיבוי', 'שולחנות עבודה', 'workspace'],
    ),
    SettingsSearchEntry(
      id: 'system.advanced.backup.shamor_zachor',
      title: 'גיבוי שמור וזכור',
      subtitle: 'ספרים ומעקב לימוד',
      tab: SettingsTab.system,
      cardId: 'system.advanced',
      keywords: ['גיבוי', 'שמור וזכור', 'מעקב לימוד'],
    ),
    SettingsSearchEntry(
      id: 'system.advanced.backup.user_overrides',
      title: 'גיבוי הגדרות מתקדמות',
      subtitle: 'הגדרות נוספות שדרסת',
      tab: SettingsTab.system,
      cardId: 'system.advanced',
      keywords: ['גיבוי', 'הגדרות מתקדמות', 'overrides'],
    ),
    SettingsSearchEntry(
      id: 'system.advanced.backup.create',
      title: 'צור גיבוי עכשיו',
      subtitle: 'יצירת קובץ גיבוי באופן ידני',
      tab: SettingsTab.system,
      cardId: 'system.advanced',
      keywords: ['גיבוי', 'יצירה', 'ידני', 'export'],
    ),
    SettingsSearchEntry(
      id: 'system.advanced.backup.restore',
      title: 'שחזר מגיבוי',
      subtitle: 'שחזור הנתונים מקובץ גיבוי',
      tab: SettingsTab.system,
      cardId: 'system.advanced',
      keywords: ['שחזור', 'גיבוי', 'restore', 'import'],
    ),
    SettingsSearchEntry(
      id: 'system.advanced.cypher',
      title: 'מצב סייפר',
      subtitle: 'נעילת הגדרות בסיסמה',
      tab: SettingsTab.system,
      cardId: 'system.advanced',
      keywords: ['נעילה', 'סיסמה', 'הגנה', 'מופעל', 'לא מופעל', 'מוגן'],
    ),
    SettingsSearchEntry(
      id: 'system.advanced.cypher.toggle',
      title: 'הפעל מצב סייפר',
      subtitle: 'הפעלה/השבתה של נעילת ההגדרות',
      tab: SettingsTab.system,
      cardId: 'system.advanced',
      keywords: ['סייפר', 'מצב מוגן', 'מופעל', 'לא מופעל', 'נעילה'],
    ),
    SettingsSearchEntry(
      id: 'system.advanced.cypher.password',
      title: 'סיסמה',
      subtitle: 'הגדרת או שינוי סיסמת מצב סייפר',
      tab: SettingsTab.system,
      cardId: 'system.advanced',
      keywords: ['סיסמה', 'סייפר', 'password', 'שינוי סיסמה'],
    ),
    SettingsSearchEntry(
      id: 'system.tour',
      title: 'הפעל סיור מחדש',
      subtitle: 'סיור מודרך לחלקי האפליקציה',
      tab: SettingsTab.system,
      cardId: 'system.tour',
      keywords: ['סיור', 'הדרכה', 'tour'],
    ),
    SettingsSearchEntry(
      id: 'system.reset',
      title: 'איפוס הגדרות',
      subtitle: 'מחיקת כל ההגדרות וחזרה למצב ההתחלתי',
      tab: SettingsTab.system,
      cardId: 'system.reset',
      keywords: ['איפוס', 'reset'],
    ),
  ];

  @override
  State<SystemSettingsTab> createState() => _SystemSettingsTabState();
}

class _SystemSettingsTabState extends State<SystemSettingsTab> {
  final GlobalKey _networkModeTileKey = GlobalKey();
  final EmptyLibraryBloc _librarySelectionBloc = EmptyLibraryBloc();

  // ── מפתחות גיבוי ──────────────────────────────────────────────────────────
  static const _keyBackupSettings = 'key-backup-settings';
  static const _keyBackupBookmarks = 'key-backup-bookmarks';
  static const _keyBackupHistory = 'key-backup-history';
  static const _keyBackupNotes = 'key-backup-notes';
  static const _keyBackupWorkspaces = 'key-backup-workspaces';
  static const _keyBackupShamorZachor = 'key-backup-shamor-zachor';
  static const _keyBackupUserOverrides = 'key-backup-user-overrides';
  static const _keyBackupPlugins = 'key-backup-plugins';
  static const _keyAutoBackupFrequency = 'key-auto-backup-frequency';

  _BackupMode _selectedBackupMode = _BackupMode.all;

  // ── מצב סייפר (expandable) ────────────────────────────────────────────────
  bool _isCypherExpanded = false;

  // ── גיבוי (expandable) ─────────────────────────────────────────────────────
  bool _isBackupExpanded = false;

  // ── גרסאות ────────────────────────────────────────────────────────────────
  String? _appVersion;
  String? _libraryVersion;
  int? _bookCount;
  bool _isFlushingPendingReports = false;
  bool _isClearingPendingReports = false;
  bool _isExportingPendingReports = false;
  bool _isClearingSentReports = false;
  bool _isPendingReportsExpanded = false;
  bool _isSentReportsExpanded = false;
  String? _sendingPendingReportId;

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  @override
  void dispose() {
    _librarySelectionBloc.close();
    super.dispose();
  }

  Future<void> _loadVersionInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final dataService = DataCollectionService();
    String? libVersion = await dataService.readLibraryVersion();
    if (libVersion == 'unknown') libVersion = 'לא ידוע'.tr();

    int? count;
    try {
      final library = await DataRepository.instance.library;
      count = library.getAllBooks().length;
    } catch (_) {
      count = 0;
    }

    if (!mounted) return;
    setState(() {
      _appVersion = packageInfo.version;
      _libraryVersion = libVersion;
      _bookCount = count;
    });
  }

  Future<void> _openBooksListDialog(BuildContext context) async {
    try {
      final library = await DataRepository.instance.library;
      if (!context.mounted) return;
      await showBooksListDialog(
        context: context,
        books: library.getAllBooks(),
      );
    } catch (e) {
      if (!mounted) return;
      UiSnack.showError(
          'שגיאה בטעינת רשימת הספרים: {error}'.tr(args: {'error': '$e'}));
    }
  }

  bool _shouldInclude(String key) =>
      _selectedBackupMode == _BackupMode.all ||
      (Settings.getValue<bool>(key) ?? true);

  Future<void> _editSenderEmail() async {
    final reportService = DirectErrorReportService();
    final email = await showErrorReportSenderEmailDialog(
      context: context,
      initialValue: reportService.senderEmail,
    );

    if (email == null) {
      return;
    }

    if (!DirectErrorReportService.isValidSenderEmail(email)) {
      UiSnack.showError('יש להזין כתובת דוא"ל תקינה.'.tr());
      return;
    }

    await reportService.saveSenderEmail(email);
    if (!mounted) return;
    setState(() {});
    UiSnack.showSuccess('כתובת הזיהוי נשמרה. ניתן לשנות אותה בהגדרות.'.tr());
  }

  Future<void> _clearSenderEmail() async {
    await DirectErrorReportService().clearSenderEmail();
    if (!mounted) return;
    setState(() {});
    UiSnack.show('כתובת הזיהוי הוסרה.'.tr());
  }

  Future<void> _flushPendingReports() async {
    setState(() {
      _isFlushingPendingReports = true;
    });

    final reportService = DirectErrorReportService();
    final pendingBefore = await reportService.getPendingReportsCount();
    final sentCount = await reportService.flushPendingReports();
    final pendingAfter = await reportService.getPendingReportsCount();

    if (!mounted) return;
    setState(() {
      _isFlushingPendingReports = false;
    });

    if (sentCount > 0) {
      UiSnack.showSuccess(
          'נשלחו {count} דיווחים ממתינים.'.tr(args: {'count': '$sentCount'}));
    } else if (pendingBefore == 0) {
      UiSnack.show('לא נמצאו דיווחים שמורים לשליחה.'.tr());
    } else {
      UiSnack.show(
        'לא ניתן לשלוח כרגע את הדיווחים השמורים. עדיין שמורים בתור {count} דיווחים, וניתן לנהל אותם בהגדרות.'
            .tr(args: {'count': '$pendingAfter'}),
      );
    }
  }

  Future<void> _sendPendingReport(DirectErrorReport report) async {
    setState(() {
      _sendingPendingReportId = report.id;
    });

    DirectReportDeliveryResult? result;
    try {
      result = await DirectErrorReportService().submitPendingReport(report);
    } catch (e) {
      debugPrint('Failed to send pending direct report: $e');
      if (mounted) {
        UiSnack.showError(
            'שגיאה בשליחת הדיווח: {error}'.tr(args: {'error': e.toString()}));
      }
      return;
    } finally {
      if (mounted) {
        setState(() {
          _sendingPendingReportId = null;
        });
      }
    }

    if (!mounted) return;
    if (result.isSent) {
      await ErrorReportHelper.showDirectReportDetailsDialog(
        context,
        title: 'הדיווח נשלח בהצלחה'.tr(),
        report: report,
      );
      if (!mounted) return;
      setState(() {});
    } else if (result.isQueued) {
      UiSnack.show(result.message);
    } else {
      UiSnack.showError(result.message);
    }
  }

  Future<void> _editPendingReport(DirectErrorReport report) async {
    var editValues = _PendingReportEditValues(
      selectedText: report.selectedText,
      errorDetails: report.errorDetails,
      contextText: report.contextText,
    );

    final confirmed = await showTwoActionsDialog(
      context: context,
      title: 'עריכת דיווח שמור'.tr(),
      content: '',
      cancelText: 'ביטול'.tr(),
      confirmText: 'שמור'.tr(),
      handleEnterKey: false,
      customContent: SizedBox(
        width: 560,
        child: _PendingReportEditFields(
          initialValues: editValues,
          onChanged: (values) => editValues = values,
        ),
      ),
    );

    if (confirmed == true) {
      await DirectErrorReportService().updatePendingReport(
        report.copyWith(
          selectedText: editValues.selectedText.trim(),
          errorDetails: editValues.errorDetails.trim(),
          contextText: editValues.contextText.trim(),
        ),
      );
      if (!mounted) return;
      setState(() {});
      UiSnack.showSuccess('הדיווח עודכן.'.tr());
    }
  }

  Future<void> _showReportDetails(
    DirectErrorReport report, {
    required bool sent,
  }) async {
    await ErrorReportHelper.showDirectReportDetailsDialog(
      context,
      title: sent ? 'פרטי דיווח שנשלח'.tr() : 'פרטי דיווח שמור'.tr(),
      report: report,
    );
  }

  Future<void> _deletePendingReport(DirectErrorReport report) async {
    await DirectErrorReportService().deletePendingReport(report.id);
    if (!mounted) return;
    setState(() {});
    UiSnack.show('הדיווח הוסר מהתור.'.tr());
  }

  Future<void> _deleteSentReport(DirectErrorReport report) async {
    await DirectErrorReportService().deleteSentReport(report.id);
    if (!mounted) return;
    setState(() {});
    UiSnack.show('הדיווח נמחק מההיסטוריה.'.tr());
  }

  Future<void> _clearSentReports() async {
    final confirmed = await showWarningDialog(
      context: context,
      title: 'לנקות את היסטוריית הדיווחים?'.tr(),
      content: 'כל הדיווחים שנשלחו יימחקו מההיסטוריה המקומית.'.tr(),
      subtitle: 'הפעולה לא מוחקת דיווחים שכבר נשלחו לצוות.'.tr(),
      cancelText: 'ביטול'.tr(),
      confirmText: 'נקה'.tr(),
    );
    if (confirmed != true) {
      return;
    }

    setState(() {
      _isClearingSentReports = true;
    });

    await DirectErrorReportService().clearSentReports();

    if (!mounted) return;
    setState(() {
      _isClearingSentReports = false;
    });
    UiSnack.show('היסטוריית הדיווחים נוקתה.'.tr());
  }

  Future<void> _clearPendingReports() async {
    final confirmed = await showWarningDialog(
      context: context,
      title: 'למחוק דיווחים שמורים?'.tr(),
      content: 'כל הדיווחים השמורים בתור יימחקו מהמחשב.'.tr(),
      subtitle: 'לא ניתן לשחזר דיווחים שנמחקו.'.tr(),
      cancelText: 'ביטול'.tr(),
      confirmText: 'מחק'.tr(),
    );
    if (confirmed != true) {
      return;
    }

    setState(() {
      _isClearingPendingReports = true;
    });

    await DirectErrorReportService().clearPendingReports();

    if (!mounted) return;
    setState(() {
      _isClearingPendingReports = false;
    });
    UiSnack.show('הדיווחים השמורים נמחקו.'.tr());
  }

  Future<void> _exportPendingReportsScript() async {
    final verified = await verifyPasswordForAction(context);
    if (!verified) {
      return;
    }

    final reportService = DirectErrorReportService();
    final reports = await reportService.getPendingReports();
    if (reports.isEmpty) {
      if (!mounted) return;
      UiSnack.show('אין דיווחים שמורים לייצוא.'.tr());
      return;
    }

    final downloadsDirectory = await getDownloadsDirectory();
    final path = await FilePicker.saveFile(
      dialogTitle: 'בחר מיקום לשמירת סקריפט השליחה'.tr(),
      fileName: 'otzaria_send_saved_reports.bat',
      initialDirectory: downloadsDirectory?.path,
      allowedExtensions: ['bat'],
      type: FileType.custom,
      lockParentWindow: true,
    );
    if (path == null || !mounted) {
      return;
    }

    setState(() {
      _isExportingPendingReports = true;
    });

    try {
      final script = reportService.buildOfflineSendBatchScript(reports);
      await File(path).writeAsString(script, encoding: ascii);

      if (!mounted) return;
      UiSnack.showSuccess(
        'סקריפט השליחה נשמר בהצלחה. לשליחת הדיווחים הפעילו את הקובץ במחשב מחובר.'
            .tr(),
      );
    } catch (e) {
      if (!mounted) return;
      UiSnack.showError(
          'שגיאה בשמירת הסקריפט: {error}'.tr(args: {'error': e.toString()}));
    } finally {
      if (mounted) {
        setState(() {
          _isExportingPendingReports = false;
        });
      }
    }
  }

  Widget _buildManagedActionButton({
    required bool enabled,
    required Widget child,
  }) {
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: child,
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return BlocListener<EmptyLibraryBloc, EmptyLibraryState>(
          bloc: _librarySelectionBloc,
          listener: (context, librarySelectionState) async {
            if (librarySelectionState is EmptyLibraryDirectorySelected) {
              await context.read<NavigationBloc>().refreshLibrary();
              if (!context.mounted) {
                return;
              }
              context.read<LibraryBloc>().add(RefreshLibrary());
              UiSnack.showSuccess('הספרייה נטענה בהצלחה.'.tr());
            }

            if (librarySelectionState is EmptyLibraryError &&
                librarySelectionState.errorMessage != null) {
              UiSnack.showError(librarySelectionState.errorMessage!);
            }

            if (librarySelectionState is EmptyLibraryAskingDbCopy) {
              if (librarySelectionState.errorMessage != null) {
                UiSnack.showError(librarySelectionState.errorMessage!);
              }
              if (!context.mounted) {
                return;
              }
              _showLibraryDbCopyDialog(context, librarySelectionState);
            }
          },
          child: SingleChildScrollView(
            primary: true,
            padding: const EdgeInsets.all(16.0),
            child: ToolPanelWrapper(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. גרסאות + נתיב ספרייה
                  SettingsAnchor(
                    cardId: 'system.versions',
                    child: _buildVersionAndPathSection(context, state),
                  ),

                  // 2. עדכוני מערכת (רשת + עדכון מפתחים)
                  SettingsAnchor(
                    cardId: 'system.updates',
                    child: _buildSystemUpdatesSection(context, state),
                  ),

                  // 3. דיווחי טעויות
                  SettingsAnchor(
                    cardId: 'system.reports',
                    child: _buildErrorReportsSection(context, state),
                  ),

                  // 4. מתקדם (גיבוי + מצב סייפר)
                  SettingsAnchor(
                    cardId: 'system.advanced',
                    child: _buildAdvancedSection(context, state),
                  ),

                  SettingsAnchor(
                    cardId: 'system.tour',
                    child: _buildGuidedTourSection(context),
                  ),

                  // 6. איפוס
                  SettingsAnchor(
                    cardId: 'system.reset',
                    child: _buildResetSection(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  2. עדכוני מערכת (רשת + עדכון מפתחים)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildSystemUpdatesSection(BuildContext context, SettingsState state) {
    return SettingsCard(
      title: 'עדכוני מערכת'.tr(),
      children: [
        KeyedSubtree(
          key: _networkModeTileKey,
          child: SegmentedSettingsTile<bool>(
            icon: FluentIcons.globe_24_regular,
            title: 'סינכרון ומצב רשת'.tr(),
            subtitle: state.isOfflineMode
                ? 'התוכנה מנותקת לגמרי מהרשת'.tr()
                : 'התוכנה יכולה להתחבר לרשת'.tr(),
            options: [
              SegmentOption<bool>(
                value: false,
                label: 'מקוון'.tr(),
                icon: FluentIcons.wifi_1_24_regular,
              ),
              SegmentOption<bool>(
                value: true,
                label: 'מנותק'.tr(),
                icon: FluentIcons.wifi_off_24_regular,
              ),
            ],
            currentValue: state.isOfflineMode,
            onChanged: (value) {
              context.read<SettingsBloc>().add(UpdateOfflineMode(value));
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                final ctx = _networkModeTileKey.currentContext;
                if (ctx != null) {
                  Scrollable.ensureVisible(ctx,
                      duration: const Duration(milliseconds: 200),
                      alignment: 0.0);
                }
              });
            },
          ),
        ),
        SwitchListTile(
          secondary: const Icon(FluentIcons.arrow_download_24_regular),
          title: Text(
            'עדכוני תוכנה וספרים'.tr(),
            style: const TextStyle(fontSize: 16),
            textDirection: AppTranslations.textDirection,
          ),
          subtitle: Text(
            state.isOfflineMode
                ? 'מושבת במצב מנותק'.tr()
                : state.softwareAndBookUpdatesEnabled
                    ? 'עדכוני תוכנה וספרים פעילים, אך דיווחי שגיאות ימשיכו לעבוד גם אם תכבו אותם'
                        .tr()
                    : 'עדכוני תוכנה וספרים מושבתים, אך שאר שירותי הרשת נשארים פעילים'
                        .tr(),
            style: const TextStyle(fontSize: 13),
            textDirection: AppTranslations.textDirection,
          ),
          value: state.canUseSoftwareAndBookUpdates,
          onChanged: state.isOfflineMode
              ? null
              : (value) {
                  context.read<SettingsBloc>().add(
                        UpdateSoftwareAndBookUpdatesEnabled(value),
                      );
                },
        ),
        if (!(Platform.isAndroid || Platform.isIOS) &&
            state.canUseSoftwareAndBookUpdates) ...[
          SwitchListTile(
            secondary: const Icon(FluentIcons.arrow_sync_24_regular),
            title: Text(
              'סינכרון הספרייה באופן אוטומטי'.tr(),
              style: const TextStyle(fontSize: 16),
              textDirection: AppTranslations.textDirection,
            ),
            subtitle: Text(
              (Settings.getValue<bool>(SettingsRepository.keyAutoSync) ?? true)
                  ? 'מסד הנתונים של הספרייה יתעדכן אוטומטית'.tr()
                  : 'סינכרון הספרייה מושבת'.tr(),
              style: const TextStyle(fontSize: 13),
              textDirection: AppTranslations.textDirection,
            ),
            value:
                Settings.getValue<bool>(SettingsRepository.keyAutoSync) ?? true,
            onChanged: (value) {
              Settings.setValue<bool>(SettingsRepository.keyAutoSync, value);
              setState(() {});
            },
          ),
          SwitchSettingsTile(
            leading: const Icon(FluentIcons.bug_24_regular),
            title:
                Text('עדכון לגרסאות מפתחים'.tr(), style: kSettingsTitleStyle),
            subtitle: Text(
              Settings.getValue<bool>(SettingsRepository.keyDevChannel) ?? false
                  ? 'קבלת עדכונים על גרסאות בדיקה — ייתכנו באגים'.tr()
                  : 'קבלת עדכונים על גרסאות יציבות בלבד'.tr(),
              style: kSettingsSubtitleStyle,
            ),
            value: Settings.getValue<bool>(SettingsRepository.keyDevChannel) ??
                false,
            onChanged: (value) {
              Settings.setValue<bool>(SettingsRepository.keyDevChannel, value);
              setState(() {});
            },
          ),
        ],
      ],
    );
  }

  Widget _buildErrorReportsSection(BuildContext context, SettingsState state) {
    final reportService = DirectErrorReportService();
    final senderEmail = reportService.senderEmail;
    final queueWhenOffline = reportService.queueWhenOfflineEnabled;

    return SettingsCard(
      title: 'דיווחי טעויות'.tr(),
      subtitle: 'שליחה ישירה לצוות אוצריא, כולל תור אוטומטי במצב אופליין.'.tr(),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < LayoutBreakpoints.compact;
            final titleWidget =
                Text('כתובת מייל לזיהוי'.tr(), style: kSettingsTitleStyle);
            final subtitleWidget = Text(
              senderEmail.isEmpty
                  ? 'עדיין לא הוגדרה כתובת זיהוי'.tr()
                  : senderEmail,
              style: kSettingsSubtitleStyle,
              textDirection: TextDirection.ltr,
            );
            final actionsRow = Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (senderEmail.isNotEmpty)
                  NeutralActionButton(
                    text: 'נקה'.tr(),
                    onPressed: _clearSenderEmail,
                  ),
                RecommendedActionButton(
                  text: senderEmail.isEmpty ? 'הגדר'.tr() : 'ערוך'.tr(),
                  onPressed: _editSenderEmail,
                ),
              ],
            );

            if (!isNarrow) {
              return ListTile(
                leading: const Icon(FluentIcons.mail_24_regular),
                title: titleWidget,
                subtitle: subtitleWidget,
                trailing: actionsRow,
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2, left: 16),
                        child: Icon(FluentIcons.mail_24_regular),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            titleWidget,
                            const SizedBox(height: 4),
                            subtitleWidget,
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: actionsRow,
                  ),
                ],
              ),
            );
          },
        ),
        SwitchListTile(
          secondary: const Icon(FluentIcons.cloud_arrow_up_24_regular),
          title: Text(
            'שמירת דיווחים אוטומטית כשאין חיבור'.tr(),
            style: const TextStyle(fontSize: 16),
            textDirection: AppTranslations.textDirection,
          ),
          subtitle: Text(
            queueWhenOffline
                ? 'דיווחים שלא נשלחו יישמרו ויישלחו אוטומטית בהמשך'.tr()
                : 'במצב אופליין לא יתבצע תור אוטומטי לדיווחים ישירים'.tr(),
            style: const TextStyle(fontSize: 13),
            textDirection: AppTranslations.textDirection,
          ),
          value: queueWhenOffline,
          onChanged: (value) async {
            await reportService.setQueueWhenOfflineEnabled(value);
            if (!mounted) return;
            setState(() {});
          },
        ),
        FutureBuilder<List<List<DirectErrorReport>>>(
          future: Future.wait([
            reportService.getPendingReports(),
            reportService.getSentReports(),
          ]),
          builder: (context, snapshot) {
            final pendingReports =
                snapshot.data?.first ?? const <DirectErrorReport>[];
            final sentReports =
                snapshot.data?.last ?? const <DirectErrorReport>[];
            final pendingCount = pendingReports.length;
            final hasReports = pendingCount > 0;

            return Column(
              children: [
                ListTile(
                  leading: const Icon(FluentIcons.task_list_ltr_24_regular),
                  title: Text('ניהול דיווחים שמורים'.tr(),
                      style: kSettingsTitleStyle),
                  subtitle: Text(
                    pendingCount == 0
                        ? 'אין כרגע דיווחים שמורים בתור'.tr()
                        : 'יש כרגע {count} דיווחים שמורים בתור'
                            .tr(args: {'count': '$pendingCount'}),
                    style: kSettingsSubtitleStyle,
                    textDirection: AppTranslations.textDirection,
                  ),
                  trailing: Icon(
                    _isPendingReportsExpanded
                        ? FluentIcons.chevron_up_24_regular
                        : FluentIcons.chevron_down_24_regular,
                  ),
                  onTap: () => setState(
                    () =>
                        _isPendingReportsExpanded = !_isPendingReportsExpanded,
                  ),
                ),
                AnimatedSize(
                  duration: AppTokens.animNormal,
                  curve: Curves.easeInOut,
                  child: _isPendingReportsExpanded
                      ? Column(
                          children: [
                            if (hasReports)
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: 16,
                                  left: 16,
                                  top: 8,
                                  bottom: 16,
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isNarrow = constraints.maxWidth <
                                        LayoutBreakpoints.compact;
                                    final sendButton =
                                        _buildManagedActionButton(
                                      enabled: !state.isOfflineMode,
                                      child: RecommendedActionButton(
                                        text: 'שלח עכשיו'.tr(),
                                        icon: FluentIcons.arrow_sync_24_regular,
                                        onPressed: _flushPendingReports,
                                        isLoading: _isFlushingPendingReports,
                                      ),
                                    );
                                    final clearButton =
                                        _buildManagedActionButton(
                                      enabled: hasReports,
                                      child: NeutralActionButton(
                                        text: 'נקה דיווחים'.tr(),
                                        icon: FluentIcons.delete_24_regular,
                                        onPressed: _clearPendingReports,
                                        isLoading: _isClearingPendingReports,
                                      ),
                                    );
                                    final exportButton =
                                        _buildManagedActionButton(
                                      enabled: hasReports,
                                      child: NeutralActionButton(
                                        text: 'הורד לשליחה במחשב מחובר'.tr(),
                                        icon: FluentIcons
                                            .arrow_download_24_regular,
                                        onPressed: _exportPendingReportsScript,
                                        isLoading: _isExportingPendingReports,
                                      ),
                                    );

                                    if (isNarrow) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          sendButton,
                                          const SizedBox(height: 8),
                                          clearButton,
                                          const SizedBox(height: 8),
                                          exportButton,
                                        ],
                                      );
                                    }

                                    return Row(
                                      children: [
                                        Expanded(child: sendButton),
                                        const SizedBox(width: 12),
                                        Expanded(child: clearButton),
                                        const SizedBox(width: 12),
                                        Expanded(child: exportButton),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            if (state.isOfflineMode)
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: 16,
                                  left: 16,
                                  bottom: 16,
                                ),
                                child: Text(
                                  'במצב מנותק אי אפשר לשלוח כעת, אך ניתן להוריד סקריפט לשליחה ממחשב מחובר.'
                                      .tr(),
                                  style: kSettingsSubtitleStyle,
                                  textDirection: AppTranslations.textDirection,
                                ),
                              ),
                            if (pendingReports.isNotEmpty)
                              ...pendingReports.map(
                                (report) => _buildPendingReportTile(
                                  context,
                                  report,
                                  canSend: !state.isOfflineMode,
                                ),
                              ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
                ListTile(
                  leading: const Icon(FluentIcons.checkmark_circle_24_regular),
                  title:
                      Text('דיווחים שנשלחו'.tr(), style: kSettingsTitleStyle),
                  subtitle: Text(
                    sentReports.isEmpty
                        ? 'עדיין אין דיווחים שנשלחו דרך המערכת'.tr()
                        : 'נשמרו {count} דיווחים שנשלחו'
                            .tr(args: {'count': '${sentReports.length}'}),
                    style: kSettingsSubtitleStyle,
                    textDirection: AppTranslations.textDirection,
                  ),
                  trailing: Icon(
                    _isSentReportsExpanded
                        ? FluentIcons.chevron_up_24_regular
                        : FluentIcons.chevron_down_24_regular,
                  ),
                  onTap: () => setState(
                    () => _isSentReportsExpanded = !_isSentReportsExpanded,
                  ),
                ),
                AnimatedSize(
                  duration: AppTokens.animNormal,
                  curve: Curves.easeInOut,
                  child: _isSentReportsExpanded
                      ? Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                right: 16,
                                left: 16,
                                bottom: 16,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildManagedActionButton(
                                      enabled: sentReports.isNotEmpty,
                                      child: NeutralActionButton(
                                        text: 'נקה את כל ההיסטוריה'.tr(),
                                        icon: FluentIcons.delete_24_regular,
                                        onPressed: _clearSentReports,
                                        isLoading: _isClearingSentReports,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (sentReports.isNotEmpty)
                              ...sentReports.map(
                                (report) =>
                                    _buildSentReportTile(context, report),
                              ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPendingReportTile(
    BuildContext context,
    DirectErrorReport report, {
    required bool canSend,
  }) {
    final isSending = _sendingPendingReportId == report.id;
    return Column(
      children: [
        ListTile(
          leading: const Icon(FluentIcons.document_bullet_list_24_regular),
          title: Text(
            report.bookTitle,
            style: kSettingsTitleStyle,
            textDirection: TextDirection.rtl,
          ),
          subtitle: Text(
            '${report.currentRef} · ${report.errorDetails.isEmpty ? 'ללא פירוט'.tr() : report.errorDetails}',
            style: kSettingsSubtitleStyle,
            textDirection: TextDirection.rtl,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildReportActions(
          children: [
            NeutralActionButton(
              text: 'צפה'.tr(),
              icon: FluentIcons.eye_24_regular,
              onPressed: () => _showReportDetails(report, sent: false),
            ),
            NeutralActionButton(
              text: 'ערוך'.tr(),
              icon: FluentIcons.edit_24_regular,
              onPressed: () => _editPendingReport(report),
            ),
            NeutralActionButton(
              text: 'מחק'.tr(),
              icon: FluentIcons.delete_24_regular,
              onPressed: () => _deletePendingReport(report),
            ),
            _buildManagedActionButton(
              enabled: canSend,
              child: RecommendedActionButton(
                text: 'שלח'.tr(),
                icon: FluentIcons.send_24_regular,
                isLoading: isSending,
                onPressed: () => _sendPendingReport(report),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSentReportTile(BuildContext context, DirectErrorReport report) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(FluentIcons.checkmark_24_regular),
          title: Text(
            report.bookTitle,
            style: kSettingsTitleStyle,
            textDirection: TextDirection.rtl,
          ),
          subtitle: Text(
            '${report.currentRef} · ${report.errorDetails.isEmpty ? 'ללא פירוט'.tr() : report.errorDetails}',
            style: kSettingsSubtitleStyle,
            textDirection: TextDirection.rtl,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildReportActions(
          children: [
            NeutralActionButton(
              text: 'צפה'.tr(),
              icon: FluentIcons.eye_24_regular,
              onPressed: () => _showReportDetails(report, sent: true),
            ),
            NeutralActionButton(
              text: 'מחק'.tr(),
              icon: FluentIcons.delete_24_regular,
              onPressed: () => _deleteSentReport(report),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportActions({
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 56, left: 16, bottom: 12),
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: children,
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  2. גרסאות + נתיב ספרייה
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildVersionAndPathSection(
      BuildContext context, SettingsState state) {
    return SettingsCard(
      title: 'מערכת אוצריא'.tr(),
      children: [
        ListTile(
          leading: const Icon(FluentIcons.info_24_regular),
          title: Text('גרסת תוכנה'.tr(), style: kSettingsTitleStyle),
          subtitle: Text(_appVersion ?? 'טוען...'.tr(),
              style: kSettingsSubtitleStyle),
          trailing: TextButton.icon(
            icon: const Icon(FluentIcons.history_24_regular, size: 16),
            label: Text('יומן שינויים'.tr()),
            onPressed: () => _showChangelogDialog(context),
          ),
        ),
        ListTile(
          leading: const Icon(FluentIcons.library_24_regular),
          title: Text('גרסת ספרייה'.tr(), style: kSettingsTitleStyle),
          subtitle: Text(_libraryVersion ?? 'טוען...'.tr(),
              style: kSettingsSubtitleStyle),
          // trailing: TextButton.icon(
          //   icon: const Icon(FluentIcons.history_24_regular, size: 16),
          //   label: const Text('יומן שינויים'),
          //   onPressed: () => _showLibraryChangelogDialog(context),
          // ),
        ),
        ListTile(
          hoverColor: Colors.transparent,
          leading: const Icon(FluentIcons.book_24_regular),
          title: Text('מספר ספרים'.tr(), style: kSettingsTitleStyle),
          subtitle: Text(
            _bookCount != null
                ? '{count} ספרים'.tr(args: {'count': '${_bookCount!}'})
                : 'טוען...'.tr(),
            style: kSettingsSubtitleStyle,
          ),
          trailing: _bookCount == null
              ? null
              : TextButton.icon(
                  icon: const Icon(FluentIcons.list_24_regular, size: 16),
                  label: Text('הצג רשימה'.tr()),
                  onPressed: () => _openBooksListDialog(context),
                ),
        ),
      ],
    );
  }

  void _showLibraryDbCopyDialog(
    BuildContext context,
    EmptyLibraryAskingDbCopy state,
  ) async {
    final sizeText = state.dbSizeBytes > 0
        ? '${(state.dbSizeBytes / 1024 / 1024).toStringAsFixed(1)} MB'
        : 'לא ידוע'.tr();

    final shouldMove = await showDbCopyRequiredDialog(
      context: context,
      sizeText: sizeText,
    );

    if (shouldMove == null) {
      return;
    }

    _librarySelectionBloc.add(
      PickDbFileRequested(
        libraryPath: state.libraryPath,
        internalDbPath: state.internalDbPath,
        externalDbPath: state.externalDbPath,
        shouldMove: shouldMove,
      ),
    );
  }

  Future<void> _createBackup() async {
    try {
      final result = await BackupService.createBackup(
        includeSettings: _shouldInclude(_keyBackupSettings),
        includeBookmarks: _shouldInclude(_keyBackupBookmarks),
        includeHistory: _shouldInclude(_keyBackupHistory),
        includeNotes: _shouldInclude(_keyBackupNotes),
        includeWorkspaces: _shouldInclude(_keyBackupWorkspaces),
        includeShamorZachor: _shouldInclude(_keyBackupShamorZachor),
        includeUserOverrides: _shouldInclude(_keyBackupUserOverrides),
        includePlugins: _shouldInclude(_keyBackupPlugins),
      );
      if (!mounted) return;
      final backupPath = result.path;
      final file = File(backupPath);
      final exists = await file.exists();
      final size = exists ? await file.length() : 0;
      if (!mounted) return;
      if (exists) {
        final partial = result.skippedSections.isNotEmpty;
        final sizeStr = '${(size / 1024).toStringAsFixed(1)} KB';
        final message = partial
            ? 'גיבוי חלקי נשמר ({size}) — חסרים: {sections}'.tr(args: {
                'size': sizeStr,
                'sections': result.skippedSections.join(", "),
              })
            : 'הגיבוי נשמר! גודל: {size}'.tr(args: {'size': sizeStr});
        UiSnack.showWithAction(
          message: message,
          actionLabel: 'פתח מיקום קובץ'.tr(),
          onAction: () async {
            final dir = file.parent;
            if (Platform.isWindows) {
              await Process.run('explorer', [dir.path]);
            } else if (Platform.isMacOS) {
              await Process.run('open', [dir.path]);
            } else if (Platform.isLinux) {
              await Process.run('xdg-open', [dir.path]);
            }
          },
          icon: Icons.check_circle_outline_rounded,
        );
      }
    } catch (e) {
      if (!mounted) return;
      UiSnack.showError(
          'שגיאה ביצירת הגיבוי: {error}'.tr(args: {'error': e.toString()}));
    }
  }

  Future<void> _restoreBackup() async {
    final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        lockParentWindow: true);
    final filePath = result?.files.single.path;
    if (filePath == null) return;
    if (!mounted) return;

    final confirmed = await showWarningDialog(
      context: context,
      title: 'שחזור מגיבוי?'.tr(),
      content: 'פעולה זו תחליף את הנתונים הקיימים בנתונים מהגיבוי.'.tr(),
      subtitle: 'פעולה זו אינה הפיכה!'.tr(),
      cancelText: 'ביטול'.tr(),
      confirmText: 'שחזר'.tr(),
    );
    if (confirmed != true) return;

    try {
      final skipped = await BackupService.restoreFromBackup(filePath);
      if (!mounted) return;
      final content = skipped.isEmpty
          ? 'הנתונים שוחזרו בהצלחה. האפליקציה תיטען מחדש כעת.'.tr()
          : 'שחזור חלקי — חסרים בקובץ הגיבוי: {sections}.\nהאפליקציה תיטען מחדש כעת.'
              .tr(args: {'sections': skipped.join(", ")});
      await showSingleActionDialog(
        context: context,
        title: skipped.isEmpty ? 'השחזור הושלם'.tr() : 'שחזור חלקי'.tr(),
        content: content,
        confirmText: 'טען מחדש'.tr(),
      );
      if (!mounted) return;
      await resetRuntimeStateForAppRestart();
      if (!mounted) return;
      RestartWidget.restartApp(
        context,
        afterRestart: WebViewEnvironmentHolder.disposeForAppRestart,
      );
    } catch (e) {
      if (!mounted) return;
      UiSnack.showError(
          'שגיאה בשחזור הגיבוי: {error}'.tr(args: {'error': e.toString()}));
    }
  }

  Future<void> _handleToggleProtectedMode(
    BuildContext context,
    SettingsRepository repository,
    bool newValue,
  ) async {
    if (!newValue) {
      final verified = await showDialog<bool>(
        context: context,
        builder: (context) => PasswordVerificationDialog(
          title: 'אמת סיסמה'.tr(),
          hint: 'הזן את הסיסמה כדי להשבית את המצב המוגן'.tr(),
          onVerify: (password) async =>
              repository.verifyProtectedModePassword(password),
        ),
      );
      if (verified != true) return;
    }
    if (context.mounted) {
      context.read<SettingsBloc>().add(UpdateProtectedModeEnabled(newValue));
      if (!newValue) UiSnack.show('המצב המוגן הושבת'.tr());
    }
  }

  Future<void> _handleSetPassword(
    BuildContext context,
    SettingsRepository repository,
    bool hasExistingPassword,
  ) async {
    if (hasExistingPassword) {
      final verified = await showDialog<bool>(
        context: context,
        builder: (context) => PasswordVerificationDialog(
          title: 'אמת סיסמה נוכחית'.tr(),
          hint: 'הזן את הסיסמה הנוכחית כדי לשנות אותה'.tr(),
          onVerify: (password) async =>
              repository.verifyProtectedModePassword(password),
        ),
      );
      if (verified != true) return;
    }
    if (!context.mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SetPasswordDialog(
        onSetPassword: (password) async {
          context
              .read<SettingsBloc>()
              .add(UpdateProtectedModePassword(password));
        },
      ),
    );
    if (result == true && context.mounted && !hasExistingPassword) {
      context.read<SettingsBloc>().add(const UpdateProtectedModeEnabled(true));
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  4. מתקדם (גיבוי + מצב סייפר)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildAdvancedSection(BuildContext context, SettingsState state) {
    final autoFrequency =
        Settings.getValue<String>(_keyAutoBackupFrequency) ?? 'none';
    final repository = RepositoryProvider.of<SettingsRepository>(context);
    final hasPassword = repository.hasProtectedModePassword();

    return SettingsCard(
      title: 'מתקדם'.tr(),
      children: [
        // ── גיבוי אוטומטי ──
        // שורה ראשית — לחיצה פותחת/סוגרת
        KeyedSubtree(
          key: tourBackupSettingsTargetKey,
          child: InkWell(
            onTap: () => setState(() => _isBackupExpanded = !_isBackupExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(FluentIcons.calendar_clock_24_regular),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'גיבוי אוטומטי'.tr(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  // SegmentedButton לבחירת תדירות
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                    segments: [
                      ButtonSegment<String>(
                        value: 'none',
                        label: Text('ללא'.tr()),
                      ),
                      ButtonSegment<String>(
                        value: 'weekly',
                        label: Text('שבועי'.tr()),
                      ),
                      ButtonSegment<String>(
                        value: 'monthly',
                        label: Text('חודשי'.tr()),
                      ),
                    ],
                    selected: {autoFrequency},
                    onSelectionChanged: (Set<String> newSelection) {
                      Settings.setValue<String>(
                          _keyAutoBackupFrequency, newSelection.first);
                      setState(() {});
                    },
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    _isBackupExpanded
                        ? FluentIcons.chevron_up_24_regular
                        : FluentIcons.chevron_down_24_regular,
                  ),
                ],
              ),
            ),
          ),
        ),

        // תוכן מורחב של גיבוי — אנימציה
        AnimatedSize(
          duration: AppTokens.animNormal,
          curve: Curves.easeInOut,
          child: _isBackupExpanded
              ? Column(
                  children: [
                    SegmentedSettingsTile<_BackupMode>(
                      icon: FluentIcons.options_24_regular,
                      title: 'מצב גיבוי'.tr(),
                      options: [
                        SegmentOption<_BackupMode>(
                          value: _BackupMode.all,
                          label: 'גבה הכל'.tr(),
                        ),
                        SegmentOption<_BackupMode>(
                          value: _BackupMode.custom,
                          label: 'מותאם אישית'.tr(),
                        ),
                      ],
                      currentValue: _selectedBackupMode,
                      onChanged: (value) =>
                          setState(() => _selectedBackupMode = value),
                    ),

                    // בחר מה לגבות (רק במצב מותאם אישית)
                    if (_selectedBackupMode == _BackupMode.custom) ...[
                      _BackupOptionTile(
                        icon: FluentIcons.settings_24_regular,
                        title: 'הגדרות'.tr(),
                        subtitle: 'כולל את כלל הגדרות התוכנה'.tr(),
                        settingKey: _keyBackupSettings,
                        onChanged: () => setState(() {}),
                      ),
                      _BackupOptionTile(
                        icon: FluentIcons.bookmark_24_regular,
                        title: 'סימניות'.tr(),
                        subtitle: 'כל הסימניות שנשמרו'.tr(),
                        settingKey: _keyBackupBookmarks,
                        onChanged: () => setState(() {}),
                      ),
                      _BackupOptionTile(
                        icon: FluentIcons.history_24_regular,
                        title: 'היסטוריה'.tr(),
                        subtitle: 'היסטוריית הלימוד'.tr(),
                        settingKey: _keyBackupHistory,
                        onChanged: () => setState(() {}),
                      ),
                      _BackupOptionTile(
                        icon: FluentIcons.note_24_regular,
                        title: 'הערות אישיות'.tr(),
                        subtitle: 'כל ההערות האישיות שלך'.tr(),
                        settingKey: _keyBackupNotes,
                        onChanged: () => setState(() {}),
                      ),
                      _BackupOptionTile(
                        icon: FluentIcons.grid_24_regular,
                        title: 'שולחנות עבודה'.tr(),
                        subtitle: 'כל שולחנות העבודה'.tr(),
                        settingKey: _keyBackupWorkspaces,
                        onChanged: () => setState(() {}),
                      ),
                      _BackupOptionTile(
                        icon: FluentIcons.book_24_regular,
                        title: 'שמור וזכור'.tr(),
                        subtitle: 'ספרים ומעקב לימוד'.tr(),
                        settingKey: _keyBackupShamorZachor,
                        onChanged: () => setState(() {}),
                      ),
                      _BackupOptionTile(
                        icon: FluentIcons.document_edit_24_regular,
                        title: 'הגדרות מתקדמות'.tr(),
                        subtitle: 'הגדרות נוספות שדרסת'.tr(),
                        settingKey: _keyBackupUserOverrides,
                        onChanged: () => setState(() {}),
                      ),
                      _BackupOptionTile(
                        icon: FluentIcons.puzzle_piece_24_regular,
                        title: 'תוספים'.tr(),
                        subtitle: 'התוספים שהותקנו, הגדרותיהם ונתוניהם'.tr(),
                        settingKey: _keyBackupPlugins,
                        onChanged: () => setState(() {}),
                      ),
                    ],

                    // כפתורי צור/שחזר
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _createBackup,
                              icon: const Icon(
                                  FluentIcons.arrow_upload_24_regular),
                              label: Text('צור גיבוי עכשיו'.tr()),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _restoreBackup,
                              icon: const Icon(
                                  FluentIcons.arrow_download_24_regular),
                              label: Text('שחזר מגיבוי'.tr()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),

        // ── מצב סייפר ──
        ListTile(
          leading: Icon(
            state.protectedModeEnabled
                ? FluentIcons.shield_lock_24_filled
                : FluentIcons.shield_lock_24_regular,
            color: state.protectedModeEnabled
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          title: Text('מצב סייפר'.tr(), style: kSettingsTitleStyle),
          subtitle: Text('נעילת הגדרות'.tr(), style: kSettingsSubtitleStyle),
          trailing: Icon(
            _isCypherExpanded
                ? FluentIcons.chevron_up_24_regular
                : FluentIcons.chevron_down_24_regular,
          ),
          onTap: () => setState(() => _isCypherExpanded = !_isCypherExpanded),
        ),

        // תוכן מורחב של סייפר — אנימציה
        AnimatedSize(
          duration: AppTokens.animNormal,
          curve: Curves.easeInOut,
          child: _isCypherExpanded
              ? Column(
                  children: [
                    SwitchSettingsTile(
                      leading: Icon(
                        state.protectedModeEnabled
                            ? FluentIcons.lock_closed_24_filled
                            : FluentIcons.lock_open_24_regular,
                      ),
                      title: Text('הפעל מצב סייפר'.tr(),
                          textDirection: AppTranslations.textDirection,
                          style: kSettingsTitleStyle),
                      subtitle: Text(
                        hasPassword
                            ? 'סיסמה הוגדרה'.tr()
                            : 'יש להגדיר סיסמה תחילה'.tr(),
                        textDirection: AppTranslations.textDirection,
                        style: TextStyle(
                          fontSize: 13,
                          color: hasPassword
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                      value: state.protectedModeEnabled,
                      onChanged: hasPassword
                          ? (value) => _handleToggleProtectedMode(
                              context, repository, value)
                          : null,
                    ),

                    // הגדרת/שינוי סיסמה
                    ListTile(
                      leading: const Icon(FluentIcons.key_24_regular),
                      title: Text(
                        'סיסמה'.tr(),
                        textDirection: AppTranslations.textDirection,
                        style: kSettingsTitleStyle,
                      ),
                      trailing: RecommendedActionButton(
                        icon: FluentIcons.key_24_regular,
                        text: hasPassword ? 'שנה סיסמה'.tr() : 'בחר סיסמה'.tr(),
                        onPressed: () => _handleSetPassword(
                            context, repository, hasPassword),
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildGuidedTourSection(BuildContext context) {
    return SettingsCard(
      title: 'סיור מודרך'.tr(),
      subtitle: 'היכרות מהירה עם החלקים המרכזיים באוצריא.'.tr(),
      children: [
        ListTile(
          leading: const Icon(FluentIcons.sparkle_24_regular),
          title: Text(
            'הפעל סיור מחדש'.tr(),
            style: kSettingsTitleStyle,
            textDirection: AppTranslations.textDirection,
          ),
          subtitle: Text(
            'הסיור יוצג מההתחלה וידריך אותך במסכי האפליקציה.'.tr(),
            style: kSettingsSubtitleStyle,
            textDirection: AppTranslations.textDirection,
          ),
          trailing: RecommendedActionButton(
            icon: FluentIcons.play_24_regular,
            text: 'הפעל'.tr(),
            onPressed: () {
              final libraryLoaded =
                  !context.read<NavigationBloc>().state.isLibraryEmpty;
              context.read<NavigationBloc>().add(
                    const CheckLibrary(),
                  );
              context.read<TourCubit>().restart(libraryLoaded: libraryLoaded);
            },
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  //  6. איפוס
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildResetSection(BuildContext context) {
    return SettingsCard(
      title: 'איפוס'.tr(),
      children: [
        ListTile(
          leading: const Icon(FluentIcons.arrow_reset_24_regular),
          title: Text('איפוס הגדרות'.tr(), style: kSettingsTitleStyle),
          subtitle: Text('מחיקת כל ההגדרות וחזרה למצב ההתחלתי'.tr(),
              style: kSettingsSubtitleStyle),
          trailing: NeutralActionButton(
            icon: FluentIcons.arrow_reset_24_regular,
            text: 'אפס הגדרות'.tr(),
            onPressed: () async {
              if (shouldProtectSettings(context)) {
                final verified = await verifyPasswordForAction(context);
                if (!verified || !context.mounted) return;
              }
              if (!context.mounted) return;

              final confirmed = await showWarningDialog(
                context: context,
                title: 'איפוס הגדרות?'.tr(),
                content: 'כל ההגדרות האישיות שלך ימחקו.'.tr(),
                subtitle: 'פעולה זו אינה הפיכה!'.tr(),
                cancelText: 'ביטול'.tr(),
                confirmText: 'אפס'.tr(),
              );
              if (confirmed == true && mounted) {
                Settings.clearCache();
                await resetRuntimeStateAfterSettingsReset();
                if (!mounted) return;
                RestartWidget.restartApp(
                  this.context,
                  afterRestart: WebViewEnvironmentHolder.disposeForAppRestart,
                );
              }
            },
          ),
        ),
      ],
    );
  }

  // ── Changelog dialogs ──────────────────────────────────────────────────────

  Future<void> _showChangelogDialog(BuildContext context) async {
    String changelog;
    try {
      changelog = await rootBundle
          .loadString('assets/יומן שינויים.md'); // i18n-ignore: נתיב asset
    } catch (_) {
      changelog = 'לא נמצא קובץ יומן שינויים.'.tr();
    }
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('יומן שינויים בתוכנה'.tr()),
          content: SizedBox(
            width: 600,
            height: 400,
            child: Markdown(
              data: changelog,
              onTapLink: (text, href, title) {
                if (href != null) launchUrl(Uri.parse(href));
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: Text('סגור'.tr())),
          ],
        ),
      ),
    );
  }

  // Future<void> _showLibraryChangelogDialog(BuildContext context) async {
  //   final changelogPath = p.join(DatabaseConstants.getDatabaseDirectoryPath(),
  //       'אודות התוכנה', 'עדכוני ספריה.md');
  //   final file = File(changelogPath);
  //   final changelog = (await file.exists())
  //       ? await file.readAsString()
  //       : 'קובץ יומן השינויים לא נמצא.';
  //   if (!context.mounted) return;
  //   showDialog(
  //     context: context,
  //     builder: (ctx) => Directionality(
  //       textDirection: TextDirection.rtl,
  //       child: AlertDialog(
  //         title: const Text('יומן שינויים בספרייה'),
  //         content: SizedBox(
  //           width: 600,
  //           height: 400,
  //           child: Markdown(
  //             data: changelog,
  //             onTapLink: (text, href, title) {
  //               if (href != null) launchUrl(Uri.parse(href));
  //             },
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //               onPressed: () => Navigator.pop(ctx), child: const Text('סגור')),
  //         ],
  //       ),
  //     ),
  //   );
  // }
}

// ══════════════════════════════════════════════════════════════════════════════
//  כרטיסי זיכרון — עיצוב נקי ורספונסיבי למסכים, תואם M3
// ══════════════════════════════════════════════════════════════════════════════

class _PendingReportEditValues {
  final String selectedText;
  final String errorDetails;
  final String contextText;

  const _PendingReportEditValues({
    required this.selectedText,
    required this.errorDetails,
    required this.contextText,
  });

  _PendingReportEditValues copyWith({
    String? selectedText,
    String? errorDetails,
    String? contextText,
  }) {
    return _PendingReportEditValues(
      selectedText: selectedText ?? this.selectedText,
      errorDetails: errorDetails ?? this.errorDetails,
      contextText: contextText ?? this.contextText,
    );
  }
}

class _PendingReportEditFields extends StatefulWidget {
  final _PendingReportEditValues initialValues;
  final ValueChanged<_PendingReportEditValues> onChanged;

  const _PendingReportEditFields({
    required this.initialValues,
    required this.onChanged,
  });

  @override
  State<_PendingReportEditFields> createState() =>
      _PendingReportEditFieldsState();
}

class _PendingReportEditFieldsState extends State<_PendingReportEditFields> {
  late final TextEditingController _selectedTextController;
  late final TextEditingController _detailsController;
  late final TextEditingController _contextController;

  @override
  void initState() {
    super.initState();
    _selectedTextController = TextEditingController(
      text: widget.initialValues.selectedText,
    );
    _detailsController = TextEditingController(
      text: widget.initialValues.errorDetails,
    );
    _contextController = TextEditingController(
      text: widget.initialValues.contextText,
    );
  }

  @override
  void dispose() {
    _selectedTextController.dispose();
    _detailsController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  void _notifyChanged() {
    widget.onChanged(
      _PendingReportEditValues(
        selectedText: _selectedTextController.text,
        errorDetails: _detailsController.text,
        contextText: _contextController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: AppTranslations.textDirection,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RtlTextField(
            controller: _selectedTextController,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            minLines: 1,
            maxLines: 5,
            onChanged: (_) => _notifyChanged(),
            decoration: InputDecoration(
              labelText: 'הטקסט שנבחר'.tr(),
              isDense: true,
              contentPadding: const EdgeInsets.only(
                top: 12,
                bottom: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          RtlTextField(
            controller: _detailsController,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            minLines: 1,
            maxLines: 6,
            onChanged: (_) => _notifyChanged(),
            decoration: InputDecoration(
              labelText: 'פירוט הטעות'.tr(),
              isDense: true,
              contentPadding: const EdgeInsets.only(
                top: 12,
                bottom: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          RtlTextField(
            controller: _contextController,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            minLines: 1,
            maxLines: 6,
            onChanged: (_) => _notifyChanged(),
            decoration: InputDecoration(
              labelText: 'הקשר'.tr(),
              isDense: true,
              contentPadding: const EdgeInsets.only(
                top: 12,
                bottom: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── _BackupOptionTile ─────────────────────────────────────────────────────────

class _BackupOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String settingKey;
  final VoidCallback onChanged;

  const _BackupOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.settingKey,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchSettingsTile(
      leading: Icon(icon),
      title: Text(title, style: kSettingsTitleStyle),
      subtitle: Text(subtitle, style: kSettingsSubtitleStyle),
      value: Settings.getValue<bool>(settingKey) ?? true,
      onChanged: (value) {
        Settings.setValue<bool>(settingKey, value);
        onChanged();
      },
    );
  }
}

enum _BackupMode { all, custom }
