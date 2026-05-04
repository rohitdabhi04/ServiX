import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _service = BookingService();

  List<BookingModel> _userBookings = [];
  List<BookingModel> _providerBookings = [];
  bool _isLoading = false;
  String? _error;

  List<BookingModel> get userBookings => _userBookings;
  List<BookingModel> get providerBookings => _providerBookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void listenToUserBookings() {
    _service.getUserBookings().listen(
          (snapshot) {
        _userBookings = snapshot.docs.map((doc) => BookingModel.fromDoc(doc)).toList();
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  void listenToProviderBookings() {
    _service.getProviderBookings().listen(
          (snapshot) {
        _providerBookings = snapshot.docs.map((doc) => BookingModel.fromDoc(doc)).toList();
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }
}