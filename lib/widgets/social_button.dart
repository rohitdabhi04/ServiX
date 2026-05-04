import 'package:flutter/material.dart';

class SocialButton extends StatefulWidget {
  final String text;
  final String? iconAsset;
  final IconData? icon;
  final VoidCallback? onPressed;

  const SocialButton({
    super.key,
    required this.text,
    this.iconAsset,
    this.icon,
    required this.onPressed,
  });

  @override
  State<SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<SocialButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.96).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
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

    return GestureDetector(
      onTapDown: (_) {
        _ctrl.forward();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        _ctrl.reverse();
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () {
        _ctrl.reverse();
        setState(() => _isPressed = false);
      },
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: _isPressed
                ? (isDark
                    ? const Color(0xFF252638)
                    : const Color(0xFFF0F1FF))
                : (isDark ? const Color(0xFF1C1D2E) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isPressed
                  ? theme.colorScheme.primary.withOpacity(0.4)
                  : (isDark
                      ? const Color(0xFF252638)
                      : const Color(0xFFE5E7EB)),
              width: _isPressed ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                blurRadius: _isPressed ? 8 : 12,
                offset: Offset(0, _isPressed ? 2 : 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null)
                Icon(widget.icon, size: 22, color: theme.colorScheme.primary),
              if (widget.iconAsset != null)
                Image.asset(widget.iconAsset!, height: 20, width: 20),
              const SizedBox(width: 10),
              Text(
                widget.text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1A1B2E),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
