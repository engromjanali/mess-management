import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/app_constants.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/features/app_info/data/datasources/interfaces/app_info_data_source.dart';
import 'package:clean_boilerplate/features/app_info/data/models/content_page_model.dart';
import 'package:clean_boilerplate/features/app_info/data/models/faq_model.dart';
import 'package:clean_boilerplate/features/app_info/domain/entities/content_page_entity.dart';

/// Public app content under `/api/v1/app/`; the language follows the
/// `X-localization` header the [ApiClient] sends.
@LazySingleton(as: AppInfoDataSource)
class AppInfoRemoteDataSourceImpl implements AppInfoDataSource {
  final ApiClient _apiClient;

  AppInfoRemoteDataSourceImpl(this._apiClient);

  @override
  Future<ContentPageModel> getPage(ContentKind kind) async {
    final response = await _apiClient.get<Map<String, dynamic>>('${AppConstants.contentPagesEndpoint}/${kind.slug}');
    return ContentPageModel.fromJson(response.data!);
  }

  @override
  Future<List<FaqModel>> getFaqs() async {
    final response = await _apiClient.get<List<dynamic>>(AppConstants.faqsEndpoint);
    return (response.data ?? []).map((item) => FaqModel.fromJson(item as Map<String, dynamic>)).toList();
  }
}
