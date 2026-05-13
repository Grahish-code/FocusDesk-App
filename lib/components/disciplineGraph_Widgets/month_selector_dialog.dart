import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Formats a month key like "2024-03" → "MAR 24", or "LAST 30" → "LAST 30 DAYS"
String formatMonthLabel(String month) {
  if (month == "LAST 30") return "LAST 30 DAYS";
  final parts = month.split('-');
  final year = parts[0].substring(2);
  const monthNames = [
    "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
    "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
  ];
  final monthIndex = int.parse(parts[1]) - 1;
  return "${monthNames[monthIndex]} $year";
}

/// Shows a bottom dialog for selecting a month/timeframe.
/// Calls [onMonthSelected] with the chosen month key when tapped.
void showMonthSelectorDialog({
  required BuildContext context,
  required List<String> availableMonths,
  required String selectedMonth,
  required ValueChanged<String> onMonthSelected,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: const Color(0xFF0D1117),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "SELECT TIMEFRAME",
                style: GoogleFonts.orbitron(
                  color: Colors.cyanAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 15),
              Divider(color: Colors.white.withValues(alpha: 0.1)),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: availableMonths.length,
                  itemBuilder: (context, index) {
                    final month = availableMonths[index];
                    final isSelected = month == selectedMonth;

                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      tileColor: isSelected
                          ? Colors.cyanAccent.withValues(alpha: 0.1)
                          : Colors.transparent,
                      title: Text(
                        formatMonthLabel(month),
                        style: GoogleFonts.orbitron(
                          color: isSelected ? Colors.cyanAccent : Colors.white70,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.cyanAccent, size: 18)
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        if (month != selectedMonth) {
                          onMonthSelected(month);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}