import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HoloInputCard extends StatelessWidget {
  final int selectedIndex;
  final Color activeColor;
  final AnimationController pulseController;
  final TextEditingController goal30Controller;
  final TextEditingController goal60Controller;
  final TextEditingController longTermController;

  const HoloInputCard({
    super.key,
    required this.selectedIndex,
    required this.activeColor,
    required this.pulseController,
    required this.goal30Controller,
    required this.goal60Controller,
    required this.longTermController,
  });

  @override
  Widget build(BuildContext context) {
    String title, subtitle, hint;
    TextEditingController activeController;

    switch (selectedIndex) {
      case 0:
        title = "30-DAYS GOAL";
        subtitle = "Immediate tasks to achieve";
        activeController = goal30Controller;
        hint = "What do you need to achieve this month?";
        break;
      case 1:
        title = "60-DAY GOAL";
        subtitle = "Mid-term consistency";
        activeController = goal60Controller;
        hint = "Where do you see yourself in two months?";
        break;
      case 2:
      default:
        title = "LONG TERM VISION";
        subtitle = "Life career";
        activeController = longTermController;
        hint = "Define your major goal (e.g., University, Job, Project)...";
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child));
      },
      child: Container(
        key: ValueKey<int>(selectedIndex),
        padding: const EdgeInsets.all(2), // Space for border
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              activeColor.withValues(alpha: 0.5),
              Colors.transparent,
              activeColor.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF050505),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- CARD HEADER ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                  border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.orbitron(
                            color: activeColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(color: activeColor.withValues(alpha: 0.5), blurRadius: 10),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle.toUpperCase(),
                          style: GoogleFonts.orbitron(
                            color: Colors.white38,
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    // Rotating Decor Icon
                    AnimatedBuilder(
                      animation: pulseController,
                      builder: (context, child) {
                        return Icon(
                          Icons.data_saver_on,
                          color: activeColor.withValues(alpha: 0.5 + (pulseController.value * 0.5)),
                          size: 24,
                        );
                      },
                    ),
                  ],
                ),
              ),

              // --- TEXT AREA ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: TextField(
                    controller: activeController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: null,
                    expands: true,
                    style: GoogleFonts.orbitron(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      height: 1.6,
                    ),
                    cursorColor: activeColor,
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: GoogleFonts.orbitron(
                        color: Colors.white12,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              // --- DECORATIVE FOOTER ---
              Container(
                height: 30,
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "EDITABLE ",
                      style: GoogleFonts.orbitron(
                        fontSize: 8,
                        color: activeColor.withValues(alpha: 0.5),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}