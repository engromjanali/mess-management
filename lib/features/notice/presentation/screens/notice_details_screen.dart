import 'package:clean_boilerplate/core/widgets/app_footer.dart';
import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:clean_boilerplate/core/errors/failures.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/widgets/app_loader.dart';
import 'package:clean_boilerplate/core/widgets/app_state_view.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/main_page_body.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/web_profile_drawer.dart';
import 'package:clean_boilerplate/features/notice/domain/entities/notice_entity.dart';
import 'package:clean_boilerplate/features/notice/domain/repositories/notice_repository.dart';
import 'package:clean_boilerplate/features/notice/presentation/widgets/notice_formatters.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NoticeDetailsScreen extends StatefulWidget {
  const NoticeDetailsScreen({this.notice, this.noticeId, super.key});

  final NoticeEntity? notice;
  final String? noticeId;

  @override
  State<NoticeDetailsScreen> createState() => _NoticeDetailsScreenState();
}

class _NoticeDetailsScreenState extends State<NoticeDetailsScreen> {
  NoticeEntity? _notice;
  Object? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _notice = widget.notice;
    if (_notice == null) _load();
  }

  @override
  void didUpdateWidget(covariant NoticeDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.noticeId != widget.noticeId || oldWidget.notice != widget.notice) {
      _notice = widget.notice;
      _error = null;
      _loading = false;
      if (_notice == null) _load();
    }
  }

  Future<void> _load() async {
    final id = widget.noticeId;
    setState(() { _loading = true; _error = null; });
    final result = await getIt<NoticeRepository>().getNotice(id ?? '');
    if (!mounted || id != widget.noticeId) return;
    setState(() {
      _loading = false;
      result.when(
        success: (value) => _notice = value.data,
        failure: (failure) => _error = failure.error,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final web = MainPageBody.showWebAppBar(context);
    final notice = _notice;
    final colors = context.customThemeColors;
    final content = _loading
        ? const Center(child: AppLoader())
        : _error is ServerFailure && (_error as ServerFailure).statusCode == 404
            ? AppEmptyState(title: context.local.noticeUnavailable, icon: Icons.campaign_outlined)
            : _error != null
            ? AppErrorState(error: _error!, onRetry: _load)
            : notice == null
                ? AppEmptyState(title: context.local.noticeUnavailable, icon: Icons.campaign_outlined)
                : LayoutBuilder(
                    builder: (context, viewport) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: viewport.maxHeight),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(web ? Dimensions.paddingSizeExtraLarge32 : Dimensions.paddingSizeLarge),
                          child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
                        child: SelectionArea(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(web ? Dimensions.paddingSizeExtraLarge32 : Dimensions.paddingSizeLarge),
                        decoration: BoxDecoration(
                          color: colors.cardBackgroundColor,
                          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                          border: Border.all(color: colors.primaryColor.withValues(alpha: 0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.campaign_rounded, size: 40, color: colors.primaryColor),
                            const SizedBox(height: Dimensions.spaceDefault),
                            if (notice.pinned) ...[
                              Chip(avatar: const Icon(Icons.push_pin_rounded, size: 16), label: Text(context.local.pinned)),
                              const SizedBox(height: Dimensions.spaceSmall),
                            ],
                            Text(notice.title, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: web ? Dimensions.fontSizeExtraOverLarge : Dimensions.fontSizeOverLarge, color: colors.textPrimaryColor)),
                            const SizedBox(height: Dimensions.spaceDefault),
                            Text(NoticeFormatters.time(notice.createdAt, locale: Localizations.localeOf(context).toLanguageTag()), style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.textHintColor)),
                            const Padding(padding: EdgeInsets.symmetric(vertical: Dimensions.spaceDefault), child: Divider()),
                            Text(notice.description, style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeLarge, height: 1.7, color: colors.textSecondaryColor)),
                          ],
                        ),
                      ),
                        ),
                      ),
                    ),
                        ),
                        if (web) const AppFooter(),
                      ],
                        ),
                      ),
                    ),
                  );
    return Scaffold(
      appBar: web ? null : AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).canPop() ? Navigator.of(context).pop() : context.go(AppRoutes.notices)),
        title: Text(context.local.notices),
      ),
      endDrawer: web ? const WebProfileDrawer() : null,
      body: MainPageBody(title: context.local.notices, child: content),
    );
  }
}
