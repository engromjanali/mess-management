import 'package:injectable/injectable.dart';
import 'package:mess_pilot/config/util/app_constants.dart';
import 'package:mess_pilot/core/network/api_client.dart';
import 'package:mess_pilot/features/poll/data/datasources/interfaces/poll_data_source.dart';
import 'package:mess_pilot/features/poll/data/models/poll_model.dart';
import 'package:mess_pilot/features/poll/domain/entities/poll_entity.dart';

/// Poll APIs: members read and vote under `/api/v1/user/polls`, the manager
/// creates and manages under `/api/v1/admin/polls`.
@LazySingleton(as: PollDataSource)
class PollRemoteDataSourceImpl implements PollDataSource {
  const PollRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<PollOverviewModel> getPolls({int page = 1, bool includePast = true}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      AppConstants.pollsEndpoint,
      queryParameters: {'page': page, 'include_past': includePast},
    );
    return PollOverviewModel.fromJson(response.data!);
  }

  @override
  Future<PollModel> getPoll(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>('${AppConstants.pollsEndpoint}/${Uri.encodeComponent(id)}');
    return PollModel.fromJson(response.data!);
  }

  @override
  Future<PollModel> createPoll(PollDraft draft) async {
    final response = await _apiClient.post<Map<String, dynamic>>(AppConstants.adminPollsEndpoint, data: _draftJson(draft));
    return PollModel.fromJson(response.data!);
  }

  @override
  Future<PollModel> updatePoll({required String id, required PollDraft draft, bool updateOptions = true}) async {
    final data = _draftJson(draft);
    if (!updateOptions) {
      data.remove('options');
      data.remove('allow_multiple');
      data.remove('max_choices');
    }
    final response = await _apiClient.patch<Map<String, dynamic>>('${AppConstants.adminPollsEndpoint}/${Uri.encodeComponent(id)}', data: data);
    return PollModel.fromJson(response.data!);
  }

  @override
  Future<PollModel> vote({required String id, required List<String> optionIds}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.pollsEndpoint}/${Uri.encodeComponent(id)}/vote',
      data: {'option_ids': optionIds.map(int.parse).toList()},
    );
    return PollModel.fromJson(response.data!);
  }

  @override
  Future<PollModel> withdrawVote(String id) async {
    final response = await _apiClient.delete<Map<String, dynamic>>('${AppConstants.pollsEndpoint}/${Uri.encodeComponent(id)}/vote');
    return PollModel.fromJson(response.data!);
  }

  @override
  Future<PollModel> setClosed({required String id, required bool closed}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '${AppConstants.adminPollsEndpoint}/${Uri.encodeComponent(id)}/close',
      data: {'closed': closed},
    );
    return PollModel.fromJson(response.data!);
  }

  @override
  Future<void> deletePoll(String id) async {
    await _apiClient.delete<Map<String, dynamic>>('${AppConstants.adminPollsEndpoint}/${Uri.encodeComponent(id)}');
  }

  Map<String, dynamic> _draftJson(PollDraft draft) => {
        'title': draft.title,
        'description': draft.description,
        'poll_date': _date(draft.pollDate),
        'options': draft.options,
        'allow_multiple': draft.allowMultiple,
        'max_choices': draft.maxChoices,
        'is_anonymous': draft.isAnonymous,
        'results_visibility': switch (draft.resultsVisibility) {
          PollResultsVisibility.always => 'always',
          PollResultsVisibility.afterVote => 'after_vote',
          PollResultsVisibility.afterClose => 'after_close',
        },
      };

  String _date(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
