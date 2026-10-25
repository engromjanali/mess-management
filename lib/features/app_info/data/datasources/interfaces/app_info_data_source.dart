import 'package:clean_boilerplate/features/app_info/data/models/content_page_model.dart';
import 'package:clean_boilerplate/features/app_info/data/models/faq_model.dart';
import 'package:clean_boilerplate/features/app_info/domain/entities/content_page_entity.dart';

/// Contract for any source of the admin-managed app pages and FAQs.
abstract class AppInfoDataSource {
  /// The page in the app's language (English when it has no translation).
  Future<ContentPageModel> getPage(ContentKind kind);

  /// Active FAQs in display order.
  Future<List<FaqModel>> getFaqs();
}
