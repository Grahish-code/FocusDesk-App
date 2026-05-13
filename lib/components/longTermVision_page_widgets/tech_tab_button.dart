import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TechTabButton extends StatelessWidget {
  final int index;
  final String label;
  final String subLabel;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const TechTabButton({
    super.key,
    required this.index,
    required this.label,
    required this.subLabel,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isSelected = selectedIndex == index;

    // Determine the color ONLY for this specific tab
    Color tabColor;
    if (index == 0) {
      tabColor = Colors.cyanAccent;
    } else if (index == 1) {
      tabColor = const Color(0xFFD946EF); // Neon Purple
    } else {
      tabColor = const Color(0xFF00FF9D); // Neon Green
    }

    // If not selected, show it faded white. If selected, show its full color.
    Color displayColor = isSelected ? tabColor : Colors.white24;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 70,
          decoration: BoxDecoration(
            color: isSelected ? tabColor.withValues(alpha: 0.1) : const Color(0xFF0F0F0F),
            border: Border.all(
              color: displayColor.withValues(alpha: isSelected ? 0.6 : 0.1),
              width: 1,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: tabColor.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 1,
              )
            ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: GoogleFonts.orbitron(
                  fontSize: 10,
                  color: isSelected ? tabColor : Colors.white38,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subLabel,
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}