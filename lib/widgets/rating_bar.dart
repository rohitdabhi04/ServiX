import 'package:flutter/material.dart';

/// ⭐ Interactive Star Rating Bar
class RatingBar extends StatefulWidget {
  final double initialRating;
  final int itemCount;
  final double itemSize;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<double>? onRatingChanged;
  final bool readOnly;

  const RatingBar({
    super.key,
    this.initialRating = 0,
    this.itemCount = 5,
    this.itemSize = 32,
    this.activeColor = const Color(0xFFFFC107),
    this.inactiveColor = const Color(0xFF555577),
    this.onRatingChanged,
    this.readOnly = false,
  });

  @override
  State<RatingBar> createState() => _RatingBarState();
}

class _RatingBarState extends State<RatingBar> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.itemCount, (index) {
        final starValue = index + 1.0;
        final isHalf = _rating >= starValue - 0.5 && _rating < starValue;
        final isFull = _rating >= starValue;

        return GestureDetector(
          onTap: widget.readOnly
              ? null
              : () {
                  setState(() => _rating = starValue);
                  widget.onRatingChanged?.call(starValue);
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              isFull
                  ? Icons.star_rounded
                  : isHalf
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded,
              size: widget.itemSize,
              color: (isFull || isHalf)
                  ? widget.activeColor
                  : widget.inactiveColor,
            ),
          ),
        );
      }),
    );
  }
}

/// ⭐ Display-only static rating with count
class RatingDisplay extends StatelessWidget {
  final double rating;
  final int? totalReviews;
  final double starSize;
  final bool compact;

  const RatingDisplay({
    super.key,
    required this.rating,
    this.totalReviews,
    this.starSize = 16,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 16),
        const SizedBox(width: 3),
        Text(
          rating > 0 ? rating.toStringAsFixed(1) : 'New',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: compact ? 12 : 13,
            color: rating > 0 ? const Color(0xFFFFC107) : Colors.grey,
          ),
        ),
        if (totalReviews != null && !compact) ...[
          const SizedBox(width: 4),
          Text(
            '($totalReviews)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ],
    );
  }
}
