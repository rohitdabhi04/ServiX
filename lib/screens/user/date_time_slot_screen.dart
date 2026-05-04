import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';

/// A full-page date & time-slot picker shown before confirming a booking.
/// Returns a Map<String, dynamic> with keys: 'date' (DateTime) and 'time' (String).
class DateTimeSlotScreen extends StatefulWidget {
  final String serviceName;

  const DateTimeSlotScreen({super.key, required this.serviceName});

  @override
  State<DateTimeSlotScreen> createState() => _DateTimeSlotScreenState();
}

class _DateTimeSlotScreenState extends State<DateTimeSlotScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTime;
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;

  // Available time slots (customize as needed)
  static const List<String> _timeSlots = [
    "08:00 AM", "09:00 AM", "10:00 AM", "11:00 AM",
    "12:00 PM", "01:00 PM", "02:00 PM", "03:00 PM",
    "04:00 PM", "05:00 PM", "06:00 PM", "07:00 PM",
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Select Date & Time"),
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
              // ── Service banner ──────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.userGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.miscellaneous_services,
                        color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.serviceName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Date picker ─────────────────────────────────────────────
              _sectionLabel("Select Date", Icons.calendar_month_rounded),
              const SizedBox(height: 12),
              _DateCarousel(
                selected: _selectedDate,
                onChanged: (d) => setState(() {
                  _selectedDate = d;
                  _selectedTime = null; // reset time when date changes
                }),
              ),

              const SizedBox(height: 28),

              // ── Time slots ──────────────────────────────────────────────
              _sectionLabel("Select Time Slot", Icons.access_time_rounded),
              const SizedBox(height: 12),
              _TimeSlotsGrid(
                slots: _timeSlots,
                selected: _selectedTime,
                onTap: (t) => setState(() => _selectedTime = t),
              ),

              const SizedBox(height: 36),

              // ── Confirm button ──────────────────────────────────────────
              AnimatedOpacity(
                opacity: _selectedTime != null ? 1.0 : 0.45,
                duration: const Duration(milliseconds: 200),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _selectedTime == null
                        ? null
                        : () => Navigator.pop(context, {
                      'date': _selectedDate,
                      'time': _selectedTime,
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.userPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _selectedTime == null
                          ? "Choose a time slot"
                          : "Confirm — ${DateFormat('d MMM').format(_selectedDate)}, $_selectedTime",
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
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

  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.userPrimary),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ── Date Carousel ──────────────────────────────────────────────────────────────

class _DateCarousel extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;

  const _DateCarousel({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    // Show next 30 days
    final dates = List.generate(30, (i) => today.add(Duration(days: i + 1)));

    return SizedBox(
      height: 78,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = DateUtils.isSameDay(date, selected);

          return GestureDetector(
            onTap: () => onChanged(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              width: 58,
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.userGradient : null,
                color: isSelected ? null : theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: isSelected
                    ? null
                    : Border.all(color: theme.dividerColor, width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date),
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? Colors.white70
                          : theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(date),
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected
                          ? Colors.white70
                          : theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Time Slots Grid ────────────────────────────────────────────────────────────

class _TimeSlotsGrid extends StatelessWidget {
  final List<String> slots;
  final String? selected;
  final ValueChanged<String> onTap;

  const _TimeSlotsGrid(
      {required this.slots, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: slots.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final slot = slots[index];
        final isSelected = slot == selected;

        return GestureDetector(
          onTap: () => onTap(slot),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.userGradient : null,
              color: isSelected ? null : theme.cardColor,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? null
                  : Border.all(color: theme.dividerColor, width: 1),
            ),
            alignment: Alignment.center,
            child: Text(
              slot,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : null,
              ),
            ),
          ),
        );
      },
    );
  }
}