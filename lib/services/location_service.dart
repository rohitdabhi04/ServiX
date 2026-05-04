import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// GPS se current location lo aur city/area return karo
  Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      // GPS service on hai?
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return {'error': 'gps_off'};

      // Permission check
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return {'error': 'permission_denied'};
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return {'error': 'permission_denied_forever'};
      }

      // GPS se position lo
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      // Coordinates → Address (FREE - device native geocoder)
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) return null;

      final place = placemarks.first;

      final city = place.locality ??
          place.administrativeArea ??
          place.subAdministrativeArea ??
          'Unknown';

      final area = place.subLocality ?? '';

      return {
        'city': city,
        'area': area,
        'fullAddress': _buildAddress(place),
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      print('❌ Location error: $e');
      return null;
    }
  }

  String _buildAddress(Placemark place) {
    final parts = [
      place.subLocality,
      place.locality,
      place.administrativeArea,
    ].where((p) => p != null && p.isNotEmpty).toList();
    return parts.join(', ');
  }

  /// Location Firestore mein save karo
  Future<void> saveLocationToFirestore(Map<String, dynamic> locationData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final updateData = <String, dynamic>{
      'city': locationData['city'],
      'area': locationData['area'] ?? '',
      'locationUpdatedAt': FieldValue.serverTimestamp(),
    };

    if (locationData['latitude'] != null) {
      updateData['latitude'] = locationData['latitude'];
      updateData['longitude'] = locationData['longitude'];
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(updateData, SetOptions(merge: true));
  }

  /// Firestore se saved location lo
  Future<Map<String, dynamic>?> getSavedLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data();
    if (data == null) return null;

    final city = data['city'] as String?;
    if (city == null || city.isEmpty) return null;

    return {
      'city': city,
      'area': data['area'] ?? '',
      'latitude': data['latitude'],
      'longitude': data['longitude'],
    };
  }
}
