import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../services/booking_service.dart';
import '../../widgets/user_avatar.dart';
import '../user/chat_screen.dart';
import '../user/reschedule_booking_screen.dart';

class ProviderBookingsScreen extends StatefulWidget {
  const ProviderBookingsScreen({super.key});

  @override
  State<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends State<ProviderBookingsScreen> {
  final bookingService = BookingService();
  String selectedFilter = "All";

  final List<String> filters = [
    "All", "Pending", "Accepted", "Completed", "Rejected", "Cancelled"
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return Column(
      children: [
        /// FILTER TABS
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: filters.length,
            itemBuilder: (context, index) {
              final filter = filters[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: selectedFilter == filter,
                  onSelected: (_) =>
                      setState(() => selectedFilter = filter),
                ),
              );
            },
          ),
        ),

        /// BOOKINGS LIST
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: bookingService.getProviderBookings(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _emptyState();
              }

              final allBookings = snapshot.data!.docs;
              final bookings = selectedFilter == "All"
                  ? allBookings
                  : allBookings.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return (data['status'] ?? '') == selectedFilter;
              }).toList();

              if (bookings.isEmpty) return _emptyState(filter: selectedFilter);

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final doc = bookings[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _bookingCard(context, doc.id, data, theme);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _bookingCard(BuildContext context, String bookingId,
      Map<String, dynamic> data, ThemeData theme) {
    final serviceName = data['serviceName'] ?? "Service";
    final price = data['price'] ?? 0;
    final status = data['status'] ?? "Pending";
    final userId = data['userId'] ?? "";
    final userEmail = data['userEmail'] ?? "";
    final createdAt = data['createdAt'];
    final scheduledDate = data['scheduledDate'];
    final scheduledTime = data['scheduledTime'] as String?;
    final cancellationReason = data['cancellationReason'] as String?;
    final cancelledBy = data['cancelledBy'] as String?;

    String formattedDate = "Date N/A";
    if (createdAt != null) {
      try {
        formattedDate =
            DateFormat("dd MMM yyyy, hh:mm a").format(createdAt.toDate());
      } catch (_) {}
    }

    String? formattedAppointment;
    if (scheduledDate != null) {
      try {
        formattedAppointment =
            DateFormat("EEE, dd MMM yyyy").format(scheduledDate.toDate());
        if (scheduledTime != null) formattedAppointment += " · $scheduledTime";
      } catch (_) {}
    }

    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Service + Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        serviceName,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                /// User info
                Row(
                  children: [
                    UserAvatar(
                        userId: userId,
                        fallbackName: userEmail,
                        radius: 14),
                    const SizedBox(width: 6),
                    Text(userEmail,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey)),
                  ],
                ),

                const SizedBox(height: 4),

                /// Booked on
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(formattedDate,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey)),
                  ],
                ),

                /// Appointment slot (if set)
                if (formattedAppointment != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.event_available,
                          size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        "Appointment: $formattedAppointment",
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 10),

                Text(
                  "₹${price.toString()}",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),

                /// Cancellation reason
                if (status == "Cancelled" &&
                    cancellationReason != null &&
                    cancellationReason.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Cancelled by ${cancelledBy == 'user' ? 'User' : 'You'}: $cancellationReason",
                      style: const TextStyle(
                          fontSize: 11, color: Colors.redAccent),
                    ),
                  ),
                ],
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.withOpacity(0.2)),

          /// ACTIONS
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                /// CHAT
                if (userId.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline,
                        color: Colors.blue),
                    constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: const EdgeInsets.all(6),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(receiverId: userId),
                          ));
                    },
                  )
                else
                  const SizedBox(width: 8),

                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (status == "Pending") ...[
                        _providerBtn("Accept", Colors.green, () async =>
                            bookingService.updateBookingStatus(bookingId: bookingId, status: "Accepted")),
                        _providerBtn("Reject", Colors.red, () async =>
                            bookingService.updateBookingStatus(bookingId: bookingId, status: "Rejected")),
                        _providerBtnIcon(Icons.event_repeat, "Reschedule", Colors.indigo, () =>
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => RescheduleBookingScreen(bookingId: bookingId, bookingData: data, isProvider: true),
                            ))),
                        _providerBtn("Cancel", Colors.orange, () => _providerCancel(context, bookingId)),
                      ] else if (status == "Accepted") ...[
                        _providerBtn("Mark Complete", Colors.teal, () async =>
                            bookingService.updateBookingStatus(bookingId: bookingId, status: "Completed")),
                        _providerBtnIcon(Icons.event_repeat, "Reschedule", Colors.indigo, () =>
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => RescheduleBookingScreen(bookingId: bookingId, bookingData: data, isProvider: true),
                            ))),
                        _providerBtn("Cancel", Colors.orange, () => _providerCancel(context, bookingId)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _providerBtn(String label, Color color, VoidCallback onTap) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size.zero,
      ),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _providerBtnIcon(IconData icon, String label, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size.zero,
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 13),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Future<void> _providerCancel(
      BuildContext context, String bookingId) async {
    final reason = await _showCancelDialog(context);
    if (reason == null || reason.trim().isEmpty) return;

    await bookingService.cancelBooking(
      bookingId: bookingId,
      cancelledBy: "provider",
      reason: reason.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text("Booking cancelled successfully"),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ),
      );
    }
  }

  static Future<String?> _showCancelDialog(BuildContext context) async {
    final controller = TextEditingController();
    String? quickPick;

    const quickReasons = [
      "Unavailable on this date",
      "Emergency / personal reason",
      "Service temporarily unavailable",
      "Client did not respond",
    ];

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cancel_outlined,
                          color: Colors.orange, size: 28),
                    ),
                    const SizedBox(height: 16),
                    // Title
                    const Text(
                      "Cancel Booking",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Please select or type a reason for cancellation.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    // Quick reason chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: quickReasons.map((r) {
                        final selected = quickPick == r;
                        return ChoiceChip(
                          label: Text(r,
                              style: const TextStyle(fontSize: 12)),
                          selected: selected,
                          selectedColor: Colors.orange.withOpacity(0.2),
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
                    // Text field
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
                    const SizedBox(height: 20),
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: const Text("Go Back",
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final text = controller.text.trim();
                              if (text.isEmpty) return;
                              Navigator.pop(ctx, text);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text("Confirm Cancel",
                                style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _emptyState({String? filter}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long_outlined,
              size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            filter != null && filter != "All"
                ? "No $filter bookings found"
                : "No bookings yet",
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case "Completed":
        return Colors.green;
      case "Accepted":
        return Colors.blue;
      case "Pending":
        return Colors.orange;
      case "Cancelled":
      case "Rejected":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}