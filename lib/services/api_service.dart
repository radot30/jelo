import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/place_model.dart';
import '../core/constants.dart';
import '../core/app_exception.dart';

class ApiService {
  Future<List<Place>> fetchNearbyPlaces(double lat, double lon) async {
    final query = _buildOverpassQuery(lat, lon, AppConstants.searchRadiusMeters);
    Object? lastException;

    for (final server in AppConstants.overpassUltraServers) {
      try {
        final response = await http.post(
          Uri.parse(server),
          headers: {
            'User-Agent': AppConstants.appUserAgent,
            'Accept': 'application/json',
          },
          body: {'data': query},
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final places = await compute(_parsePlacesJson, response.body);
          if (places.isNotEmpty) {
            return places;
          }
        }
      } catch (e) {
        lastException = e;
        if (kDebugMode) {
          debugPrint('[ApiService] Failover from $server: $e');
        }
      }
    }

    throw NetworkException(
        'Gagal memuat tempat di sekitar Anda. ${lastException ?? "Server tidak dapat dijangkau."}');
  }

  Future<List<LatLng>> fetchRoute(
      double startLat, double startLon, double endLat, double endLon) async {
    final profiles = ['driving', 'foot', 'bike'];

    for (final profile in profiles) {
      final url =
          '${AppConstants.osrmBaseUrl}/$profile/$startLon,$startLat;$endLon,$endLat?overview=full&geometries=geojson&alternatives=true';
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'User-Agent': AppConstants.appUserAgent,
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final routes = data['routes'] as List?;
          if (routes != null && routes.isNotEmpty) {
            routes.sort((a, b) =>
                (a['distance'] as num).compareTo(b['distance'] as num));
            final bestRoute = routes.first;
            final geometry = bestRoute['geometry'];
            final coordinates = geometry['coordinates'] as List;
            return coordinates
                .map((coord) => LatLng(
                    (coord[1] as num).toDouble(), (coord[0] as num).toDouble()))
                .toList();
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[ApiService] Route fetch failed ($profile): $e');
        }
      }
    }
    return [];
  }

  String _buildOverpassQuery(double lat, double lon, double radius) {
    return '''
      [out:json][timeout:25];
      (
        nwr["amenity"~"^(cafe|fast_food|pub|bar|food_court|biergarten)\$"](around:$radius,$lat,$lon);
        nwr["shop"~"^(convenience|kiosk|mall|department_store|beverages)\$"](around:$radius,$lat,$lon);
        nwr["tourism"~"^(attraction|museum|zoo|viewpoint|gallery|theme_park)\$"](around:$radius,$lat,$lon);
        nwr["leisure"~"^(park|nature_reserve|water_park|swimming_pool|resort|outdoor_seating|picnic_table)\$"](around:$radius,$lat,$lon);
        nwr["natural"~"^(waterfall|peak|water|beach)\$"](around:$radius,$lat,$lon);
        nwr["waterway"="waterfall"](around:$radius,$lat,$lon);
      );
      out center;
    ''';
  }
}

List<Place> _parsePlacesJson(String responseBody) {
  final data = json.decode(responseBody);
  if (data is Map && data.containsKey('elements')) {
    final elements = data['elements'] as List;
    return elements
        .where((e) => e['tags'] != null && e['tags']['name'] != null)
        .map((e) => Place.fromJson(e))
        .toList();
  }
  return [];
}
