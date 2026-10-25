import 'package:mess_pilot/core/widgets/app_loader.dart';
import 'package:mess_pilot/core/di/injection.dart';
import 'package:mess_pilot/core/network/api_client.dart';
import 'package:mess_pilot/features/membership/data/membership_api_service.dart';
import 'package:mess_pilot/features/membership/presentation/bloc/membership_cubit.dart';
import 'package:mess_pilot/features/membership/presentation/screens/membership_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class JoinMessScreen extends StatelessWidget {
  const JoinMessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MembershipCubit>(
      create: (_) => MembershipCubit(MembershipApiService(getIt<ApiClient>()))..load(),
      // Connected users may join or create another mess too.
      child: const MembershipGate(allowConnected: true, connectedChild: Scaffold(body: Center(child: AppLoader()))),
    );
  }
}
