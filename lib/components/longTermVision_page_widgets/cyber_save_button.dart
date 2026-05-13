import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:focusdesk/providers/app_provider.dart';

class CyberSaveButton extends StatelessWidget {
  final TextEditingController goal30Controller;
  final TextEditingController goal60Controller;
  final TextEditingController longTermController;
  final Color activeColor;

  const CyberSaveButton({
    super.key,
    required this.goal30Controller,
    required this.goal60Controller,
    required this.longTermController,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      // Listens to BOTH controllers in real-time as the user types
      animation: Listenable.merge([goal30Controller, goal60Controller]),
      builder: (context, child) {
        // STRICT CHECK: Both 30 and 60 days must not be empty
        bool isReady = goal30Controller.text.trim().isNotEmpty &&
            goal60Controller.text.trim().isNotEmpty;

        Color buttonThemeColor = isReady ? activeColor : Colors.white24;
        Color textColor = isReady ? activeColor : Colors.white54;

        return GestureDetector(
            onTap: () async {
              if (isReady) {
                HapticFeedback.mediumImpact();

                // 1. Tell the provider to save the data.
                // Inside this function, the provider automatically runs _checkTimeAndGoals()
                // and updates the AppState. The ScreenRouter will swap the page instantly.
                await context.read<AppProvider>().saveLongTermStrategy(
                  goal30: goal30Controller.text.trim(),
                  goal60: goal60Controller.text.trim(),
                  longTerm: longTermController.text.trim(),
                );

                // 2. Show the success message.
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      content: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF222222).withValues(alpha: 0.9),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check, color: activeColor),
                                const SizedBox(width: 12),
                                Text(
                                  "Strategy Saved Successfully",
                                  style: GoogleFonts.inter(
                                      color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                // 3. NO NAVIGATOR CODE HERE.
                // The ScreenRouter handles the transition.

              } else {
                HapticFeedback.heavyImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("SYSTEM LOCKED: Fill 30-Day and 60-Day goals to proceed."),
                    backgroundColor: Colors.redAccent,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 55,
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
                topRight: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(
                color: buttonThemeColor.withValues(alpha: isReady ? 0.3 : 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: buttonThemeColor.withValues(alpha: isReady ? 0.1 : 0.0),
                  blurRadius: isReady ? 15 : 0,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isReady ? Icons.check_circle_outline : Icons.lock_outline,
                  color: textColor,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  "CONFIRM GOALS",
                  style: GoogleFonts.orbitron(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}