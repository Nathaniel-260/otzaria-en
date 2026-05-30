import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:otzaria/core/ui_snack.dart';
import 'package:otzaria/l10n/app_translations.dart';
import 'package:otzaria/l10n/tr_extension.dart';
import 'package:otzaria/plugins/bloc/plugin_system_bloc.dart';
import 'package:otzaria/plugins/bloc/plugin_system_event.dart';
import 'package:otzaria/plugins/bloc/plugin_system_state.dart';
import 'package:otzaria/plugins/models/installed_plugin.dart';
import 'package:otzaria/plugins/models/plugin_valid_permissions.dart';
import 'package:otzaria/plugins/utils/fluent_icon_resolver.dart';
import 'package:otzaria/settings/engine/settings_bloc.dart';
import 'package:otzaria/settings/engine/settings_event.dart';
import 'package:otzaria/settings/engine/settings_state.dart';
import 'package:otzaria/settings/search/settings_anchor.dart';
import 'package:otzaria/settings/search/settings_search_models.dart';
import 'package:otzaria/settings/settings_card.dart';
import 'package:otzaria/settings/view/settings_screen.dart';
import 'package:otzaria/tools/built_in_tools_catalog.dart';
import 'package:otzaria/widgets/dialogs/app_dialogs.dart';

const String _networkAccessPermission = 'network.access';

/// פאנל ניהול כלים (מובנים + תוספים) במסך "הגדרות › כלים".
///
/// מאפשר בחירה מרובה עם סרגל פעולות עליון:
/// - הסתרה/הצגה מתוך הממשק (לשונית הכלים + פאנל הצד + nav rail).
/// - הצמדה לסרגל הניווט הראשי.
/// - לתוספים: השבתה/הפעלה, הענקת/ביטול גישה לרשת, טעינה אוטומטית בעלייה, מחיקה.
class ToolsManagementPanel extends StatefulWidget {
  const ToolsManagementPanel({super.key});

  /// פריטי חיפוש בהגדרות. נסרק על-ידי tool/generate_search_index.dart.
  static const List<SettingsSearchEntry> searchEntries = [
    SettingsSearchEntry(
      id: 'tools.management.hide',
      title: 'הסתרת כלים',
      subtitle: 'הסתר כלים מובנים או תוספים מהממשק',
      tab: SettingsTab.tools,
      cardId: 'tools.management',
      keywords: ['הסתר', 'הסתרה', 'הסתרת', 'הצג', 'מוסתר', 'כלים', 'תוספים'],
    ),
    SettingsSearchEntry(
      id: 'tools.management.pin_nav_rail',
      title: 'הצמדה לסרגל הניווט',
      subtitle: 'הצמד כלים או תוספים לסרגל הניווט הראשי',
      tab: SettingsTab.tools,
      cardId: 'tools.management',
      keywords: ['הצמד', 'הצמדה', 'ניווט', 'סרגל', 'nav rail'],
    ),
    SettingsSearchEntry(
      id: 'tools.management.plugins',
      title: 'ניהול תוספים',
      subtitle: 'השבתה, הפעלה, מחיקה והרשאות לתוספים',
      tab: SettingsTab.tools,
      cardId: 'tools.management',
      keywords: [
        'תוסף',
        'תוספים',
        'מחק',
        'מחיקה',
        'השבת',
        'השבתה',
        'הפעל',
        'הרשאות',
        'רשת',
        'אינטרנט',
        'טעינה אוטומטית',
        'בעלייה'
      ],
    ),
  ];

  @override
  State<ToolsManagementPanel> createState() => _ToolsManagementPanelState();
}

class _ToolsManagementPanelState extends State<ToolsManagementPanel> {
  /// המזהים שנבחרו כרגע — מערבב מזהי כלים מובנים ומזהי תוספים.
  final Set<String> _selectedIds = <String>{};

  bool get _anySelected => _selectedIds.isNotEmpty;

  void _toggle(String id, bool? value) {
    setState(() {
      if (value == true) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
    });
  }

