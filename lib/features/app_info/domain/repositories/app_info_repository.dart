import 'package:clean_boilerplate/config/util/result.dart';
import 'package:clean_boilerplate/features/app_info/domain/entities/content_page_entity.dart';
import 'package:clean_boilerplate/features/app_info/domain/entities/faq_entity.dart';

/// Admin-managed app pages and FAQs (abstraction in the domain layer).
abstract class AppInfoRepository {
  ResultFuture<ContentPageEntity> getPage(ContentKind kind);

  ResultFuture<List<FaqEntity>> getFaqs();
}
