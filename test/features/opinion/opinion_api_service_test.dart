import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/features/opinion/data/opinion_api_service.dart';
import 'package:clean_boilerplate/features/opinion/domain/entities/opinion_entity.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Dio dio;
  late OpinionApiService api;
  final requests = <RequestOptions>[];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    requests.clear();
    dio = Dio();
    api = OpinionApiService(ApiClient(dio: dio, sharedPreferences: await SharedPreferences.getInstance()));
  });

  tearDown(() => dio.close());

  test('Overview parses season write permissions, publication and pagination', () async {
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests.add(options);
      handler.resolve(Response(requestOptions: options, statusCode: 200, data: {
        'mess_id': 7, 'can_manage': false, 'can_create': false, 'next_page': 2,
        'data': [{
          'id': 10, 'mess_id': 7, 'season_id': 4, 'season_name': 'October', 'title': 'Feedback', 'details': 'Share feedback',
          'start_date': '2026-10-01', 'end_date': '2026-10-31', 'accepting_messages': true, 'visibility': 'after_publish',
          'can_write': false, 'opinion_count': 1, 'has_more_opinions': true,
          'opinions': [{'id': 20, 'period_id': 10, 'message': 'Published feedback', 'created_at': '2026-10-12T12:00:00Z', 'is_published': true}],
        }],
      }));
    }));
    final overview = await api.getOverview();
    expect(overview.messId, '7');
    expect(overview.canManage, isFalse);
    expect(overview.nextPage, 2);
    final period = overview.periods.single;
    expect(period.canWrite, isFalse);
    expect(period.seasonId, '4');
    expect(period.opinions.single.isPublished, isTrue);
    expect(period.visibility, OpinionVisibility.afterPublish);
    expect(requests.single.queryParameters, {'page': 1});
    expect(requests.single.extra['sensitive'], isTrue);
  });

  test('Submission and mutations use server endpoints without author identifiers', () async {
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests.add(options);
      handler.resolve(Response(requestOptions: options, statusCode: 200));
    }));
    await api.submitOpinion(periodId: '10', message: 'Anonymous feedback', anonymous: true);
    await api.createPeriod(title: 'Feedback', details: 'Details', startDate: DateTime(2026, 10), endDate: DateTime(2026, 10, 31), visibility: OpinionVisibility.afterPublish, submissionMode: OpinionSubmissionMode.anonymousOnly);
    await api.setMessageSending(periodId: '10', enabled: false);
    await api.setVisibility(periodId: '10', visibility: OpinionVisibility.realtime);
    await api.publishOpinions(periodId: '10');
    expect(requests.first.path, '/api/v1/user/opinions/10/messages');
    expect(requests.first.data, {'message': 'Anonymous feedback', 'anonymous': true});
    expect(requests[1].data, {'title': 'Feedback', 'details': 'Details', 'start_date': '2026-10-01', 'end_date': '2026-10-31', 'visibility': 'after_publish', 'submission_mode': 'anonymous_only'});
    expect(requests[2].method, 'PATCH');
    expect(requests[2].data, {'accepting_messages': false});
    expect(requests[3].data, {'visibility': 'realtime'});
    expect(requests.last.path, '/api/v1/admin/opinions/10/publish');
    expect(requests.every((request) => request.extra['sensitive'] == true), isTrue);
  });

  test('More messages use the backend current membership and server pagination', () async {
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests.add(options);
      handler.resolve(Response(requestOptions: options, statusCode: 200, data: {'data': [], 'next_page': null}));
    }));
    final messages = await api.getMessages('10', page: 2);
    expect(requests.single.queryParameters, {'page': 2});
    expect(messages.nextPage, isNull);
    expect(messages.opinions, isEmpty);
  });
}