  void _clearSelection() {
    setState(_selectedIds.clear);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PluginSystemBloc, PluginSystemState>(
      builder: (context, pluginState) {
        return BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, settingsState) {
            final plugins = pluginState is PluginSystemLoaded
                ? pluginState.plugins
                : const <InstalledPlugin>[];
            // ניקוי מזהים נבחרים שהוסרו (תוסף שהוסר/כלי שהוסר):
            _pruneStaleSelection(settingsState, plugins);
            return SettingsAnchor(
              cardId: 'tools.management',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_anySelected)
                    _ActionBar(
                      selectedIds: _selectedIds.toSet(),
                      plugins: plugins,
                      settingsState: settingsState,
                      onClear: _clearSelection,
                    ),
                  SettingsCard(
                    title: 'כלים מובנים'.tr(),
                    subtitle:
                        'בחר כלים כדי להסתיר מהממשק או להצמיד לסרגל הניווט הראשי.'
                            .tr(),
                    children: [
                      for (final meta in kBuiltInToolsCatalog)
                        _BuiltInToolRow(
                          meta: meta,
                          hidden: settingsState.hiddenBuiltInToolIds
                              .contains(meta.toolId),
                          pinnedToNavRail: settingsState
                              .builtInToolsPinnedToNavRail
                              .contains(meta.toolId),
                          selected: _selectedIds.contains(meta.toolId),
                          onSelectChanged: (v) => _toggle(meta.toolId, v),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (plugins.isNotEmpty)
                    SettingsCard(
                      title: 'תוספים מותקנים'.tr(),
                      subtitle:
                          'נהל את התוספים שלך: השבתה, הסתרה, הצמדה, הרשאות ומחיקה. גרור לשינוי סדר.'
                              .tr(),
                      children: [
                        for (final plugin in plugins)
                          _DraggableSettingsPluginRow(
                            key: ValueKey(plugin.pluginId),
                            plugin: plugin,
                            selected: _selectedIds.contains(plugin.pluginId),
                            onSelectChanged: (v) => _toggle(plugin.pluginId, v),
                            onAcceptSource: (sourceId) => _handleReorder(
                              context: context,
                              allPlugins: plugins,
                              sourcePluginId: sourceId,
                              targetPluginId: plugin.pluginId,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _handleReorder({
    required BuildContext context,
    required List<InstalledPlugin> allPlugins,
    required String sourcePluginId,
    required String targetPluginId,
  }) {
    final sourceIdx =
        allPlugins.indexWhere((p) => p.pluginId == sourcePluginId);
    final targetIdx =
        allPlugins.indexWhere((p) => p.pluginId == targetPluginId);
    if (sourceIdx < 0 || targetIdx < 0) return;
    final reordered = List.of(allPlugins);
    final src = reordered.removeAt(sourceIdx);
    reordered.insert(targetIdx, src);
    context.read<PluginSystemBloc>().add(
          ReorderPluginsRequested(reordered.map((p) => p.pluginId).toList()),
        );
  }

  /// מנקה מזהים נבחרים שאינם רלוונטיים עוד (תוסף שהוסר וכו'). חייב לקרות
  /// בתוך build כי הנתונים מגיעים מ-BlocBuilder.
  void _pruneStaleSelection(
    SettingsState settingsState,
    List<InstalledPlugin> plugins,
  ) {
    if (_selectedIds.isEmpty) return;
    final validIds = <String>{
      for (final m in kBuiltInToolsCatalog) m.toolId,
      for (final p in plugins) p.pluginId,
    };
    final stale = _selectedIds.difference(validIds);
    if (stale.isNotEmpty) {
      // setState אסורה ב-build; אבל אפשר להזיז את ההסרה לאחר ה-frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedIds.removeAll(stale));
      });
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// סרגל הפעולות
// ──────────────────────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final Set<String> selectedIds;
  final List<InstalledPlugin> plugins;
  final SettingsState settingsState;
  final VoidCallback onClear;

  const _ActionBar({
    required this.selectedIds,
    required this.plugins,
    required this.settingsState,
    required this.onClear,
  });

  Iterable<BuiltInToolMeta> get _selectedBuiltIns =>
      kBuiltInToolsCatalog.where((m) => selectedIds.contains(m.toolId));

  Iterable<InstalledPlugin> get _selectedPlugins =>
      plugins.where((p) => selectedIds.contains(p.pluginId));

  bool get _allBuiltIn =>
      _selectedPlugins.isEmpty && _selectedBuiltIns.isNotEmpty;
  bool get _allPlugins =>
      _selectedBuiltIns.isEmpty && _selectedPlugins.isNotEmpty;

  /// האם כל הפריטים שנבחרו כבר מוסתרים?
  bool get _allSelectedAreHidden {
    if (selectedIds.isEmpty) return false;
    for (final m in _selectedBuiltIns) {
      if (!settingsState.hiddenBuiltInToolIds.contains(m.toolId)) return false;
    }
    for (final p in _selectedPlugins) {
      if (!p.hiddenFromTools) return false;
    }
    return true;
  }

  /// האם כל הפריטים שנבחרו כבר מוצמדים ל-nav rail?
  bool get _allSelectedArePinnedToNav {
    if (selectedIds.isEmpty) return false;
    for (final m in _selectedBuiltIns) {
      if (!settingsState.builtInToolsPinnedToNavRail.contains(m.toolId)) {
        return false;
      }
    }
    for (final p in _selectedPlugins) {
      if (!p.pinnedToNavRail) return false;
    }
    return true;
  }

  bool get _allSelectedPluginsEnabled =>
      _selectedPlugins.every((p) => p.enabled);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final count = selectedIds.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: cs.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '{count} נבחרו'.tr(args: {'count': '$count'}),
                textDirection: AppTranslations.textDirection,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(FluentIcons.dismiss_circle_24_regular),
              label: Text('נקה בחירה'.tr()),
            ),
            _ActionChip(
              icon: _allSelectedAreHidden
                  ? FluentIcons.eye_24_regular
                  : FluentIcons.eye_off_24_regular,
              label: _allSelectedAreHidden ? 'הצג'.tr() : 'הסתר'.tr(),
              onPressed: () => _onToggleHide(context),
            ),
            _ActionChip(
              icon: _allSelectedArePinnedToNav
                  ? FluentIcons.pin_off_24_regular
                  : FluentIcons.pin_24_regular,
              label: _allSelectedArePinnedToNav
                  ? 'הסר מסרגל הניווט'.tr()
                  : 'הצמד לסרגל הניווט'.tr(),
              onPressed: () => _onTogglePinNavRail(context),
            ),
            if (_allPlugins) ...[
              _ActionChip(
                icon: _allSelectedPluginsEnabled
                    ? FluentIcons.pause_circle_24_regular
                    : FluentIcons.play_circle_24_regular,
                label: _allSelectedPluginsEnabled ? 'השבת'.tr() : 'הפעל'.tr(),
                onPressed: () => _onToggleEnabled(context),
              ),
              _PermissionMenu(
                icon: FluentIcons.globe_24_regular,
                label: 'גישה לרשת'.tr(),
                onGrant: () => _setNetworkAccess(context, granted: true),
                onRevoke: () => _setNetworkAccess(context, granted: false),
              ),
              _PermissionMenu(
                icon: FluentIcons.power_24_regular,
                label: 'טעינה אוטומטית בעלייה'.tr(),
                onGrant: () => _setRunOnStartup(context, granted: true),
                onRevoke: () => _setRunOnStartup(context, granted: false),
              ),
              _ActionChip(
                icon: FluentIcons.delete_24_regular,
                label: 'מחק'.tr(),
                danger: true,
                onPressed: () => _onDelete(context),
              ),
            ],
            if (_allBuiltIn && _selectedBuiltIns.isNotEmpty)
              _disabledHint('פעולות נוספות זמינות רק לתוספים'.tr()),
          ],
        ),
      ),
    );
  }

  Widget _disabledHint(String text) {
    return Builder(builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text,
          textDirection: AppTranslations.textDirection,
          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    });
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  void _onToggleHide(BuildContext context) {
    final shouldHide = !_allSelectedAreHidden;
    // כלים מובנים
    final newHidden = Set<String>.from(settingsState.hiddenBuiltInToolIds);
    for (final m in _selectedBuiltIns) {
      if (shouldHide) {
        newHidden.add(m.toolId);
      } else {
        newHidden.remove(m.toolId);
      }
    }
    if (newHidden.length != settingsState.hiddenBuiltInToolIds.length ||
        !newHidden.containsAll(settingsState.hiddenBuiltInToolIds)) {
      context.read<SettingsBloc>().add(UpdateHiddenBuiltInToolIds(newHidden));
    }
    // תוספים
    final bloc = context.read<PluginSystemBloc>();
    for (final p in _selectedPlugins) {
      bloc.add(SetPluginHiddenRequested(
        pluginId: p.pluginId,
        hidden: shouldHide,
      ));
    }
    UiSnack.show(shouldHide ? 'הפריטים הוסתרו'.tr() : 'הפריטים יוצגו'.tr());
  }

  void _onTogglePinNavRail(BuildContext context) {
    final shouldPin = !_allSelectedArePinnedToNav;
    // כלים מובנים
    final newPinned =
        Set<String>.from(settingsState.builtInToolsPinnedToNavRail);
    for (final m in _selectedBuiltIns) {
      if (shouldPin) {
        newPinned.add(m.toolId);
      } else {
        newPinned.remove(m.toolId);
      }
    }
    if (newPinned.length != settingsState.builtInToolsPinnedToNavRail.length ||
        !newPinned.containsAll(settingsState.builtInToolsPinnedToNavRail)) {
      context
          .read<SettingsBloc>()
          .add(UpdateBuiltInToolsPinnedToNavRail(newPinned));
    }
    // תוספים
    final bloc = context.read<PluginSystemBloc>();
    for (final p in _selectedPlugins) {
      if (shouldPin) {
        bloc.add(PinPluginToNavRailRequested(p.pluginId));
      } else {
        bloc.add(UnpinPluginFromNavRailRequested(p.pluginId));
      }
    }
  }

  void _onToggleEnabled(BuildContext context) {
    final shouldEnable = !_allSelectedPluginsEnabled;
    final bloc = context.read<PluginSystemBloc>();
    for (final p in _selectedPlugins) {
      if (shouldEnable) {
        bloc.add(EnablePluginRequested(p.pluginId));
      } else {
        bloc.add(DisablePluginRequested(p.pluginId));
      }
    }
  }

  void _setNetworkAccess(BuildContext context, {required bool granted}) {
    final eligible = _selectedPlugins
        .where((p) => p.manifest.permissions.contains(_networkAccessPermission))
        .toList();
    if (eligible.isEmpty) {
      UiSnack.showError(
          'אף תוסף נבחר לא מצהיר על שימוש ברשת — אין מה לעדכן'.tr());
      return;
    }
    final bloc = context.read<PluginSystemBloc>();
    for (final p in eligible) {
      bloc.add(SetPluginPermissionRequested(
        pluginId: p.pluginId,
        permission: _networkAccessPermission,
        granted: granted,
      ));
    }
    UiSnack.show(granted
        ? 'גישה לרשת הוענקה לתוספים הנבחרים'.tr()
        : 'גישה לרשת בוטלה לתוספים הנבחרים'.tr());
  }

  void _setRunOnStartup(BuildContext context, {required bool granted}) {
    final eligible = _selectedPlugins
        .where((p) =>
            p.manifest.permissions.contains(pluginRunOnStartupPermission))
        .toList();
    if (eligible.isEmpty) {
      UiSnack.showError('אף תוסף נבחר לא תומך בטעינה אוטומטית בעלייה'.tr());
      return;
    }
    final bloc = context.read<PluginSystemBloc>();
    for (final p in eligible) {
      bloc.add(SetPluginPermissionRequested(
        pluginId: p.pluginId,
        permission: pluginRunOnStartupPermission,
        granted: granted,
      ));
    }
    UiSnack.show(granted
        ? 'טעינה אוטומטית בעלייה הופעלה לתוספים הנבחרים'.tr()
        : 'טעינה אוטומטית בעלייה בוטלה לתוספים הנבחרים'.tr());
  }

  Future<void> _onDelete(BuildContext context) async {
    final plugins = _selectedPlugins.toList();
    if (plugins.isEmpty) return;
    final names = plugins.map((p) => p.name).join('\n• ');
    // קוראים ל-bloc *לפני* ה-await כדי לא להחזיק BuildContext חוצה גבולות async
    final bloc = context.read<PluginSystemBloc>();
    final confirmed = await showWarningDialog(
      context: context,
      title: 'מחיקת תוספים'.tr(),
      content: 'האם למחוק {count} תוסף(ים)?\n\n• {names}'.tr(
        args: {'count': '${plugins.length}', 'names': names},
      ),
      subtitle: 'פעולה זו אינה הפיכה. נתוני התוסף יימחקו.'.tr(),
      confirmText: 'מחק'.tr(),
    );
    if (confirmed != true) return;
    for (final p in plugins) {
      if (p.isDevelopment) {
        bloc.add(DetachDevelopmentPluginRequested(p.pluginId));
      } else {
        bloc.add(UninstallPluginRequested(p.pluginId));
      }
    }
    UiSnack.show('התוספים סומנו למחיקה'.tr());
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool danger;

  const _ActionChip({
    required this.icon,
    required this.label,
    this.onPressed,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = danger ? cs.error : null;
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: fg),
      label: Text(label, style: fg != null ? TextStyle(color: fg) : null),
    );
  }
}

/// פעולה דו-כיוונית מפורשת — תפריט נפתח עם "הענק" ו"בטל".
///
/// משמשת לפעולות שאי אפשר לקבוע "מצב נוכחי" ממידע ה-state (כי ההרשאה
/// נשמרת ב-permission grant table הנפרד, לא ב-`InstalledPlugin`).
/// במקום לנחש כיוון או להחזיק מצב a-synchronous, נציע למשתמש שתי
/// בחירות מפורשות.
class _PermissionMenu extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onGrant;
  final VoidCallback onRevoke;

  const _PermissionMenu({
    required this.icon,
    required this.label,
    required this.onGrant,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<bool>(
      tooltip: label,
      onSelected: (grant) => grant ? onGrant() : onRevoke(),
      itemBuilder: (_) => [
        PopupMenuItem<bool>(
          value: true,
          child: ListTile(
            leading: const Icon(FluentIcons.checkmark_24_regular),
            title: Text('הענק'.tr()),
            dense: true,
          ),
        ),
        PopupMenuItem<bool>(
          value: false,
          child: ListTile(
            leading: const Icon(FluentIcons.dismiss_24_regular),
            title: Text('בטל'.tr()),
            dense: true,
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 4),
            Text(label),
            const SizedBox(width: 2),
            const Icon(FluentIcons.chevron_down_24_regular, size: 16),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// שורות הטבלה
// ──────────────────────────────────────────────────────────────────────────────

class _BuiltInToolRow extends StatelessWidget {
  final BuiltInToolMeta meta;
  final bool hidden;
  final bool pinnedToNavRail;
  final bool selected;
  final ValueChanged<bool?> onSelectChanged;

  const _BuiltInToolRow({
    required this.meta,
    required this.hidden,
    required this.pinnedToNavRail,
    required this.selected,
    required this.onSelectChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      hoverColor: Colors.transparent,
      leading: Checkbox(value: selected, onChanged: onSelectChanged),
      title: Text(meta.label, textDirection: AppTranslations.textDirection),
      subtitle: _StatusBadges(
        hidden: hidden,
        pinnedToNavRail: pinnedToNavRail,
      ),
      trailing: meta.icon != null
          ? Icon(meta.icon)
          : (meta.imageIcon != null
              ? ImageIcon(AssetImage(meta.imageIcon!), size: 24)
              : null),
      onTap: () => onSelectChanged(!selected),
    );
  }
}

class _DraggableSettingsPluginRow extends StatelessWidget {
  final InstalledPlugin plugin;
  final bool selected;
  final ValueChanged<bool?> onSelectChanged;
  final ValueChanged<String> onAcceptSource;

  const _DraggableSettingsPluginRow({
    super.key,
    required this.plugin,
    required this.selected,
    required this.onSelectChanged,
    required this.onAcceptSource,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data != plugin.pluginId,
      onAcceptWithDetails: (details) => onAcceptSource(details.data),
      builder: (context, candidateData, _) {
        final isHovering = candidateData.isNotEmpty;
        final cs = Theme.of(context).colorScheme;
        return Container(
          decoration: isHovering
              ? BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.08),
                  border: Border(
                    top: BorderSide(color: cs.primary, width: 2),
                  ),
                )
              : null,
          child: Material(
            color: Colors.transparent,
            child: _PluginRow(
              plugin: plugin,
              selected: selected,
              onSelectChanged: onSelectChanged,
              dragHandle: Draggable<String>(
                data: plugin.pluginId,
                dragAnchorStrategy: pointerDragAnchorStrategy,
                feedback: _SettingsDragFeedback(plugin: plugin),
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Tooltip(
                    message: 'גרור ושחרר לשינוי סדר'.tr(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Icon(
                        FluentIcons.re_order_dots_vertical_24_regular,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PluginRow extends StatelessWidget {
  final InstalledPlugin plugin;
  final bool selected;
  final ValueChanged<bool?> onSelectChanged;
  final Widget? dragHandle;

  const _PluginRow({
    required this.plugin,
    required this.selected,
    required this.onSelectChanged,
    this.dragHandle,
  });

  @override
  Widget build(BuildContext context) {
    final icon = fluentIconFromName(plugin.manifest.toolTabIconName) ??
        FluentIcons.puzzle_piece_24_regular;
    return ListTile(
      hoverColor: Colors.transparent,
      leading: Checkbox(value: selected, onChanged: onSelectChanged),
      title: Text(
        '${plugin.name}  •  v${plugin.version}',
        textDirection: AppTranslations.textDirection,
      ),
      subtitle: _StatusBadges(
        hidden: plugin.hiddenFromTools,
        pinnedToNavRail: plugin.pinnedToNavRail,
        disabled: !plugin.enabled,
        networkDeclared: plugin.manifest.networkEnabled,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          if (dragHandle != null) dragHandle!,
        ],
      ),
      onTap: () => onSelectChanged(!selected),
    );
  }
}

class _SettingsDragFeedback extends StatelessWidget {
  final InstalledPlugin plugin;

  const _SettingsDragFeedback({required this.plugin});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(fluentIconFromName(plugin.manifest.toolTabIconName) ??
                FluentIcons.puzzle_piece_24_regular),
            const SizedBox(width: 8),
            Text(
              plugin.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadges extends StatelessWidget {
  final bool hidden;
  final bool pinnedToNavRail;
  final bool disabled;
  final bool networkDeclared;

  const _StatusBadges({
    this.hidden = false,
    this.pinnedToNavRail = false,
    this.disabled = false,
    this.networkDeclared = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final chips = <Widget>[];
    if (disabled) {
      chips.add(_badge(context, 'מושבת'.tr(), cs.errorContainer,
          cs.onErrorContainer, FluentIcons.pause_circle_24_regular));
    }
    if (hidden) {
      chips.add(_badge(context, 'מוסתר'.tr(), cs.surfaceContainerHighest,
          cs.onSurfaceVariant, FluentIcons.eye_off_24_regular));
    }
    if (pinnedToNavRail) {
      chips.add(_badge(context, 'בסרגל ניווט'.tr(), cs.primaryContainer,
          cs.onPrimaryContainer, FluentIcons.pin_24_regular));
    }
    if (networkDeclared) {
      chips.add(_badge(context, 'משתמש ברשת'.tr(), cs.tertiaryContainer,
          cs.onTertiaryContainer, FluentIcons.globe_24_regular));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(spacing: 6, runSpacing: 4, children: chips),
    );
  }

  Widget _badge(
      BuildContext context, String text, Color bg, Color fg, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(text,
              textDirection: AppTranslations.textDirection,
              style: TextStyle(color: fg, fontSize: 12)),
        ],
      ),
    );
  }
}
