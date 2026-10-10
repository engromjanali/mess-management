import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/usecase/usecase.dart';
import 'package:clean_boilerplate/core/widgets/home_back_button.dart';
import 'package:clean_boilerplate/features/app_info/domain/entities/faq_entity.dart';
import 'package:clean_boilerplate/features/app_info/domain/usecases/app_info_usecases.dart';
import 'package:clean_boilerplate/features/app_info/presentation/widgets/app_info_error_view.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/main_page_body.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/web_profile_drawer.dart';
import 'package:clean_boilerplate/features/splash/presentation/bloc/splash_bloc.dart';

/// Frequently asked questions from Django admin, in the app's language, with
/// the support email (from the app config) below them.
class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  List<FaqEntity>? _faqs;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    final result = await getIt<GetFaqsUseCase>()(const NoParams());
    if (!mounted) return;
    result.when(
      success: (success) => setState(() => _faqs = success.data),
      failure: (failure) => setState(() => _error = failure.error.toString()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showWebAppBar = MainPageBody.showWebAppBar(context);
    final faqs = _faqs;
    return Scaffold(
      endDrawer: showWebAppBar ? const WebProfileDrawer() : null,
      appBar: showWebAppBar ? null : AppBar(leading: const HomeBackButton(), title: Text(context.local.faq)),
      body: MainPageBody(
        title: context.local.faq,
        child: _error != null && faqs == null
            ? AppInfoErrorView(message: _error!, onRetry: _load)
            : faqs == null
            ? const Center(child: CircularProgressIndicator.adaptive())
            : RefreshIndicator(onRefresh: _load, child: _FaqList(faqs: faqs)),
      ),
    );
  }
}

class _FaqList extends StatelessWidget {
  const _FaqList({required this.faqs});

  final List<FaqEntity> faqs;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final supportEmail = context.watch<SplashBloc>().state.maybeWhen(loaded: (config) => config.supportEmail, orElse: () => '');
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (faqs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraLarge32),
                    child: Text(context.local.noFaqs, textAlign: TextAlign.center, style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.textSecondaryColor)),
                  )
                else
                  for (final faq in faqs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                      child: _FaqTile(faq: faq),
                    ),
                if (supportEmail.isNotEmpty) ...[
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                  SelectableText(context.local.supportEmail(supportEmail), textAlign: TextAlign.center, style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.textSecondaryColor)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.faq});

  final FaqEntity faq;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusLarge), side: BorderSide(color: colors.borderColor));
    return Material(
      color: colors.surfaceColor,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: shape,
        collapsedShape: shape,
        leading: Icon(Icons.help_outline_rounded, color: colors.primaryColor),
        title: Text(faq.question, style: AppTextStyles.sfProRoundedSemiBold.copyWith(color: colors.textPrimaryColor)),
        childrenPadding: const EdgeInsetsDirectional.fromSTEB(Dimensions.paddingSizeLarge, 0, Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge),
        expandedAlignment: AlignmentDirectional.centerStart,
        children: [SelectableText(faq.answer, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor, height: 1.5))],
      ),
    );
  }
}
