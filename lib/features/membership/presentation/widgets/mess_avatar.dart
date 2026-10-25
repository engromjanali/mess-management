import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/features/membership/presentation/widgets/mess_formatters.dart';

/// Round initials avatar tinted with [color].
class MessAvatar extends StatelessWidget {
  const MessAvatar({required this.name, required this.color, this.size = 40, super.key});

  final String name;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        MessFormatters.initials(name),
        style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: size * 0.36, color: color),
      ),
    );
  }
}
