const googleMapsHosts = {'google.com', 'www.google.com', 'maps.google.com', 'maps.app.goo.gl', 'goo.gl'};

bool isGoogleMapsUri(Uri? uri) => uri != null && uri.scheme == 'https' && uri.host.isNotEmpty && uri.userInfo.isEmpty && googleMapsHosts.contains(uri.host.toLowerCase());

Uri? messMapUri({double? latitude, double? longitude, String mapUrl = '', required String address}) {
  if (latitude != null && longitude != null) return Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': '$latitude,$longitude'});
  final saved = Uri.tryParse(mapUrl.trim());
  if (isGoogleMapsUri(saved)) return saved;
  final query = address.trim();
  return query.isEmpty ? null : Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': query});
}
