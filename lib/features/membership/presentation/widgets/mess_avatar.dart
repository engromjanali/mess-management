import 'package:flutter/material.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/helpers/image_url_helper.dart';
import 'package:mess_pilot/features/membership/presentation/widgets/mess_formatters.dart';

/// Round mess avatar: its image when set, otherwise initials tinted with [color].
class MessAvatar extends StatelessWidget {
  const MessAvatar({required this.name, required this.color, this.size = 40, this.imageUrl, super.key});

  final String name;
  final Color color;
  final double size;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = resolveImageUrl(imageUrl);
    final hasImage = isNetworkImageUrl(url);
    final cacheSize = (size * MediaQuery.devicePixelRatioOf(context)).ceil();
    final fallback = Center(
      child: Text(
        MessFormatters.initials(name),
        style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: size * 0.36, color: color),
      ),
    );
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: hasImage
          ? Image.network(url, width: size, height: size, fit: BoxFit.cover, cacheWidth: cacheSize, cacheHeight: cacheSize, errorBuilder: (_, _, _) => fallback, loadingBuilder: (context, child, progress) => progress == null ? child : fallback)
          : fallback,
    );
  }
}
