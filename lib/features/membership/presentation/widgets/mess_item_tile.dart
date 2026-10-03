import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/membership/presentation/widgets/mess_avatar.dart';

/// A mess row (invitation received, join request sent): avatar, name,
/// [subtitle] and [actions]. [busy] replaces the actions with a spinner.
class MessItemTile extends StatelessWidget {
  const MessItemTile({required this.messName, required this.subtitle, required this.actions, this.busy = false, super.key});

  final String messName;
  final String subtitle;
  final List<Widget> actions;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: Row(
        children: [
          MessAvatar(name: messName, color: colors.primaryColor, size: 44),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(messName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textPrimaryColor)),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textHintColor)),
              ],
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          if (busy)
            const Padding(
              padding: EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            Wrap(spacing: Dimensions.paddingSizeExtraSmall, children: actions),
        ],
      ),
    );
  }
}
