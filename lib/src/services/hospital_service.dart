import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_models.dart';

class HospitalService {
  static const _endpoint = 'https://overpass-api.de/api/interpreter';

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
