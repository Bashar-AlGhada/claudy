class GeoCoordinate {
  const GeoCoordinate({required this.lat, required this.lon});

  final double lat;
  final double lon;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoCoordinate && other.lat == lat && other.lon == lon;

  @override
  int get hashCode => Object.hash(lat, lon);

  @override
  String toString() => 'GeoCoordinate($lat, $lon)';
}
