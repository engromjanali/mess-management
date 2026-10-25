import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/features/settings/domain/entities/locale_entity.dart';
import 'package:flutter/material.dart';

/// Centered overlay for language selection
class LanguageSelectionOverlay extends StatelessWidget {
  const LanguageSelectionOverlay({required this.currentLocale, super.key});

  final Locale currentLocale;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.local.selectLanguage, textAlign: TextAlign.center, style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
                const SizedBox(height: Dimensions.spaceDefault),
                ...AppLocale.supportedLocales.map((locale) {
                  final isSelected = locale.languageCode == currentLocale.languageCode;
                  final languageName = AppLocale.getLanguageName(locale);
      
                  return _LanguageListItem(isSelected: isSelected, languageName: languageName, locale: locale);
                }),
                const SizedBox(height: Dimensions.spaceDefault),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual language list item widget
class _LanguageListItem extends StatelessWidget {
  final bool isSelected;
  final String languageName;
  final Locale locale;

  const _LanguageListItem({required this.isSelected, required this.languageName, required this.locale});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? Theme.of(context).primaryColor : null),
      title: Text(
        languageName,
        style: AppTextStyles.sfProRoundedMedium.copyWith(
          fontSize: Dimensions.fontSizeDefault,
          fontWeight: isSelected ? AppTextStyles.semiBold : AppTextStyles.regular,
          color: isSelected ? Theme.of(context).primaryColor : null,
        ),
      ),
      onTap: () {
        Navigator.pop(context, locale);
      },
    );
  }
}
