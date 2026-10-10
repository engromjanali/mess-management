/// The admin-managed text pages the app shows.
enum ContentKind {
  privacyPolicy('privacy-policy'),
  termsAndConditions('terms-and-conditions');

  const ContentKind(this.slug);

  /// The page's path segment in `/api/v1/app/pages/<slug>`.
  final String slug;
}

/// A privacy policy / terms page in the app's language.
class ContentPageEntity {
  const ContentPageEntity({required this.title, required this.body, required this.updatedAt});

  final String title;

  /// Plain text: blank line = new paragraph, `# ` = heading, `- ` = bullet.
  final String body;
  final DateTime updatedAt;
}
