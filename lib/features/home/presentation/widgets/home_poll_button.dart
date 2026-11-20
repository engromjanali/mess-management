import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mess_pilot/config/route/app_router.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';

class HomePollButton extends StatelessWidget {
  const HomePollButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(AppRoutes.polls),
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        splashColor: Colors.white.withValues(alpha: 0.20),
        highlightColor: Colors.white.withValues(alpha: 0.10),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeSmall,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.how_to_vote_rounded,
                  size: 15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Text(
                context.local.pollPolls,
                style: AppTextStyles.sfProRoundedBold.copyWith(
                  color: Colors.white,
                  fontSize: Dimensions.fontSizeSmall,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 10,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
