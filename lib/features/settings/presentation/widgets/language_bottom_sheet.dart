import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/settings/domain/entities/locale_entity.dart';
import 'package:clean_boilerplate/features/settings/presentation/bloc/localization/localization_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Bottom sheet widget for language selection
class LanguageBottomSheet extends StatelessWidget {
  const LanguageBottomSheet({required this.currentLocale, super.key});

  final Locale currentLocale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.local.selectLanguage, style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
          const SizedBox(height: Dimensions.spaceDefault),
          ...AppLocale.supportedLocales.map((locale) {
            final isSelected = locale.languageCode == currentLocale.languageCode;
            final languageName = AppLocale.getLanguageName(locale);

            return _LanguageListItem(isSelected: isSelected, languageName: languageName, locale: locale);
          }),
          const SizedBox(height: Dimensions.spaceDefault),
        ],
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
        context.read<LocalizationBloc>().add(LocalizationEvent.changeLocale(locale.languageCode));
        Navigator.pop(context);
      },
    );
  }
}
