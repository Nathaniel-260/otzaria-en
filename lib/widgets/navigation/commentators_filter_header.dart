import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:otzaria/l10n/app_translations.dart';
import 'package:otzaria/l10n/tr_extension.dart';

class CommentatorsFilterHeader extends StatelessWidget {
  final VoidCallback onBack;
  final String title;

  const CommentatorsFilterHeader({
    super.key,
    required this.onBack,
    this.title = 'בחירת מפרשים', // i18n-ignore: ברירת מחדל const; מתורגם בהצגה
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 48, end: 48),
              child: Text(
                title.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                textDirection: AppTranslations.textDirection,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: IconButton(
                icon: const Icon(FluentIcons.arrow_left_24_regular),
                tooltip: 'חזרה למפרשים'.tr(),
                onPressed: onBack,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
