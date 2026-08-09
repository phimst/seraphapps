import 'dart:math';
import 'package:geolocator/geolocator.dart';

class UserLocation {
  final double lat;
  final double lon;
  final bool isFallback;
  UserLocation({required this.lat, required this.lon, required this.isFallback});
}

class LocationService {
  // Fallback kalau GPS gak kedeteksi/ditolak, sesuai request: sekitar Mojokerto.
  static const double mojokertoLat = -7.4664;
  static const double mojokertoLon = 112.4339;

  static Future<UserLocation> getCurrentOrFallback() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return UserLocation(lat: mojokertoLat, lon: mojokertoLon, isFallback: true);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return UserLocation(lat: mojokertoLat, lon: mojokertoLon, isFallback: true);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return UserLocation(lat: position.latitude, lon: position.longitude, isFallback: false);
    } catch (_) {
      // GPS timeout / error apapun -> jangan crash, fallback ke Mojokerto.
      return UserLocation(lat: mojokertoLat, lon: mojokertoLon, isFallback: true);
    }
  }

  /// Jarak antara 2 titik koordinat pakai formula Haversine, hasil dalam KM.
  static double distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0; // radius bumi dalam km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _deg2rad(double deg) => deg * (pi / 180);
}
