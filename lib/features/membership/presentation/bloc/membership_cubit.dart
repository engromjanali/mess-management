import 'package:clean_boilerplate/features/membership/data/membership_api_service.dart';
import 'package:clean_boilerplate/features/membership/domain/entities/membership_status_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class MembershipState {
  const MembershipState();
}

class MembershipLoading extends MembershipState {
  const MembershipLoading();
}

class MembershipLoaded extends MembershipState {
  const MembershipLoaded(this.status);
  final MembershipStatusEntity status;
}

class MembershipError extends MembershipState {
  const MembershipError(this.message);
  final String message;
}

class MembershipCubit extends Cubit<MembershipState> {
  MembershipCubit(this._service) : super(const MembershipLoading());

  final MembershipApiService _service;

  Future<void> load() async {
    emit(const MembershipLoading());
    try {
      emit(MembershipLoaded(await _service.getStatus()));
    } catch (_) {
      emit(const MembershipError('Could not load your mess membership. Please try again.'));
    }
  }

  Future<void> joinInvite(String code) async {
    if (code.trim().isEmpty) return;
    try {
      await _service.joinInvite(code.trim());
      await load();
    } catch (_) {
      emit(const MembershipError('The invite is invalid, expired, or cannot be used by this account.'));
    }
  }

  Future<void> requestJoin(int messId) async {
    try {
      await _service.requestJoin(messId);
      await load();
    } catch (_) {
      emit(const MembershipError('Could not send the join request. It may already be pending.'));
    }
  }

  Future<MessPageEntity> getAvailableMesses({required int page, required int limit, String search = ''}) => _service.getAvailableMesses(page: page, limit: limit, search: search);

  Future<void> createMess({required String name, required String address, required String seasonName}) async {
    if (name.trim().isEmpty || seasonName.trim().isEmpty) return;
    try {
      await _service.createMess(name: name.trim(), address: address.trim(), seasonName: seasonName.trim());
      await load();
    } catch (_) {
      emit(const MembershipError('Could not create the mess. Please check the details and try again.'));
    }
  }
}
