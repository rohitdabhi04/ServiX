import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../services/notification_service.dart';

/// Reschedule screen — user OR provider can pick a new date/time.
/// Pass [isProvider] = true when opened from provider side.
class RescheduleBookingScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;
  final bool isProvider;

  const RescheduleBookingScreen({
    super.key,
    required this.bookingId,
    required this.bookingData,
    this.isProvider = false,
  });

  @override
  State<RescheduleBookingScreen> createState() =>
      _RescheduleBookingScreenState();
}

class _RescheduleBookingScreenState extends State<RescheduleBookingScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTime;
  bool _isSaving = false;

  late AnimationController _ctrl;
  late Animation<double> _fade;

  static const List<String> _timeSlots = [
    "08:00 AM", "09:00 AM", "10:00 AM", "11:00 AM",
    "12:00 PM", "01:00 PM", "02:00 PM", "03:00 PM",
    "04:00 PM", "05:00 PM", "06:00 PM", "07:00 PM",
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill existing schedule
    final existingDate = widget.bookingData['scheduledDate'];
    if (existingDate != null) {
      _selectedDate = (existingDate as Timestamp).toDate();
    }
    _selectedTime = widget.bookingData['scheduledTime'] as String?;

    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.userPrimary,
              brightness: Theme.of(ctx).brightness),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a time slot")));
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection("bookings")
          .doc(widget.bookingId)
          .update({
        "scheduledDate": Timestamp.fromDate(_selectedDate),
        "scheduledTime": _selectedTime,
        "rescheduledBy": widget.isProvider ? "provider" : "user",
        "rescheduledAt": FieldValue.serverTimestamp(),
        "status": "Pending", // reset to pending after reschedule
      });

      // Notify the other party
      final data = widget.bookingData;
      final serviceName = data['serviceName'] ?? "Service";
      final formattedDate =
          DateFormat("EEE, dd MMM yyyy").format(_selectedDate);

      if (widget.isProvider) {
        final userId = data['userId'] as String?;
        final providerName = data['providerName'] ?? "Provider";
        if (userId != null) {
          await NotificationService.sendNotificationToUser(
            userId: userId,
            title: "📅 Appointment Rescheduled",
            body:
                "$providerName rescheduled \"$serviceName\" to $formattedDate at $_selectedTime",
            bookingId: widget.bookingId,
          );
        }
      } else {
        final providerId = data['providerId'] as String?;
        final userName = data['userName'] ?? "User";
        if (providerId != null) {
          await NotificationService.sendNotificationToUser(
            userId: providerId,
            title: "📅 Appointment Rescheduled by User",
            body:
                "$userName rescheduled \"$serviceName\" to $formattedDate at $_selectedTime",
            bookingId: widget.bookingId,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Appointment rescheduled successfully!"),
            backgroundColor: Colors.green.shade600,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final serviceName =
        widget.bookingData['serviceName'] ?? "Service";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Reschedule Appointment"),
        centerTitle: true,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fade,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Service Banner ────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.userGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_repeat,
                        color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Rescheduling",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          Text(serviceName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Date Picker ────────────────────────────────────────────────
              Text("Select New Date",
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cardColor
                        : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.userPrimary.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          color: AppColors.userPrimary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          DateFormat("EEEE, dd MMMM yyyy")
                              .format(_selectedDate),
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(Icons.edit_calendar_outlined,
                          color: Colors.grey.shade500, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Time Slots ─────────────────────────────────────────────────
              Text("Select New Time Slot",
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.6,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _timeSlots.length,
                itemBuilder: (context, i) {
                  final slot = _timeSlots[i];
                  final isSelected = _selectedTime == slot;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTime = slot),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.userPrimary
                            : (isDark
                                ? AppColors.cardColor
                                : AppColors.lightCard),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.userPrimary
                              : (isDark
                                  ? AppColors.border
                                  : AppColors.borderLight),
                        ),
                      ),
                      child: Text(
                        slot,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : theme.textTheme.bodySmall?.color,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // ── Info note ──────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.blue, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "The booking status will reset to Pending after rescheduling. The other party will be notified.",
                        style: TextStyle(
                            color: Colors.blue, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Confirm Button ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline),
                  label: Text(_isSaving
                      ? "Saving..."
                      : "Confirm Reschedule"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.userPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
