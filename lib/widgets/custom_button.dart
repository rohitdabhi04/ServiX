import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final LinearGradient? gradient;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.gradient,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();

    // Press scale animation
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOutCubic),
    );

    // Subtle glow pulse animation
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.25, end: 0.45).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = widget.onPressed == null;

    final gradient = widget.gradient ??
        LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
        );

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => _scaleCtrl.forward(),
      onTapUp: isDisabled
          ? null
          : (_) {
              _scaleCtrl.reverse();
              widget.onPressed?.call();
            },
      onTapCancel: isDisabled ? null : () => _scaleCtrl.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnim, _glowAnim]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: isDisabled ? null : gradient,
                color: isDisabled ? AppColors.textGrey.withOpacity(0.3) : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDisabled
                    ? null
                    : [
                        BoxShadow(
                          color: theme.colorScheme.primary
                              .withOpacity(_glowAnim.value),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                          spreadRadius: -2,
                        ),
                      ],
              ),
              child: widget.isLoading
                  ? Center(
                      child: SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.text,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
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
