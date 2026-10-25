import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/extensions/overly_extensions.dart';
import 'package:mess_pilot/features/splash/domain/entities/support_channel_entity.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportChannelsView extends StatelessWidget {
  const SupportChannelsView({required this.channels, super.key});

  final List<SupportChannelEntity> channels;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final channel in channels)
          Padding(
            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
            child: Material(
              color: colors.surfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: colors.borderColor)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: channel.contactUri == null ? null : () => _open(context, channel),
                child: Padding(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                  child: Row(
                    children: [
                      SizedBox.square(dimension: 44, child: ClipRRect(borderRadius: BorderRadius.circular(8), child: _logo(context, channel))),
                      const SizedBox(width: Dimensions.paddingSizeDefault),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(channel.name.isEmpty ? _label(context, channel.kind) : channel.name, style: AppTextStyles.sfProRoundedSemiBold.copyWith(color: colors.textPrimaryColor)),
                            const SizedBox(height: 4),
                            Text(channel.destination, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor), softWrap: true),
                          ],
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      Icon(Icons.open_in_new_rounded, size: Dimensions.iconSizeSmall, color: colors.textSecondaryColor),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _logo(BuildContext context, SupportChannelEntity channel) {
    final fallback = Icon(_icon(channel.kind), color: context.customThemeColors.primaryColor, size: 28);
    final uri = Uri.tryParse(channel.logoUrl);
    if (uri == null || !{'http', 'https'}.contains(uri.scheme) || uri.host.isEmpty || uri.userInfo.isNotEmpty) return fallback;
    return Image.network(channel.logoUrl, fit: BoxFit.contain, cacheWidth: 132, cacheHeight: 132, errorBuilder: (_, _, _) => fallback);
  }

  Future<void> _open(BuildContext context, SupportChannelEntity channel) async {
    try {
      final opened = await launchUrl(channel.contactUri!, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) context.showErrorSnackBar(context.local.supportOpenFailed);
    } catch (_) {
      if (context.mounted) context.showErrorSnackBar(context.local.supportOpenFailed);
    }
  }

  IconData _icon(String kind) => switch (kind) {
    'email' => Icons.email_outlined,
    'telegram' => Icons.send_rounded,
    'whatsapp' => Icons.chat_outlined,
    'phone' => Icons.phone_outlined,
    'website' => Icons.language_rounded,
    _ => Icons.support_agent_rounded,
  };

  String _label(BuildContext context, String kind) => switch (kind) {
    'email' => context.local.supportChannelEmail,
    'telegram' => 'Telegram',
    'whatsapp' => 'WhatsApp',
    'phone' => context.local.supportChannelPhone,
    'website' => context.local.supportChannelWebsite,
    _ => context.local.support,
  };
}
