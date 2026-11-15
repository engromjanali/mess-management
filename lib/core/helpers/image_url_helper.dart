import 'package:mess_pilot/config/util/app_constants.dart';

/// Absolute URL for an image path returned by the API, resolving relative
/// media paths (e.g. `/media/mess_images/x.jpg`) against the API base URL.
String resolveImageUrl(String? rawUrl) {
  final raw = rawUrl?.trim() ?? '';
  if (raw.isEmpty) return '';
  return raw.startsWith('/') && !raw.startsWith('//') ? Uri.parse(AppConstants.baseUrl).resolve(raw).toString() : raw;
}

/// Whether [url] points to a fetchable network image.
bool isNetworkImageUrl(String url) {
  final uri = Uri.tryParse(url);
  return uri != null && (uri.scheme == 'https' || uri.scheme == 'http') && uri.host.isNotEmpty;
}
