import 'package:mess_pilot/config/util/result.dart';
import 'package:mess_pilot/features/poll/domain/entities/poll_entity.dart';

/// Poll repository contract (domain layer).
abstract class PollRepository {
  ResultFuture<PollOverviewEntity> getPolls({int page = 1, bool includePast = true});

  ResultFuture<PollEntity> getPoll(String id);

  ResultFuture<PollEntity> createPoll(PollDraft draft);

  ResultFuture<PollEntity> updatePoll({required String id, required PollDraft draft, bool updateOptions = true});

  ResultFuture<PollEntity> vote({required String id, required List<String> optionIds});

  ResultFuture<PollEntity> withdrawVote(String id);

  ResultFuture<PollEntity> setClosed({required String id, required bool closed});

  ResultVoid deletePoll(String id);
}
