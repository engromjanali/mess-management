import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/membership/domain/entities/mess_details_entity.dart';
import 'package:clean_boilerplate/features/membership/presentation/widgets/mess_formatters.dart';

/// Gradient header: mess name and address, the active season (name, start,
/// day count) and the user's own role and join date.
class MessHeroCard extends StatelessWidget {
  const MessHeroCard({required this.mess, super.key});

  final MessDetailsEntity mess;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final day = mess.season.dayOn(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusExtra2Large),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [colors.primaryDarkColor, colors.primaryColor, colors.primaryLightColor]),
        boxShadow: [BoxShadow(color: colors.primaryColor.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Stack(
        children: [
          // Soft decorative mark in the corner.
          PositionedDirectional(end: -24, top: -24, child: Icon(Icons.home_work_rounded, size: 140, color: Colors.white.withValues(alpha: 0.08))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      MessFormatters.initials(mess.name),
                      style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraOverLarge, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeDefault),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mess.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraOverLarge, color: Colors.white),
                        ),
                        if (mess.address.isNotEmpty) ...[
                          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded, size: Dimensions.iconSizeSmall, color: Colors.white.withValues(alpha: 0.85)),
                              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                              Expanded(
                                child: Text(
                                  mess.address,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Colors.white.withValues(alpha: 0.85)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),
              Wrap(
                spacing: Dimensions.paddingSizeSmall,
                runSpacing: Dimensions.paddingSizeSmall,
                children: [
                  _HeroChip(icon: Icons.event_note_rounded, label: context.local.seasonName(mess.season.name)),
                  _HeroChip(icon: Icons.flag_rounded, label: context.local.messSince(MessFormatters.date(context, mess.season.startDate))),
                  if (day > 0) _HeroChip(icon: Icons.timelapse_rounded, label: context.local.seasonDay(day)),
                  _HeroChip(icon: Icons.verified_user_rounded, label: '${context.local.you} · ${MessFormatters.role(context, mess.myRole)}', highlighted: true),
                  _HeroChip(icon: Icons.login_rounded, label: context.local.joinedOn(MessFormatters.date(context, mess.joinedAt))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label, this.highlighted = false});

  final IconData icon;
  final String label;

  /// Solid white chip (the user's own role) instead of a translucent one.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final foreground = highlighted ? colors.primaryDarkColor : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: highlighted ? Colors.white : Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(Dimensions.radiusExtra2Large),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: Dimensions.iconSizeSmall, color: foreground),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
