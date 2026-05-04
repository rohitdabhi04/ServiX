import 'package:flutter/material.dart';
import '../services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  final _locationService = LocationService();

  String _city = '';
  String _area = '';
  bool _isLoading = false;
  bool _hasLocation = false;

  String get city => _city;
  String get area => _area;
  bool get isLoading => _isLoading;
  bool get hasLocation => _hasLocation;

  String get displayLocation {
    if (!_hasLocation) return 'Set Location';
    if (_area.isNotEmpty && _area != _city) return '$_area, $_city';
    return _city;
  }

  /// App start pe saved location load karo
  Future<void> loadSavedLocation() async {
    final saved = await _locationService.getSavedLocation();
    if (saved != null) {
      _city = saved['city'] ?? '';
      _area = saved['area'] ?? '';
      _hasLocation = _city.isNotEmpty;
      notifyListeners();
    }
  }

  /// GPS se location detect karo
  Future<String> detectLocation() async {
    _isLoading = true;
    notifyListeners();

    try {
      final locationData = await _locationService.getCurrentLocation();

      if (locationData == null) {
        _isLoading = false;
        notifyListeners();
        return 'error';
      }

      // Error handling
      if (locationData.containsKey('error')) {
        _isLoading = false;
        notifyListeners();
        return locationData['error'] as String;
      }

      _city = locationData['city'] ?? '';
      _area = locationData['area'] ?? '';
      _hasLocation = true;

      await _locationService.saveLocationToFirestore(locationData);

      _isLoading = false;
      notifyListeners();
      return 'success';
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'error';
    }
  }

  /// Manual location set karo
  Future<void> setManualLocation(String city, {String area = ''}) async {
    _city = city;
    _area = area;
    _hasLocation = true;
    notifyListeners();

    await _locationService.saveLocationToFirestore({
      'city': city,
      'area': area,
    });
  }

  void clearLocation() {
    _city = '';
    _area = '';
    _hasLocation = false;
    notifyListeners();
  }
}
