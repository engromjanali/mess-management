import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/features/notice/data/datasources/interfaces/notice_data_source.dart';
import 'package:clean_boilerplate/features/notice/data/models/notice_model.dart';

/// Notice board APIs: members read `/api/v1/user/notices`, the manager writes
/// under `/api/v1/admin/notices`.
@LazySingleton(as: NoticeDataSource)
class NoticeRemoteDataSourceImpl implements NoticeDataSource {
  final ApiClient _apiClient;

  NoticeRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<NoticeModel>> getNotices() async {
    final response = await _apiClient.get<Map<String, dynamic>>(AppConstants.noticesEndpoint);
    final items = response.data!['data'] as List<dynamic>? ?? [];
    return items.map((item) => NoticeModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<NoticeModel> addNotice({required String title, required String description}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(AppConstants.adminNoticesEndpoint, data: {'title': title, 'description': description});
    return NoticeModel.fromJson(response.data!);
  }

  @override
  Future<NoticeModel> updateNotice({required String id, required String title, required String description}) async {
    final response = await _apiClient.patch<Map<String, dynamic>>('${AppConstants.adminNoticesEndpoint}/$id', data: {'title': title, 'description': description});
    return NoticeModel.fromJson(response.data!);
  }

  @override
  Future<void> setPinned({required String id, required bool pinned}) async {
    await _apiClient.post<Map<String, dynamic>>('${AppConstants.adminNoticesEndpoint}/$id/pin', data: {'pinned': pinned});
  }

  @override
  Future<void> deleteNotice(String id) async {
    await _apiClient.delete<Map<String, dynamic>>('${AppConstants.adminNoticesEndpoint}/$id');
  }
}
