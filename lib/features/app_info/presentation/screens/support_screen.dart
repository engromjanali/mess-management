import 'package:mess_pilot/core/widgets/app_page_scroll_view.dart';
import 'package:mess_pilot/core/widgets/app_state_view.dart';
import 'package:mess_pilot/core/widgets/app_loader.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/widgets/home_back_button.dart';
import 'package:mess_pilot/core/widgets/support_channels_view.dart';
import 'package:mess_pilot/features/app_info/presentation/widgets/app_info_error_view.dart';
import 'package:mess_pilot/features/home/presentation/widgets/main_page_body.dart';
import 'package:mess_pilot/features/home/presentation/widgets/web_profile_drawer.dart';
import 'package:mess_pilot/features/splash/presentation/bloc/splash_bloc.dart';
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
            loading: () => const Center(child: AppLoader()),
            error: (message) => AppInfoErrorView(message: message, onRetry: () => context.read<SplashBloc>().add(const SplashEvent.getConfig())),
            loaded: (config) => RefreshIndicator(
              onRefresh: () async {
                final bloc = context.read<SplashBloc>();
                final refreshed = bloc.stream.firstWhere((state) => state.maybeWhen(loading: () => false, orElse: () => true));
                bloc.add(const SplashEvent.getConfig());
                await refreshed;
              },
              child: AppPageScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: config.availableSupportChannels.isEmpty
                          ? AppEmptyState(title: context.local.noSupportChannels, icon: Icons.support_agent_rounded)
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
