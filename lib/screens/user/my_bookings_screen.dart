import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../services/booking_service.dart';
import '../../services/review_service.dart';
import '../../widgets/user_avatar.dart';
import 'review_screen.dart';
import 'booking_detail_screen.dart';
import 'chat_screen.dart';
import 'reschedule_booking_screen.dart';
import 'date_time_slot_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final bookingService = BookingService();
  String selectedFilter = "All";

  final List<String> filters = [
    "All", "Pending", "Accepted", "Completed", "Cancelled"
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("My Bookings"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: filters.length,
              itemBuilder: (context, index) {
                final filter = filters[index];
                final isSelected = selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) => setState(() => selectedFilter = filter),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: bookingService.getUserBookings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("Something went wrong, please try again"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _emptyState();
                }
                final allBookings = snapshot.data!.docs;
                final bookings = selectedFilter == "All"
                    ? allBookings
                    : allBookings.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['status'] ?? "") == selectedFilter;
                }).toList();
                if (bookings.isEmpty) return _emptyState(filter: selectedFilter);
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final doc = bookings[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _bookingCard(context, doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookingCard(BuildContext context, String bookingId, Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final serviceName = data['serviceName'] ?? "Service";
    final price = data['price'] ?? 0;
    final status = data['status'] ?? "Pending";
    final providerName = data['providerName'] ?? "Provider";
    final providerId = data['providerId'] ?? "";
    final serviceId = data['serviceId'] ?? "";
    final createdAt = data['createdAt'];
    final scheduledDate = data['scheduledDate'];
    final scheduledTime = data['scheduledTime'] as String?;

    String formattedDate = "Date N/A";
    if (createdAt != null) {
      try {
        formattedDate = DateFormat("dd MMM yyyy, hh:mm a").format(createdAt.toDate());
      } catch (_) {}
    }

    String? formattedAppt;
    if (scheduledDate != null) {
      try {
        formattedAppt = DateFormat("EEE, dd MMM yyyy").format(scheduledDate.toDate());
        if (scheduledTime != null) formattedAppt += " · $scheduledTime";
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
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top Info Section ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service name + status badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        serviceName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Provider
                Row(
                  children: [
                    UserAvatar(
                      userId: providerId,
                      fallbackName: providerName,
                      radius: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        providerName,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Booking date
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                // Appointment slot
                if (formattedAppt != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.event_available,
                          size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "Appt: $formattedAppt",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                // Price
                Text(
                  "₹${price.toString()}",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.withOpacity(0.2)),

          // ── Action Buttons ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                // Chat icon
                if (providerId.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline,
                        color: Colors.blue),
                    tooltip: "Chat with Provider",
                    constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: const EdgeInsets.all(6),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ChatScreen(receiverId: providerId)),
                    ),
                  )
                else
                  const SizedBox(width: 8),

                // Action buttons — Wrap fills remaining width
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      // RESCHEDULE
                      if (status == "Pending" || status == "Accepted")
                        _actionBtn(
                          icon: Icons.event_repeat,
                          label: "Reschedule",
                          color: Colors.indigo,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RescheduleBookingScreen(
                                  bookingId: bookingId,
                                  bookingData: data,
                                  isProvider: false,
                                ),
                              ),
                            );
                          },
                        ),
                      // CANCEL
                      if (status == "Pending")
                        _actionBtn(
                          icon: Icons.cancel_outlined,
                          label: "Cancel",
                          color: Colors.red,
                          onTap: () => _confirmCancel(context, bookingId),
                        ),
                      // REVIEW / REVIEWED
                      if (status == "Completed")
                        FutureBuilder<bool>(
                          future:
                          ReviewService().isBookingReviewed(bookingId),
                          builder: (context, snap) {
                            final isReviewed = snap.data ?? false;
                            if (isReviewed) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star_rounded,
                                        color: Colors.amber, size: 14),
                                    SizedBox(width: 4),
                                    Text("Reviewed",
                                        style: TextStyle(
                                            color: Colors.amber,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              );
                            }
                            return _actionBtn(
                              icon: Icons.star_outline_rounded,
                              label: "Review",
                              color: Colors.amber.shade700,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReviewScreen(
                                    bookingId: bookingId,
                                    serviceId: serviceId,
                                    providerId: providerId,
                                    serviceName: serviceName,
                                    providerName: providerName,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      // BOOK AGAIN
                      if (status == "Completed" || status == "Cancelled")
                        _actionBtn(
                          icon: Icons.replay_rounded,
                          label: "Book Again",
                          color: Colors.green,
                          onTap: () => _reBook(context, data),
                        ),
                      // DETAILS
                      OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingDetailScreen(
                                data: data, bookingId: bookingId),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          minimumSize: Size.zero,
                        ),
                        child: const Text("Details"),
                      ),
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

  // ── Re-Book Flow ──────────────────────────────────────────────────────────
  Future<void> _reBook(BuildContext context, Map<String, dynamic> data) async {
    final serviceName = data['serviceName'] ?? "Service";
    final serviceId = data['serviceId'] ?? "";
    final price = data['price']?.toString() ?? "0";
    final providerId = data['providerId'] ?? "";

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
          builder: (_) => DateTimeSlotScreen(serviceName: serviceName)),
    );
    if (result == null) return;

    final DateTime selectedDate = result['date'];
    final String selectedTime = result['time'];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Confirm Re-booking"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(serviceName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
                "Date: ${DateFormat('EEE, dd MMM yyyy').format(selectedDate)}",
                style: const TextStyle(fontSize: 13)),
            Text("Time: $selectedTime",
                style: const TextStyle(fontSize: 13)),
            Text("Price: ₹$price", style: const TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Book Again")),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await BookingService().bookService(
      serviceId: serviceId,
      serviceName: serviceName,
      price: price,
      providerId: providerId,
      scheduledDate: selectedDate,
      scheduledTime: selectedTime,
    );

    if (context.mounted) {
      final msg = res == "success"
          ? "Booking placed successfully!"
          : res == "already"
          ? "You already have an active booking for this service."
          : "Booking failed. Please try again.";
      final color = res == "success"
          ? Colors.green
          : res == "already"
          ? Colors.orange
          : Colors.red;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
    }
  }

  // ── Small Action Button Widget ────────────────────────────────────────────
  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── Cancel Dialog ─────────────────────────────────────────────────────────
  void _confirmCancel(BuildContext context, String bookingId) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cancel_outlined, color: Colors.red, size: 28),
              ),
              const SizedBox(height: 16),
              // Title
              const Text(
                "Cancel Booking?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Subtitle
              Text(
                "Are you sure you want to cancel this booking? This action cannot be undone.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
              ),
              const SizedBox(height: 24),
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
                      child: const Text("Keep Booking",
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await bookingService.updateBookingStatus(
                            bookingId: bookingId, status: "Cancelled");
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text("Booking cancelled successfully"),
                                ],
                              ),
                              backgroundColor: Colors.red.shade600,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              margin: const EdgeInsets.all(12),
                            ),
                          );
                        }
                      },
                      child: const Text("Yes, Cancel",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────
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

  // ── Status Color ──────────────────────────────────────────────────────────
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