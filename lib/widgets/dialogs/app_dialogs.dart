// lib/widgets/dialogs/app_dialogs.dart
//
// דיאלוגים גנריים של האפליקציה — M3-styled.
//
// מכיל:
//  • [SingleActionDialog] — דיאלוג עם כפתור אישור בלבד
//  • [TwoActionsDialog]   — דיאלוג עם ביטול + אישור (M3 FilledButton)
//  • [WarningDialog]      — דיאלוג אזהרה: ביטול (primary), אישור (error/שקוף)
//
// **הבדל מ-ConfirmationDialog:**
//  [ConfirmationDialog] (confirmation_dialog.dart) משתמש ב-TextButton ומאפשר
//  [isDangerous] / [confirmColor] — מתאים לניווט מקלדת עם הדגשת פוקוס.
//  [TwoActionsDialog] / [WarningDialog] כאן מסוגננים לחלוטין בסגנון M3
//  FilledButton ומתאימים לדיאלוגים פשוטים ללא ניווט מקלדת מיוחד.
//
// **שימוש:**
// ```dart
// await showSingleActionDialog(context: context, title: '...', content: '...');
// await showTwoActionsDialog(context: context, title: '...', content: '...');
// await showWarningDialog(context: context, title: '...', content: '...');
// ```

import 'package:flutter/material.dart';
import 'package:otzaria/l10n/app_translations.dart';
import 'package:otzaria/l10n/tr_extension.dart';
import 'package:otzaria/widgets/misc/keyboard_dialog_navigation.dart';

// ── SingleActionDialog ────────────────────────────────────────────────────────

/// דיאלוג עם פעולה אחת (כפתור אישור בלבד)
class SingleActionDialog extends StatefulWidget {
  final dynamic title;
  final String? content;
  final Widget? customContent;
  final String confirmText;

  const SingleActionDialog({
    super.key,
    required this.title,
    this.content,
    this.customContent,
    this.confirmText = 'אישור',
  }) : assert(
          content != null || customContent != null,
          'content או customContent חייבים להיות מוגדרים', // i18n-ignore: assert מפתחים
        );

  @override
  State<SingleActionDialog> createState() => _SingleActionDialogState();
}

class _SingleActionDialogState extends State<SingleActionDialog>
    with DialogNavigationMixin {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return buildKeyboardNavigator(
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
      child: AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        title: widget.title is String
            ? Text((widget.title as String).tr())
            : widget.title,
        content: widget.customContent ?? Text(widget.content!.tr()),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: cs.primary, foregroundColor: cs.onPrimary),
            child: Text(widget.confirmText.tr()),
          ),
        ],
      ),
    );
  }
}

// ── TwoActionsDialog ──────────────────────────────────────────────────────────

/// דיאלוג עם שתי פעולות (ביטול ואישור) — סגנון M3 FilledButton
class TwoActionsDialog extends StatefulWidget {
  final dynamic title;
  final String content;
  final Widget? customContent;
  final String cancelText;
  final String confirmText;
  final bool handleEnterKey;

  const TwoActionsDialog({
    super.key,
    required this.title,
    required this.content,
    this.customContent,
    this.cancelText = 'ביטול',
    this.confirmText = 'אישור',
    this.handleEnterKey = true,
  });

  @override
  State<TwoActionsDialog> createState() => _TwoActionsDialogState();
}

class _TwoActionsDialogState extends State<TwoActionsDialog>
    with DialogNavigationMixin {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return buildKeyboardNavigator(
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
      handleEnterKey: widget.handleEnterKey,
      child: AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        title: widget.title is String
            ? Text((widget.title as String).tr())
            : widget.title,
        content: widget.customContent ?? Text(widget.content.tr()),
        actions: [
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(false),
            style: FilledButton.styleFrom(
                backgroundColor: cs.secondaryContainer,
                foregroundColor: cs.onSecondaryContainer),
            child: Text(widget.cancelText.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: cs.primary, foregroundColor: cs.onPrimary),
            child: Text(widget.confirmText.tr()),
          ),
        ],
      ),
    );
  }
}

