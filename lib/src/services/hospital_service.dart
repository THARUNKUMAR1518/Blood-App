import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_models.dart';

class PlaceSearchResult {
  const PlaceSearchResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });

  final double latitude;
  final double longitude;
  final String displayName;
}

class HospitalService {
  static const _endpoint = 'https://overpass-api.de/api/interpreter';
  static const _geocodingEndpoint = 'nominatim.openstreetmap.org';

  Future<PlaceSearchResult> searchPlace(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      throw Exception('Please enter a place to search.');
    }

    final uri = Uri.https(_geocodingEndpoint, '/search', {
      'q': trimmed,
      'format': 'jsonv2',
      'limit': '1',
    });

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': 'blood-connect/1.0 (hospital-search)',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Unable to search place right now.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List || decoded.isEmpty) {
      throw Exception('No place found. Try a different search.');
    }

    final first = decoded.first;
    if (first is! Map<String, dynamic>) {
      throw Exception('Unable to read place search result.');
    }

    final latValue = first['lat'];
    final lonValue = first['lon'];
    if (latValue == null || lonValue == null) {
      throw Exception('Selected place has no coordinates.');
    }

    final latitude = double.tryParse(latValue.toString());
    final longitude = double.tryParse(lonValue.toString());
    if (latitude == null || longitude == null) {
      throw Exception('Invalid coordinates returned for searched place.');
    }

    return PlaceSearchResult(
      latitude: latitude,
      longitude: longitude,
      displayName: (first['display_name'] ?? trimmed).toString(),
    );
  }

  Future<List<NearbyHospital>> fetchNearbyHospitals({
    required double latitude,
    required double longitude,
    int radiusMeters = 6000,
  }) async {
    final query = '''
[out:json][timeout:20];
(
  node["amenity"="hospital"](around:$radiusMeters,$latitude,$longitude);
  way["amenity"="hospital"](around:$radiusMeters,$latitude,$longitude);
  relation["amenity"="hospital"](around:$radiusMeters,$latitude,$longitude);
);
out center 25;
''';

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'data': query},
    );

    if (response.statusCode != 200) {
      throw Exception('Unable to fetch hospital data.');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = (decoded['elements'] as List?) ?? [];

    final hospitals = <NearbyHospital>[];
    for (final item in elements) {
      final map = item as Map<String, dynamic>;
      final tags = (map['tags'] as Map?)?.cast<String, dynamic>() ?? {};
      final name = (tags['name'] ?? 'Hospital').toString();

      final latValue = map['lat'] ?? (map['center'] as Map?)?['lat'];
      final lonValue = map['lon'] ?? (map['center'] as Map?)?['lon'];
      if (latValue == null || lonValue == null) continue;

      final lat = (latValue as num).toDouble();
      final lon = (lonValue as num).toDouble();
      final addressParts = [
        tags['addr:street'],
        tags['addr:city'],
      ].where((part) => part != null && part.toString().isNotEmpty).join(', ');

      hospitals.add(
        NearbyHospital(
          name: name,
          latitude: lat,
          longitude: lon,
          address: addressParts,
        ),
      );
    }

    return hospitals;
  }
}
