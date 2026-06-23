import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/util/dimensions.dart';
import '../../config/util/styles.dart';
import 'role_cubit.dart';

/// Overlays a global floating button on top of every route that toggles the
/// previewed [UserRole]. Wrap the app's router content with this in
/// `MaterialApp.router`'s `builder`.
///
/// Temporary dev tool — remove once real role-based auth lands.
class RoleSwitcherOverlay extends StatelessWidget {
  const RoleSwitcherOverlay({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          right: Dimensions.paddingSizeLarge,
          bottom: Dimensions.paddingSizeExtraLarge32 + Dimensions.spaceLarge,
          child: SafeArea(
            child: BlocBuilder<RoleCubit, UserRole>(
              builder: (context, role) {
                final isAdmin = role.isAdmin;
                final color =
                    isAdmin ? const Color(0xFF7C4DFF) : const Color(0xFF1FA463);

                return FloatingActionButton.extended(
                  heroTag: 'role-switcher-fab',
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  onPressed: () => context.read<RoleCubit>().toggle(),
                  icon: Icon(role.icon),
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Viewing as',
                        style: AppTextStyles.sfProRoundedMedium.copyWith(
                          color: Colors.white70,
                          fontSize: Dimensions.fontSizeExtraSmall,
                        ),
                      ),
                      Text(
                        role.label,
                        style: AppTextStyles.sfProRoundedBold.copyWith(
                          color: Colors.white,
                          fontSize: Dimensions.fontSizeDefault,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
