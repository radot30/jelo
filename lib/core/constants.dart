class AppConstants {
  static const List<String> overpassUltraServers = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://lz4.overpass-api.de/api/interpreter',
  ];
  static const String osrmBaseUrl = 'https://router.project-osrm.org/route/v1';
  static const String appUserAgent = 'JELO/1.0 (GamifiedCityApp)';
  
  static const double searchRadiusMeters = 5000.0;
  static const double claimRadiusMeters = 50.0;

  static const double defaultLat = -6.200000;
  static const double defaultLon = 106.816666;
}
