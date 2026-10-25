import 'package:mess_pilot/features/membership/domain/helpers/mess_map_uri.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Coordinates create an exact Google Maps destination', () {
    expect(messMapUri(latitude: 23.8103, longitude: 90.4125, address: 'Fallback')?.queryParameters['query'], '23.8103,90.4125');
  });

  test('Saved Google Maps links are used directly', () {
    for (final url in ['https://www.google.com/maps/place/Dhaka', 'https://maps.google.com/?q=Dhaka', 'https://maps.app.goo.gl/example', 'https://goo.gl/maps/example']) {
      expect(messMapUri(mapUrl: url, address: 'Fallback').toString(), url);
    }
  });

  test('Unsafe links fall back to an encoded Google Maps address search', () {
    for (final url in ['http://www.google.com/maps', 'https://example.com/maps', 'https://user:secret@www.google.com/maps', 'javascript:alert(1)']) {
      final uri = messMapUri(mapUrl: url, address: 'Mirpur 10, Dhaka');
      expect(uri?.scheme, 'https');
      expect(uri?.host, 'www.google.com');
      expect(uri?.path, '/maps/search/');
      expect(uri?.queryParameters, {'api': '1', 'query': 'Mirpur 10, Dhaka'});
    }
  });

  test('A missing link and address has no map destination', () {
    expect(messMapUri(mapUrl: '', address: '  '), isNull);
  });
}
