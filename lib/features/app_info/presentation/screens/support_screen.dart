import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/widgets/home_back_button.dart';
import 'package:clean_boilerplate/core/widgets/support_channels_view.dart';
import 'package:clean_boilerplate/features/app_info/presentation/widgets/app_info_error_view.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/main_page_body.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/web_profile_drawer.dart';
import 'package:clean_boilerplate/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final showWebAppBar = MainPageBody.showWebAppBar(context);
    return Scaffold(
      endDrawer: showWebAppBar ? const WebProfileDrawer() : null,
      appBar: showWebAppBar ? null : AppBar(leading: const HomeBackButton(), title: Text(context.local.support)),
      body: MainPageBody(
        title: context.local.support,
        child: BlocBuilder<SplashBloc, SplashState>(
          builder: (context, state) => state.when(
            loading: () => const Center(child: CircularProgressIndicator.adaptive()),
            error: (message) => AppInfoErrorView(message: message, onRetry: () => context.read<SplashBloc>().add(const SplashEvent.getConfig())),
            loaded: (config) => RefreshIndicator(
              onRefresh: () async {
                final bloc = context.read<SplashBloc>();
                final refreshed = bloc.stream.firstWhere((state) => state.maybeWhen(loading: () => false, orElse: () => true));
                bloc.add(const SplashEvent.getConfig());
                await refreshed;
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: config.availableSupportChannels.isEmpty
                          ? Padding(padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraLarge32), child: Text(context.local.noSupportChannels, textAlign: TextAlign.center))
                          : SupportChannelsView(channels: config.availableSupportChannels),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
