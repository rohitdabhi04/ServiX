import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/booking_service.dart';
import '../../widgets/user_avatar.dart';
import 'reschedule_booking_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String bookingId;

  const BookingDetailScreen({
    super.key,
    required this.data,
    required this.bookingId,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final BookingService _bookingService = BookingService();
  bool _isCancelling = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final serviceName = widget.data['serviceName'] ?? "Service";
    final price = widget.data['price']?.toString() ?? "0";
    final status = widget.data['status'] ?? "Pending";
    final providerName = widget.data['providerName'] ?? "Unknown Provider";
    final providerId = widget.data['providerId'] ?? "";
    final createdAt = widget.data['createdAt'];
    final scheduledDate = widget.data['scheduledDate'];
    final scheduledTime = widget.data['scheduledTime'] as String?;
    final cancelledBy = widget.data['cancelledBy'] as String?;
    final cancellationReason = widget.data['cancellationReason'] as String?;

    String formattedCreated = "N/A";
    String formattedScheduled = "Not specified";

    try {
      if (createdAt != null) {
        formattedCreated =
            DateFormat("dd MMM yyyy, hh:mm a").format(createdAt.toDate());
      }
      if (scheduledDate != null) {
        formattedScheduled =
            DateFormat("EEEE, dd MMM yyyy").format(scheduledDate.toDate());
        if (scheduledTime != null) formattedScheduled += " at $scheduledTime";
      }
    } catch (_) {}

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case "Completed":
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case "Pending":
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
      case "Accepted":
        statusColor = Colors.blue;
        statusIcon = Icons.thumb_up;
        break;
      case "Rejected":
      case "Cancelled":
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking Details"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Service Card ─────────────────────────────────────────────
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.miscellaneous_services, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(serviceName,
                          style: theme.textTheme.titleLarge),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Price ────────────────────────────────────────────────────
            _infoRow(Icons.currency_rupee, "Price: ₹$price"),
            const SizedBox(height: 12),

            // ── Booked On ────────────────────────────────────────────────
            _infoRow(Icons.calendar_today, "Booked On: $formattedCreated"),
            const SizedBox(height: 12),

            // ── Scheduled Appointment ────────────────────────────────────
            _infoRow(
              Icons.event_available,
              "Appointment: $formattedScheduled",
              color: (scheduledDate != null) ? Colors.blue : null,
            ),
            const SizedBox(height: 12),

            // ── Provider ─────────────────────────────────────────────────
            Row(
              children: [
                UserAvatar(
                    userId: providerId,
                    fallbackName: providerName,
                    radius: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text("Provider: $providerName",
                      style: theme.textTheme.bodyMedium),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Status Card ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor),
                  const SizedBox(width: 10),
                  Text(
                    status,
                    style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ],
              ),
            ),

            // ── Cancellation Info ────────────────────────────────────────
            if (status == "Cancelled" &&
                cancellationReason != null &&
                cancellationReason.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Cancelled by: ${cancelledBy == 'user' ? 'You' : 'Provider'}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const SizedBox(height: 6),
                    Text("Reason: $cancellationReason",
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),

            // ── Action Buttons ───────────────────────────────────────────
            if (status == "Pending" || status == "Accepted") ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RescheduleBookingScreen(
                        bookingId: widget.bookingId,
                        bookingData: widget.data,
                        isProvider: false,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.event_repeat),
                  label: const Text("Reschedule Appointment"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.indigo,
                    side: const BorderSide(color: Colors.indigo),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isCancelling ? null : _confirmCancel,
                  icon: _isCancelling
                      ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.cancel_outlined),
                  label: Text(
                      _isCancelling ? "Cancelling..." : "Cancel Booking"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],

            if (status == "Completed") ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text("Leave Review"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: color != null ? FontWeight.w500 : null)),
        ),
      ],
    );
  }

  Future<void> _confirmCancel() async {
    final reason = await _showCancelDialog(context);
    if (reason == null || reason.trim().isEmpty) return;

    setState(() => _isCancelling = true);
    await _bookingService.cancelBooking(
      bookingId: widget.bookingId,
      cancelledBy: "user",
      reason: reason.trim(),
    );
    if (mounted) {
      setState(() => _isCancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Booking cancelled successfully."),
            backgroundColor: Colors.red),
      );
      Navigator.pop(context);
    }
  }

  /// Shows a dialog to choose a cancel reason. Returns null if dismissed.
  static Future<String?> _showCancelDialog(BuildContext context) async {
    final controller = TextEditingController();
    String? quickPick;

    const quickReasons = [
      "Change of plans",
      "Found a better option",
      "Scheduled time conflict",
      "Service no longer needed",
    ];

    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text("Cancel Booking"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Select or type a reason:"),
                    const SizedBox(height: 12),
                    // Quick-pick chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: quickReasons.map((r) {
                        final selected = quickPick == r;
                        return ChoiceChip(
                          label: Text(r, style: const TextStyle(fontSize: 12)),
                          selected: selected,
                          onSelected: (_) {
                            setLocal(() {
                              quickPick = r;
                              controller.text = r;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: "Or type your reason here...",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      onChanged: (_) => setLocal(() => quickPick = null),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Keep Booking")),
                ElevatedButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    Navigator.pop(ctx, text);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white),
                  child: const Text("Confirm Cancel"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}