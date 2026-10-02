import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String locationName;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });
}

class LocationService {
  /// Request GPS location permission and retrieve current device position
  static Future<LocationData?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await Geolocator.openLocationSettings();
        if (!serviceEnabled) return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String placeName = 'Detected Location';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final locality = p.locality ?? p.subLocality ?? p.subAdministrativeArea;
          final city = p.administrativeArea ?? p.country;
          if (locality != null && locality.isNotEmpty) {
            placeName = '$locality, ${city ?? "India"}';
          } else {
            placeName = city ?? 'Current Location';
          }
        }
      } catch (e) {
        print('Reverse geocoding error: $e');
        placeName = '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}';
      }

      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        locationName: placeName,
      );
    } catch (e) {
      print('Location detection error: $e');
      return null;
    }
  }

  /// Calculate distance in km between two GPS coordinates
  static double calculateDistanceKm(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    final distanceInMeters = Geolocator.distanceBetween(
      startLat,
      startLng,
      endLat,
      endLng,
    );
    return distanceInMeters / 1000.0;
  }
}
