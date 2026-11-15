import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/extensions/overly_extensions.dart';
import 'package:mess_pilot/core/helpers/image_url_helper.dart';

/// A picked mess image, uploaded only when the form is saved.
class PickedMessImage {
  const PickedMessImage({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;
}

/// Picks a downscaled gallery image for a mess.
Future<PickedMessImage?> pickMessImage(BuildContext context) async {
  try {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, maxHeight: 1200, imageQuality: 85);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return PickedMessImage(bytes: bytes, name: file.name);
  } catch (_) {
    if (context.mounted) context.showErrorSnackBar(context.local.photoAccessError);
    return null;
  }
}

/// Optional mess image field: shows the picked or saved image, else an icon,
/// with a camera badge to change it and a close badge to remove it.
class MessImagePicker extends StatelessWidget {
  const MessImagePicker({required this.name, this.imageUrl, this.pickedBytes, this.busy = false, this.onPick, this.onRemove, super.key});

  final String name;
  final String? imageUrl;
  final Uint8List? pickedBytes;
  final bool busy;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final resolved = resolveImageUrl(imageUrl);
    final image = pickedBytes != null
        ? MemoryImage(pickedBytes!) as ImageProvider
        : isNetworkImageUrl(resolved)
        ? NetworkImage(resolved)
        : null;
    return Semantics(
      button: true,
      label: context.local.changeMessImage,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              InkWell(
                onTap: busy ? null : onPick,
                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                child: Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                    color: colors.primaryColor.withValues(alpha: 0.12),
                    border: Border.all(color: colors.borderColor),
                    image: image == null ? null : DecorationImage(image: image, fit: BoxFit.cover),
                  ),
                  child: image == null ? Icon(Icons.home_work_rounded, size: 40, color: colors.primaryColor) : null,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: colors.primaryColor,
                  child: busy
                      ? const SizedBox(height: Dimensions.iconSizeSmall, width: Dimensions.iconSizeSmall, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.camera_alt_rounded, size: Dimensions.iconSizeSmall, color: Colors.white),
                ),
              ),
              if (onRemove != null && image != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: InkWell(
                    onTap: busy ? null : onRemove,
                    customBorder: const CircleBorder(),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: colors.cardBackgroundColor,
                      child: Icon(Icons.close_rounded, size: Dimensions.iconSizeSmall, color: colors.errorColor),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Flexible(child: Text(context.local.messImageOptional, style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textSecondaryColor))),
        ],
      ),
    );
  }
}
