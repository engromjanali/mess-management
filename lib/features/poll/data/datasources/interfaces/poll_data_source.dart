import 'package:mess_pilot/features/poll/data/models/poll_model.dart';
import 'package:mess_pilot/features/poll/domain/entities/poll_entity.dart';

/// Contract for any source that can provide and mutate polls.
abstract class PollDataSource {
  Future<PollOverviewModel> getPolls({int page = 1, bool includePast = true});

  Future<PollModel> getPoll(String id);

  Future<PollModel> createPoll(PollDraft draft);

  Future<PollModel> updatePoll({required String id, required PollDraft draft, bool updateOptions = true});

  Future<PollModel> vote({required String id, required List<String> optionIds});

  Future<PollModel> withdrawVote(String id);

  Future<PollModel> setClosed({required String id, required bool closed});

  Future<void> deletePoll(String id);
}
