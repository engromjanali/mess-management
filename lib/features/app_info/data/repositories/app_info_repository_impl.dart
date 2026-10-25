import 'package:injectable/injectable.dart';
import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/core/errors/error_handler.dart';
import 'package:clean_boilerplate/features/app_info/data/datasources/interfaces/app_info_data_source.dart';
import 'package:clean_boilerplate/features/app_info/domain/entities/content_page_entity.dart';
import 'package:clean_boilerplate/features/app_info/domain/entities/faq_entity.dart';
import 'package:clean_boilerplate/features/app_info/domain/repositories/app_info_repository.dart';

@LazySingleton(as: AppInfoRepository)
class AppInfoRepositoryImpl implements AppInfoRepository {
  final AppInfoDataSource _dataSource;

  AppInfoRepositoryImpl(this._dataSource);

  @override
  ResultFuture<ContentPageEntity> getPage(ContentKind kind) => guardResult(() async => (await _dataSource.getPage(kind)).toEntity());

  @override
  ResultFuture<List<FaqEntity>> getFaqs() => guardResult(() async => (await _dataSource.getFaqs()).map((faq) => faq.toEntity()).toList());
}
