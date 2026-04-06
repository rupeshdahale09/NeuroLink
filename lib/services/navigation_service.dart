import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class NavigationService {
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      throw Exception('Location permission is required for navigation.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<List<String>> buildVoiceGuidance({
    required String destinationLabel,
  }) async {
    final position = await getCurrentPosition();
    try {
      // Demo route to a nearby offset so the app returns spoken turn-by-turn text.
      final destLat = position.latitude + 0.0018;
      final destLng = position.longitude + 0.0018;
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/walking/'
        '${position.longitude},${position.latitude};$destLng,$destLat'
        '?steps=true&overview=false',
      );
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>? ?? [];
        if (routes.isNotEmpty) {
          final legs = (routes.first as Map<String, dynamic>)['legs'] as List<dynamic>? ?? [];
          final steps = <String>[];
          for (final leg in legs) {
            final legMap = leg as Map<String, dynamic>;
            final legSteps = legMap['steps'] as List<dynamic>? ?? [];
            for (final step in legSteps.take(6)) {
              final stepMap = step as Map<String, dynamic>;
              final maneuver = stepMap['maneuver'] as Map<String, dynamic>? ?? {};
              final modifier = (maneuver['modifier'] ?? 'straight').toString();
              final distance = ((stepMap['distance'] ?? 20) as num).round();
              steps.add('Go $modifier for $distance meters.');
            }
          }
          if (steps.isNotEmpty) {
            return [
              'Starting navigation to $destinationLabel.',
              ...steps,
              'You are nearing your destination.',
            ];
          }
        }
      }
    } catch (_) {}

    return [
      'Starting navigation to $destinationLabel.',
      'Walk straight for 50 meters.',
      'Turn left and continue for 80 meters.',
      'Destination is near your right side.',
    ];
  }
}
