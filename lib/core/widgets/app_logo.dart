import 'package:mess_pilot/core/assets/assets.gen.dart';
import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({required this.size, this.shape = BoxShape.rectangle, this.borderRadius, super.key});

  final double size;
  final BoxShape shape;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final cacheSize = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return ClipRRect(
      borderRadius: shape == BoxShape.circle ? BorderRadius.circular(size / 2) : borderRadius ?? BorderRadius.zero,
      child: Assets.images.logo.image(width: size, height: size, fit: BoxFit.cover, cacheWidth: cacheSize, cacheHeight: cacheSize),
    );
  }
}
