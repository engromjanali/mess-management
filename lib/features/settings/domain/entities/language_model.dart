/// Language model for multi-language support
///
/// This model defines the structure for supported languages in the application.
/// Clients can easily add new languages by updating the list in AppConstants.
class LanguageModel {
  /// Language code (ISO 639-1), e.g., 'en', 'bn', 'ar'
  final String code;

  /// English name of the language, e.g., 'English', 'Bangla', 'Arabic'
  final String name;

  /// Native name of the language, e.g., 'English', 'বাংলা', 'العربية'
  final String nativeName;

  const LanguageModel({required this.code, required this.name, required this.nativeName});
}
