import 'package:claudy/core/location/bigdatacloud_reverse_geocoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseName prefers city and appends country', () {
    final name = BigDataCloudReverseGeocoder.parseName({
      'city': 'Amsterdam',
      'locality': 'Some borough',
      'countryName': 'Netherlands',
    });
    expect(name, 'Amsterdam, Netherlands');
  });

  test('parseName falls back to locality', () {
    final name = BigDataCloudReverseGeocoder.parseName({
      'city': '',
      'locality': 'Uithuizen',
      'countryName': 'Netherlands',
    });
    expect(name, 'Uithuizen, Netherlands');
  });

  test('parseName omits country when absent', () {
    expect(
      BigDataCloudReverseGeocoder.parseName({'locality': 'Nowhere'}),
      'Nowhere',
    );
  });

  test('parseName returns null without usable fields or payload', () {
    expect(BigDataCloudReverseGeocoder.parseName(null), isNull);
    expect(BigDataCloudReverseGeocoder.parseName({}), isNull);
    expect(
      BigDataCloudReverseGeocoder.parseName({
        'city': '   ',
        'principalSubdivision': 'Noord-Holland',
      }),
      isNull,
    );
  });
}