// ── WarningDialog ─────────────────────────────────────────────────────────────

/// דיאלוג אזהרה — כפתור ביטול כהה (הפעולה הבטוחה), אישור אדום (מסוכן)
class WarningDialog extends StatefulWidget {
  final dynamic title;
  final String content;
  final String? subtitle;
  final String cancelText;
  final String confirmText;

  const WarningDialog({
    super.key,
    required this.title,
    required this.content,
    this.subtitle,
    this.cancelText = 'ביטול',
    this.confirmText = 'המשך',
  });

  @override
  State<WarningDialog> createState() => _WarningDialogState();
}

class _WarningDialogState extends State<WarningDialog>
    with DialogNavigationMixin {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return buildKeyboardNavigator(
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
      child: AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        title: widget.title is String
            ? Text((widget.title as String).tr())
            : widget.title,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.content.tr()),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 8),
              Text(widget.subtitle!.tr(),
                  style: TextStyle(color: cs.error, fontSize: 13)),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: FilledButton.styleFrom(
                backgroundColor: cs.primary, foregroundColor: cs.onPrimary),
            child: Text(widget.cancelText.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: cs.error),
            child: Text(widget.confirmText.tr()),
          ),
        ],
      ),
    );
  }
}

// ── Helper functions ──────────────────────────────────────────────────────────

Future<bool?> showSingleActionDialog({
  required BuildContext context,
  required String title,
  String? content,
  Widget? customContent,
  String confirmText = 'אישור',
  bool barrierDismissible = true,
}) =>
    showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => SingleActionDialog(
          title: title,
          content: content,
          customContent: customContent,
          confirmText: confirmText),
    );

Future<bool?> showTwoActionsDialog({
  required BuildContext context,
  required String title,
  required String content,
  Widget? customContent,
  String cancelText = 'ביטול',
  String confirmText = 'אישור',
  bool barrierDismissible = true,
  bool handleEnterKey = true,
}) =>
    showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => TwoActionsDialog(
          title: title,
          content: content,
          customContent: customContent,
          cancelText: cancelText,
          confirmText: confirmText,
          handleEnterKey: handleEnterKey),
    );

Future<bool?> showWarningDialog({
  required BuildContext context,
  required String title,
  required String content,
  String? subtitle,
  String cancelText = 'ביטול',
  String confirmText = 'המשך',
  bool barrierDismissible = true,
}) =>
    showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => WarningDialog(
          title: title,
          content: content,
          subtitle: subtitle,
          cancelText: cancelText,
          confirmText: confirmText),
    );

Future<bool?> showDbCopyRequiredDialog({
  required BuildContext context,
  required String sizeText,
  bool barrierDismissible = false,
}) =>
    showTwoActionsDialog(
      context: context,
      title: 'נדרשת העתקה של קובץ הספרייה'.tr(),
      content: '',
      barrierDismissible: barrierDismissible,
      cancelText: 'העתק (שמור מקור)'.tr(),
      confirmText: 'העתק + נסה מחק מקור'.tr(),
      customContent: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'לא ניתן לגשת ישירות לקובץ seforim.db (גודל: {size}) מכיוון שהוא נמצא באחסון חיצוני ב-Android.'
                .tr(args: {'size': sizeText}),
            textDirection: AppTranslations.textDirection,
          ),
          const SizedBox(height: 12),
          Text(
            'לחץ על כפתור למטה, נווט לאותה תיקייה ובחר את הקובץ seforim.db — האפליקציה תעתיק אותו לאחסון הפנימי.'
                .tr(),
            textDirection: AppTranslations.textDirection,
          ),
          const SizedBox(height: 6),
          Text(
            '(אפשרות "נסה מחק מקור" — ניסיון למחוק לאחר העתקה. עשויה שלא להצליח בכל גרסאות Android.)'
                .tr(),
            style: const TextStyle(fontSize: 12),
            textDirection: AppTranslations.textDirection,
          ),
        ],
      ),
    );
