import 'package:dio/dio.dart';
import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/features/opinion/domain/entities/opinion_entity.dart';

typedef OpinionOverview = ({String messId, bool canManage, bool canCreate, int? nextPage, List<OpinionPeriodEntity> periods});
typedef OpinionMessagePage = ({int? nextPage, List<AnonymousOpinionEntity> opinions});

class OpinionApiService {
  const OpinionApiService(this._apiClient);

  final ApiClient _apiClient;
  static final _privateOptions = Options(extra: {'sensitive': true});

  Future<OpinionOverview> getOverview({int page = 1, CancelToken? cancelToken}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(AppConstants.opinionsEndpoint, queryParameters: {'page': page}, options: _privateOptions, cancelToken: cancelToken);
    final json = response.data!;
    return (messId: '${json['mess_id']}', canManage: json['can_manage'] == true, canCreate: json['can_create'] == true, nextPage: (json['next_page'] as num?)?.toInt(), periods: (json['data'] as List<dynamic>).map((item) => _period(item as Map<String, dynamic>)).toList());
  }

  Future<OpinionMessagePage> getMessages(String periodId, {required int page, CancelToken? cancelToken}) async {
    final response = await _apiClient.get<Map<String, dynamic>>('${AppConstants.opinionsEndpoint}/$periodId/messages', queryParameters: {'page': page}, options: _privateOptions, cancelToken: cancelToken);
    final json = response.data!;
    return (nextPage: (json['next_page'] as num?)?.toInt(), opinions: (json['data'] as List<dynamic>).map((item) => _opinion(item as Map<String, dynamic>)).toList());
  }

  Future<void> createPeriod({required String title, required String details, required DateTime startDate, required DateTime endDate, required OpinionVisibility visibility, required OpinionSubmissionMode submissionMode}) async {
    await _apiClient.post<void>(AppConstants.adminOpinionsEndpoint, data: {'title': title, 'details': details, 'start_date': _date(startDate), 'end_date': _date(endDate), 'visibility': _visibility(visibility), 'submission_mode': _submissionMode(submissionMode)}, options: _privateOptions);
  }

  Future<void> submitOpinion({required String periodId, required String message, required bool anonymous}) async {
    await _apiClient.post<void>('${AppConstants.opinionsEndpoint}/$periodId/messages', data: {'message': message, 'anonymous': anonymous}, options: _privateOptions);
  }

  Future<void> setMessageSending({required String periodId, required bool enabled}) => _update(periodId, {'accepting_messages': enabled});
  Future<void> setNamedOpinions({required String periodId, required bool enabled}) => _update(periodId, {'allow_named_opinions': enabled});
  Future<void> setSubmissionMode({required String periodId, required OpinionSubmissionMode mode}) => _update(periodId, {'submission_mode': _submissionMode(mode)});
  Future<void> updateEndDate({required String periodId, required DateTime endDate}) => _update(periodId, {'end_date': _date(endDate)});
  Future<void> setVisibility({required String periodId, required OpinionVisibility visibility}) => _update(periodId, {'visibility': _visibility(visibility)});

  Future<void> publishOpinions({required String periodId}) async {
    await _apiClient.post<void>('${AppConstants.adminOpinionsEndpoint}/$periodId/publish', options: _privateOptions);
  }

  Future<void> _update(String periodId, Map<String, dynamic> data) async {
    await _apiClient.patch<void>('${AppConstants.adminOpinionsEndpoint}/$periodId', data: data, options: _privateOptions);
  }

  String _date(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  String _visibility(OpinionVisibility visibility) => visibility == OpinionVisibility.realtime ? 'realtime' : 'after_publish';
  String _submissionMode(OpinionSubmissionMode mode) => switch (mode) { OpinionSubmissionMode.anonymousOnly => 'anonymous_only', OpinionSubmissionMode.namedOnly => 'named_only', OpinionSubmissionMode.all => 'all' };

  OpinionPeriodEntity _period(Map<String, dynamic> json) => OpinionPeriodEntity(
    id: '${json['id']}', messId: '${json['mess_id']}', seasonId: '${json['season_id']}', seasonName: json['season_name'] as String,
    title: json['title'] as String, details: json['details'] as String, startDate: DateTime.parse(json['start_date'] as String), endDate: DateTime.parse(json['end_date'] as String),
    acceptingMessages: json['accepting_messages'] == true, allowNamedOpinions: json['allow_named_opinions'] == true, submissionMode: switch (json['submission_mode']) { 'named_only' => OpinionSubmissionMode.namedOnly, 'all' => OpinionSubmissionMode.all, _ => OpinionSubmissionMode.anonymousOnly }, visibility: json['visibility'] == 'realtime' ? OpinionVisibility.realtime : OpinionVisibility.afterPublish,
    canWrite: json['can_write'] == true, opinionCount: (json['opinion_count'] as num).toInt(), hasMoreOpinions: json['has_more_opinions'] == true,
    opinions: (json['opinions'] as List<dynamic>).map((item) => _opinion(item as Map<String, dynamic>)).toList(),
  );

  AnonymousOpinionEntity _opinion(Map<String, dynamic> json) => AnonymousOpinionEntity(id: '${json['id']}', periodId: '${json['period_id']}', message: json['message'] as String, createdAt: DateTime.parse(json['created_at'] as String).toLocal(), authorName: json['author_name'] as String?, authorPhotoUrl: json['author_photo_url'] as String?, isPublished: json['is_published'] == true);
}
