import 'dart:ui';
import 'package:flutter/material.dart';

class GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isGlowing;

  const GlassButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.isGlowing = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: isGlowing
              ? [
            BoxShadow(
              color: Colors.cyanAccent.withValues(alpha: 0.6),
              blurRadius: 15,
              spreadRadius: 2,
            )
          ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isGlowing
                    ? Colors.cyanAccent.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.1),
                border: Border.all(
                  color: isGlowing
                      ? Colors.cyanAccent.withValues(alpha: 0.8)
                      : Colors.white24,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                icon,
                color: isGlowing ? Colors.cyanAccent : Colors.white54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}