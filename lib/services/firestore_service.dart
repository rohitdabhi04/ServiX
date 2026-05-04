import 'user_service.dart';
import 'service_service.dart';
import 'booking_service.dart';

class FirestoreService {
  final userService = UserService();
  final serviceService = ServiceService();
  final bookingService = BookingService();
}