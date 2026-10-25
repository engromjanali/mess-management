import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/widgets/app_shimmer.dart';
import 'package:flutter/material.dart';

class HomeDashboardShimmer extends StatelessWidget {
  const HomeDashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    Widget block({double? width, double height = 16, double radius = 12}) => Container(width: width, height: height, decoration: BoxDecoration(color: colors.borderColor.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(radius)));
    return Semantics(
      label: context.local.loading,
      liveRegion: true,
      child: ExcludeSemantics(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AppShimmer(
                  child: LayoutBuilder(builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 900 ? 4 : constraints.maxWidth >= 480 ? 3 : constraints.maxWidth >= 240 ? 2 : 1;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        block(height: 180, radius: 24),
                        const SizedBox(height: 28),
                        Align(alignment: AlignmentDirectional.centerStart, child: FractionallySizedBox(widthFactor: 0.35, child: block(height: 20))),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisExtent: 132, crossAxisSpacing: 12, mainAxisSpacing: 12),
                          itemCount: 6,
                          itemBuilder: (context, index) => Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: colors.surfaceColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: colors.borderColor.withValues(alpha: 0.4))),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [block(width: 32, height: 32), const SizedBox(height: 14), FractionallySizedBox(widthFactor: 0.65, child: block(height: 12)), const SizedBox(height: 10), FractionallySizedBox(widthFactor: 0.4, child: block(height: 20))]),
                          ),
                        ),
                        const SizedBox(height: 28),
                        block(height: 180, radius: 20),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
