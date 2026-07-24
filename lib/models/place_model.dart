class Place {
  final String id;
  final String name;
  final String type; // e.g., tourism, historic, cafe
  final double lat;
  final double lon;
  final DateTime? claimDate; // null if not claimed

  final String? openingHours;
  final String? address;
  final String? website;
  final String? phone;

  Place({
    required this.id,
    required this.name,
    required this.type,
    required this.lat,
    required this.lon,
    this.claimDate,
    this.openingHours,
    this.address,
    this.website,
    this.phone,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    final tags = (json['tags'] as Map<String, dynamic>?) ?? {};
    
    final typeKeys = ['tourism', 'historic', 'amenity', 'leisure', 'natural', 'shop'];
    String type = 'unknown';
    for (final key in typeKeys) {
      if (tags.containsKey(key)) {
        type = tags[key].toString();
        break;
      }
    }

    final (parsedLat, parsedLon) = _parseLatLon(json);

    return Place(
      id: json['id']?.toString() ?? '',
      name: tags['name']?.toString() ?? 'Unknown Place',
      type: type,
      lat: parsedLat,
      lon: parsedLon,
      openingHours: tags['opening_hours']?.toString(),
      address: _parseAddress(tags),
      website: tags['website']?.toString(),
      phone: tags['phone']?.toString(),
    );
  }

  static (double, double) _parseLatLon(Map<String, dynamic> json) {
    if (json['lat'] != null && json['lon'] != null) {
      return ((json['lat'] as num).toDouble(), (json['lon'] as num).toDouble());
    } else if (json['center'] != null) {
      final center = json['center'] as Map<String, dynamic>;
      return (
        (center['lat'] as num?)?.toDouble() ?? 0.0,
        (center['lon'] as num?)?.toDouble() ?? 0.0
      );
    }
    return (0.0, 0.0);
  }

  static String? _parseAddress(Map<String, dynamic> tags) {
    if (!tags.containsKey('addr:street')) return null;
    String street = tags['addr:street'].toString();
    if (tags.containsKey('addr:housenumber')) {
      street = '${tags["addr:housenumber"]} $street';
    }
    if (tags.containsKey('addr:city')) {
      street = '$street, ${tags["addr:city"]}';
    }
    return street;
  }

  factory Place.fromMap(Map<String, dynamic> map) {
    return Place(
      id: map['place_id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Unknown',
      type: map['type']?.toString() ?? 'unknown',
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (map['lon'] as num?)?.toDouble() ?? 0.0,
      claimDate: map['claim_date'] != null
          ? DateTime.tryParse(map['claim_date'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'place_id': id,
      'name': name,
      'type': type,
      'lat': lat,
      'lon': lon,
      'claim_date': claimDate?.toIso8601String(),
    };
  }
}
