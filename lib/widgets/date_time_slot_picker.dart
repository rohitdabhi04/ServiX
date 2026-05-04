import 'package:flutter/material.dart';
import '../screens/user/date_time_slot_screen.dart';

/// Wrapper model returned by DateTimeSlotPicker.show()
class DateTimeSlot {
  final DateTime date;
  final String time;
  const DateTimeSlot({required this.date, required this.time});
}

/// Static helper that opens DateTimeSlotScreen as a full-page route
/// and returns a [DateTimeSlot] (or null if user dismissed).
///
/// Usage:
///   final slot = await DateTimeSlotPicker.show(context, serviceName: 'Cleaning');
///   if (slot == null) return;
///   print(slot.date); print(slot.time);
class DateTimeSlotPicker {
  DateTimeSlotPicker._();

  static Future<DateTimeSlot?> show(
      BuildContext context, {
        String serviceName = '',
      }) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => DateTimeSlotScreen(serviceName: serviceName),
      ),
    );

    if (result == null) return null;

    final date = result['date'] as DateTime?;
    final time = result['time'] as String?;

    if (date == null || time == null) return null;

    return DateTimeSlot(date: date, time: time);
  }
}