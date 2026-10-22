import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

class AppUserAvatar extends StatelessWidget {
  const AppUserAvatar({required this.name, this.photoUrl, this.radius = 18, super.key});

  final String name;
  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    final initials = parts.take(2).map((part) => part.characters.first.toUpperCase()).join();
    final fallback = Center(child: initials.isEmpty || RegExp(r'^\d+$').hasMatch(initials) ? Icon(Icons.person_rounded, size: radius, color: colors.primaryColor) : Text(initials, maxLines: 1, style: TextStyle(fontSize: radius * 0.7, fontWeight: FontWeight.w700, color: colors.primaryColor)));
    final rawUrl = photoUrl?.trim() ?? '';
    final url = rawUrl.startsWith('/') && !rawUrl.startsWith('//') ? Uri.parse(AppConstants.baseUrl).resolve(rawUrl).toString() : rawUrl;
    final uri = Uri.tryParse(url);
    final hasPhoto = uri != null && (uri.scheme == 'https' || uri.scheme == 'http') && uri.host.isNotEmpty;
    final cacheSize = (radius * 2 * MediaQuery.devicePixelRatioOf(context)).ceil();
    return SizedBox.square(
      dimension: radius * 2,
      child: ClipOval(
        child: ColoredBox(
          color: colors.primaryColor.withValues(alpha: 0.12),
          child: hasPhoto ? Image.network(url, width: radius * 2, height: radius * 2, fit: BoxFit.cover, cacheWidth: cacheSize, cacheHeight: cacheSize, errorBuilder: (_, _, _) => fallback, loadingBuilder: (context, child, progress) => progress == null ? child : fallback) : fallback,
        ),
      ),
    );
  }
}
