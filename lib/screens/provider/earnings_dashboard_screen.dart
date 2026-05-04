import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';

class EarningsDashboardScreen extends StatefulWidget {
  const EarningsDashboardScreen({super.key});

  @override
  State<EarningsDashboardScreen> createState() =>
      _EarningsDashboardScreenState();
}

class _EarningsDashboardScreenState extends State<EarningsDashboardScreen>
    with SingleTickerProviderStateMixin {
  String _period = "weekly"; // daily | weekly | monthly
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Earnings Dashboard"),
        centerTitle: true,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fade,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("bookings")
              .where("providerId", isEqualTo: uid)
              .where("status", isEqualTo: "Completed")
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];
            final bookings = docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _EarningEntry(
                price: (data['price'] is num)
                    ? (data['price'] as num).toDouble()
                    : double.tryParse(data['price']?.toString() ?? '0') ?? 0,
                date: (data['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                serviceName: data['serviceName'] ?? "Service",
                userName: data['userName'] ?? "User",
              );
            }).toList();

            // Sort by date desc
            bookings.sort((a, b) => b.date.compareTo(a.date));

            // Compute totals
            final totalEarnings =
                bookings.fold<double>(0, (sum, e) => sum + e.price);
            final totalBookings = bookings.length;

            // Period filter
            final now = DateTime.now();
            final filtered = bookings.where((e) {
              switch (_period) {
                case "daily":
                  return e.date.year == now.year &&
                      e.date.month == now.month &&
                      e.date.day == now.day;
                case "weekly":
                  return e.date
                      .isAfter(now.subtract(const Duration(days: 7)));
                case "monthly":
                  return e.date.year == now.year &&
                      e.date.month == now.month;
                default:
                  return true;
              }
            }).toList();

            final periodEarnings =
                filtered.fold<double>(0, (sum, e) => sum + e.price);
            final periodBookings = filtered.length;

            // Build chart data
            final chartData = _buildChartData(bookings, _period, now);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Summary Header ────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.providerGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Total Earnings",
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          "₹${totalEarnings.toStringAsFixed(0)}",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _statChip(
                                Icons.receipt_long,
                                "$totalBookings Completed",
                                Colors.white),
                          ],
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Period Toggle ─────────────────────────────────────────
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _periodChip("Daily", "daily", isDark),
                        const SizedBox(width: 8),
                        _periodChip("Weekly", "weekly", isDark),
                        const SizedBox(width: 8),
                        _periodChip("Monthly", "monthly", isDark),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Period Stats ──────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          context,
                          "Period Revenue",
                          "₹${periodEarnings.toStringAsFixed(0)}",
                          Icons.currency_rupee,
                          Colors.green,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          context,
                          "Bookings",
                          "$periodBookings",
                          Icons.calendar_today,
                          Colors.blue,
                          isDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Bar Chart ─────────────────────────────────────────────
                  Text("Revenue Chart",
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _BarChart(data: chartData, isDark: isDark),

                  const SizedBox(height: 24),

                  // ── Recent Transactions ───────────────────────────────────
                  Text("Recent Transactions",
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  if (filtered.isEmpty)
                    _emptyState(context)
                  else
                    ...filtered
                        .take(10)
                        .map((e) => _transactionTile(context, e, isDark))
                        .toList(),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _periodChip(String label, String value, bool isDark) {
    final isSelected = _period == value;
    return GestureDetector(
      onTap: () => setState(() => _period = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.providerPrimary
              : (isDark ? AppColors.cardColor : AppColors.lightCard),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected
                  ? AppColors.providerPrimary
                  : (isDark ? AppColors.border : AppColors.borderLight)),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.bold : null,
                fontSize: 13)),
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  Widget _statCard(BuildContext context, String title, String value,
      IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardColor : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.border : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold)),
          Text(title,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _transactionTile(
      BuildContext context, _EarningEntry e, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardColor : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? AppColors.border : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline,
                color: Colors.green, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.serviceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(e.userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("₹${e.price.toStringAsFixed(0)}",
                  style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              Text(DateFormat("dd MMM, hh:mm a").format(e.date),
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text("No earnings for this period",
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  List<_ChartBar> _buildChartData(
      List<_EarningEntry> bookings, String period, DateTime now) {
    if (period == "daily") {
      // Last 7 hours
      return List.generate(7, (i) {
        final hour = now.hour - 6 + i;
        final label = hour < 0
            ? "${24 + hour}h"
            : "${hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)}${hour < 12 ? 'AM' : 'PM'}";
        final actualHour = (now.hour - 6 + i + 24) % 24;
        final total = bookings
            .where((e) =>
                e.date.day == now.day &&
                e.date.hour == actualHour)
            .fold<double>(0, (s, e) => s + e.price);
        return _ChartBar(label: label, value: total);
      });
    } else if (period == "weekly") {
      // Last 7 days
      return List.generate(7, (i) {
        final day = now.subtract(Duration(days: 6 - i));
        final label = DateFormat("EEE").format(day);
        final total = bookings
            .where((e) =>
                e.date.year == day.year &&
                e.date.month == day.month &&
                e.date.day == day.day)
            .fold<double>(0, (s, e) => s + e.price);
        return _ChartBar(label: label, value: total);
      });
    } else {
      // Last 6 months
      return List.generate(6, (i) {
        final month = DateTime(now.year, now.month - 5 + i);
        final label = DateFormat("MMM").format(month);
        final total = bookings
            .where((e) =>
                e.date.year == month.year &&
                e.date.month == month.month)
            .fold<double>(0, (s, e) => s + e.price);
        return _ChartBar(label: label, value: total);
      });
    }
  }
}

class _EarningEntry {
  final double price;
  final DateTime date;
  final String serviceName;
  final String userName;

  const _EarningEntry({
    required this.price,
    required this.date,
    required this.serviceName,
    required this.userName,
  });
}

class _ChartBar {
  final String label;
  final double value;
  const _ChartBar({required this.label, required this.value});
}

// ── Custom Bar Chart ─────────────────────────────────────────────────────────
class _BarChart extends StatelessWidget {
  final List<_ChartBar> data;
  final bool isDark;

  const _BarChart({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.fold<double>(0, (m, b) => b.value > m ? b.value : m);

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardColor : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.border : AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((bar) {
          final heightRatio =
              maxVal > 0 ? (bar.value / maxVal) : 0.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (bar.value > 0)
                    Text(
                      "₹${bar.value.toStringAsFixed(0)}",
                      style: const TextStyle(
                          fontSize: 8,
                          color: AppColors.providerPrimary,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    height: 100 * heightRatio.toDouble(),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.providerPrimary,
                          AppColors.providerSecondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(bar.label,
                      style: const TextStyle(
                          fontSize: 9, color: Colors.grey),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
