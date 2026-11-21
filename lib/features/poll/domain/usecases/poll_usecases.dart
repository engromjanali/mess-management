import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:mess_pilot/config/util/result.dart';
import 'package:mess_pilot/core/usecase/usecase.dart';
import 'package:mess_pilot/features/poll/domain/entities/poll_entity.dart';
import 'package:mess_pilot/features/poll/domain/repositories/poll_repository.dart';

/// Params for loading a page of polls.
class GetPollsParams extends Equatable {
  const GetPollsParams({this.page = 1, this.includePast = true});

  final int page;
  final bool includePast;

  @override
  List<Object?> get props => [page, includePast];
}

@lazySingleton
class GetPollsUseCase implements UseCase<PollOverviewEntity, GetPollsParams> {
  const GetPollsUseCase(this._repository);

  final PollRepository _repository;

  @override
  ResultFuture<PollOverviewEntity> call(GetPollsParams params) =>
      _repository.getPolls(page: params.page, includePast: params.includePast);
}

@lazySingleton
class GetPollUseCase implements UseCase<PollEntity, String> {
  const GetPollUseCase(this._repository);

  final PollRepository _repository;

  @override
  ResultFuture<PollEntity> call(String id) => _repository.getPoll(id);
}

@lazySingleton
class CreatePollUseCase implements UseCase<PollEntity, PollDraft> {
  const CreatePollUseCase(this._repository);

  final PollRepository _repository;

  @override
  ResultFuture<PollEntity> call(PollDraft draft) => _repository.createPoll(draft);
}

class UpdatePollParams extends Equatable {
  const UpdatePollParams({required this.id, required this.draft, this.updateOptions = true});

  final String id;
  final PollDraft draft;
  final bool updateOptions;

  @override
  List<Object?> get props => [id, draft, updateOptions];
}

@lazySingleton
class UpdatePollUseCase implements UseCase<PollEntity, UpdatePollParams> {
  const UpdatePollUseCase(this._repository);

  final PollRepository _repository;

  @override
  ResultFuture<PollEntity> call(UpdatePollParams params) =>
      _repository.updatePoll(id: params.id, draft: params.draft, updateOptions: params.updateOptions);
}

class VotePollParams extends Equatable {
  const VotePollParams({required this.id, required this.optionIds});

  final String id;
  final List<String> optionIds;

  @override
  List<Object?> get props => [id, optionIds];
}

@lazySingleton
class VotePollUseCase implements UseCase<PollEntity, VotePollParams> {
  const VotePollUseCase(this._repository);

  final PollRepository _repository;

  @override
  ResultFuture<PollEntity> call(VotePollParams params) => _repository.vote(id: params.id, optionIds: params.optionIds);
}

@lazySingleton
class WithdrawPollVoteUseCase implements UseCase<PollEntity, String> {
  const WithdrawPollVoteUseCase(this._repository);

  final PollRepository _repository;

  @override
  ResultFuture<PollEntity> call(String id) => _repository.withdrawVote(id);
}

class SetPollClosedParams extends Equatable {
  const SetPollClosedParams({required this.id, required this.closed});

  final String id;
  final bool closed;

  @override
  List<Object?> get props => [id, closed];
}

@lazySingleton
class SetPollClosedUseCase implements UseCase<PollEntity, SetPollClosedParams> {
  const SetPollClosedUseCase(this._repository);

  final PollRepository _repository;

  @override
  ResultFuture<PollEntity> call(SetPollClosedParams params) => _repository.setClosed(id: params.id, closed: params.closed);
}

@lazySingleton
class DeletePollUseCase implements UseCase<void, String> {
  const DeletePollUseCase(this._repository);

  final PollRepository _repository;

  @override
  ResultVoid call(String id) => _repository.deletePoll(id);
}
