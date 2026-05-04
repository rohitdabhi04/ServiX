import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField>
    with SingleTickerProviderStateMixin {
  bool _obscure = true;
  bool _focused = false;
  late FocusNode _focusNode;
  late AnimationController _animCtrl;
  late Animation<double> _borderAnim;
  late Animation<double> _iconScaleAnim;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _borderAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _iconScaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack),
    );

    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
      if (_focusNode.hasFocus) {
        _animCtrl.forward();
      } else {
        _animCtrl.reverse();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _borderAnim,
      builder: (context, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.isPassword ? _obscure : false,
            keyboardType: widget.keyboardType,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            cursorColor: theme.colorScheme.primary,
            cursorRadius: const Radius.circular(2),
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: widget.prefixIcon != null
                  ? ScaleTransition(
                      scale: _iconScaleAnim,
                      child: Icon(
                        widget.prefixIcon,
                        color: _focused
                            ? theme.colorScheme.primary
                            : theme.iconTheme.color,
                        size: 20,
                      ),
                    )
                  : null,
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(scale: animation, child: child);
                        },
                        child: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          key: ValueKey(_obscure),
                          color: _focused
                              ? theme.colorScheme.primary
                              : theme.iconTheme.color,
                          size: 20,
                        ),
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }
}
