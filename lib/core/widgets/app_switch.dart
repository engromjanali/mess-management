import 'package:flutter/material.dart';
import 'package:mess_pilot/config/util/dimensions.dart';

class AppSwitch extends StatelessWidget {
  const AppSwitch({required this.value, required this.onChanged, this.title, this.subtitle, this.secondary, super.key});

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? title;
  final Widget? subtitle;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final control = SizedBox(
      width: 42,
      height: 26,
      child: FittedBox(child: Switch.adaptive(value: value, onChanged: onChanged)),
    );
    if (title == null) return control;
    return Row(
      children: [
        if (secondary case final Widget icon?) ...[icon, const SizedBox(width: Dimensions.paddingSizeSmall)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [title!, ?subtitle],
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        control,
      ],
    );
  }
}
