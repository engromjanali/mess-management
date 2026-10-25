import 'package:mess_pilot/config/util/result.dart';
import 'package:mess_pilot/features/app_info/domain/entities/content_page_entity.dart';
import 'package:mess_pilot/features/app_info/domain/entities/faq_entity.dart';

/// Admin-managed app pages and FAQs (abstraction in the domain layer).
abstract class AppInfoRepository {
  ResultFuture<ContentPageEntity> getPage(ContentKind kind);

  ResultFuture<List<FaqEntity>> getFaqs();
}
