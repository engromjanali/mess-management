import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/widgets/home_back_button.dart';
import 'package:clean_boilerplate/features/app_info/domain/entities/content_page_entity.dart';
import 'package:clean_boilerplate/features/app_info/domain/usecases/app_info_usecases.dart';
import 'package:clean_boilerplate/features/app_info/presentation/widgets/app_info_error_view.dart';
import 'package:clean_boilerplate/features/app_info/presentation/widgets/content_text.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/main_page_body.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/web_profile_drawer.dart';

/// Privacy policy or terms and conditions, as written in Django admin, in
/// the app's language (English when it has no translation).
class ContentPageScreen extends StatefulWidget {
  const ContentPageScreen({required this.kind, super.key});

  final ContentKind kind;

  @override
  State<ContentPageScreen> createState() => _ContentPageScreenState();
}

class _ContentPageScreenState extends State<ContentPageScreen> {
  ContentPageEntity? _page;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    final result = await getIt<GetContentPageUseCase>()(widget.kind);
    if (!mounted) return;
    result.when(
      success: (success) => setState(() => _page = success.data),
      failure: (failure) => setState(() => _error = failure.error.toString()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.kind) {
      ContentKind.privacyPolicy => context.local.privacyPolicy,
      ContentKind.termsAndConditions => context.local.termsAndConditions,
    };
    final showWebAppBar = MainPageBody.showWebAppBar(context);
    final page = _page;
    return Scaffold(
      endDrawer: showWebAppBar ? const WebProfileDrawer() : null,
      appBar: showWebAppBar ? null : AppBar(leading: const HomeBackButton(), title: Text(title)),
      body: MainPageBody(
        title: title,
        child: _error != null && page == null
            ? AppInfoErrorView(message: _error!, onRetry: _load)
            : page == null
            ? const Center(child: CircularProgressIndicator.adaptive())
            : RefreshIndicator(onRefresh: _load, child: _PageBody(page: page)),
      ),
    );
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody({required this.page});

  final ContentPageEntity page;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final updated = DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(page.updatedAt);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge24),
              decoration: BoxDecoration(
                color: colors.cardBackgroundColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                border: Border.all(color: colors.borderColor.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(page.title, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: colors.textPrimaryColor)),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Text(context.local.lastUpdatedOn(updated), style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textSecondaryColor)),
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  ContentText(body: page.body),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
