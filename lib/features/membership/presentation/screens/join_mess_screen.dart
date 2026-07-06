import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/features/membership/data/membership_api_service.dart';
import 'package:clean_boilerplate/features/membership/presentation/bloc/membership_cubit.dart';
import 'package:clean_boilerplate/features/membership/presentation/screens/membership_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class JoinMessScreen extends StatelessWidget {
  const JoinMessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MembershipCubit>(
      create: (_) => MembershipCubit(MembershipApiService(getIt<ApiClient>()))..load(),
      child: const MembershipGate(connectedChild: Scaffold(body: Center(child: CircularProgressIndicator.adaptive()))),
    );
  }
}
