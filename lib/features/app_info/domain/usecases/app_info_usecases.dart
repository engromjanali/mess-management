import 'package:injectable/injectable.dart';
import 'package:mess_pilot/config/util/result.dart';
import 'package:mess_pilot/core/usecase/usecase.dart';
import 'package:mess_pilot/features/app_info/domain/entities/content_page_entity.dart';
import 'package:mess_pilot/features/app_info/domain/entities/faq_entity.dart';
import 'package:mess_pilot/features/app_info/domain/repositories/app_info_repository.dart';

/// Loads the privacy policy or the terms in the app's language.
@lazySingleton
class GetContentPageUseCase implements UseCase<ContentPageEntity, ContentKind> {
  final AppInfoRepository _repository;
  GetContentPageUseCase(this._repository);

  @override
  ResultFuture<ContentPageEntity> call(ContentKind kind) => _repository.getPage(kind);
}

/// Loads the active FAQs in display order.
@lazySingleton
class GetFaqsUseCase implements UseCase<List<FaqEntity>, NoParams> {
  final AppInfoRepository _repository;
  GetFaqsUseCase(this._repository);

  @override
  ResultFuture<List<FaqEntity>> call(NoParams params) => _repository.getFaqs();
}
