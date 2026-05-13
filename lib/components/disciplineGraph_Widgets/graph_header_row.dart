import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'month_selector_dialog.dart';

class GraphHeaderRow extends StatelessWidget {
  final String selectedMonth;
  final bool isFitToScreen;
  final List<String> availableMonths;
  final VoidCallback onZoomToggle;
  final ValueChanged<String> onMonthSelected;

  const GraphHeaderRow({
    super.key,
    required this.selectedMonth,
    required this.isFitToScreen,
    required this.availableMonths,
    required this.onZoomToggle,
    required this.onMonthSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "DISCIPLINE WAVE",
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
              // Month selector pill

            ],
          ),

          const SizedBox(height: 10),


          // Zoom toggle button
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [

              InkWell(
                onTap: () => showMonthSelectorDialog(
                  context: context,
                  availableMonths: availableMonths,
                  selectedMonth: selectedMonth,
                  onMonthSelected: onMonthSelected,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        formatMonthLabel(selectedMonth),
                        style: GoogleFonts.orbitron(
                          color: Colors.cyanAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.cyanAccent,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: onZoomToggle,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isFitToScreen ? Icons.zoom_in : Icons.zoom_out,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isFitToScreen ? "EXPAND" : "FIT ALL",
                        style: GoogleFonts.orbitron(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}