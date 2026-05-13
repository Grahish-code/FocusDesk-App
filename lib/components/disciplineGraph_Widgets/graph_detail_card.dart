import 'package:flutter/material.dart';
import 'package:focusdesk/services/storage_service.dart';
import 'package:google_fonts/google_fonts.dart';


class GraphDetailCard extends StatelessWidget {
  final List<Map<String, dynamic>> sortedHistory;
  final int selectedIndex;

  const GraphDetailCard({
    super.key,
    required this.sortedHistory,
    required this.selectedIndex,
  });

  // ── Shared text style ──────────────────────────────────────
  static TextStyle _orbitron({
    Color color = Colors.white,
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.normal,
    double letterSpacing = 0,
    double height = 1.0,
  }) =>
      GoogleFonts.orbitron(
        fontStyle: FontStyle.italic,
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
      );

  // ── Task detail dialog ─────────────────────────────────────
  Future<void> _showTaskDialog(BuildContext context, String dateKey) async {
    // Fetch directly from SQLite — no provider needed.
    final storage = StorageService();
    List<String> goals = [];
    Map<String, bool> statuses = {};

    try {
      goals = await storage.getTodayGoals(dateKey);
      statuses = await storage.getGoalStatuses(dateKey);
    } catch (_) {}

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _TaskDialog(
        dateKey: dateKey,
        goals: goals,
        statuses: statuses,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (sortedHistory.isEmpty ||
        selectedIndex == -1 ||
        selectedIndex >= sortedHistory.length) {
      return const SizedBox(height: 60);
    }

    final data = sortedHistory[selectedIndex];
    final String dateKey = data['date'];
    final int completed = (data['completed_goals'] as List).length;
    final int total = (data['total_goals'] as List).length;
    final bool isSuccess = data['status'] == 'Completed';
    // isAwol is kept for display compatibility but no longer written by new
    // logic — existing old records in DB may still carry this reason.
    final bool isAwol = data['reason'] == "AWOL - System Ignored";
    final bool hasNoTasks = total == 0;
    final String formattedDate = _formatDate(dateKey);

    // Whether the performance column is tappable (needs tasks to show)
    final bool isTappable = !isAwol && !hasNoTasks;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(selectedIndex),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSuccess
                ? Colors.cyanAccent.withValues(alpha: 0.3)
                : Colors.redAccent.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ── Date column ──────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "DATE RECORD",
                  style: _orbitron(
                    color: Colors.white38,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: _orbitron(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            Container(width: 1, height: 30, color: Colors.white12),

            // ── Performance column (tappable when tasks exist) ─
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "PERFORMANCE",
                  style: _orbitron(
                    color: Colors.white38,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),

                if (isAwol)
                  Text(
                    "NO TASK",
                    style: _orbitron(
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else if (hasNoTasks)
                  Text(
                    "NO TASKS",
                    style: _orbitron(
                      color: Colors.white38,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                // Tappable performance value
                  InkWell(
                    onTap: () => _showTaskDialog(context, dateKey),
                    borderRadius: BorderRadius.circular(6),
                    splashColor: Colors.cyanAccent.withValues(alpha: 0.15),
                    highlightColor: Colors.cyanAccent.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            "$completed/$total",
                            style: _orbitron(
                              color: isSuccess
                                  ? Colors.cyanAccent
                                  : Colors.redAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            " TASKS",
                            style: _orbitron(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Subtle tap indicator
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 11,
                            color: isTappable
                                ? Colors.white38
                                : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(String date) {
    const monthNames = [
      "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
      "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
    ];
    final parts = date.split('-');
    final day = parts[2];
    final monthName = monthNames[int.parse(parts[1]) - 1];
    return "$day $monthName";
  }
}

// ================================================================
// Task detail dialog — same dark design as FailureReasonPage
// ================================================================
class _TaskDialog extends StatelessWidget {
  final String dateKey;
  final List<String> goals;
  final Map<String, bool> statuses;

  const _TaskDialog({
    required this.dateKey,
    required this.goals,
    required this.statuses,
  });

  static TextStyle _orbitron({
    Color color = Colors.white,
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.normal,
    double letterSpacing = 0,
    double height = 1.0,
  }) =>
      GoogleFonts.orbitron(
        fontStyle: FontStyle.italic,
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
      );

  String get _formattedDate {
    const monthNames = [
      "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
      "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
    ];
    final parts = dateKey.split('-');
    final day = parts[2];
    final monthName = monthNames[int.parse(parts[1]) - 1];
    final year = parts[0];
    return "$day $monthName $year";
  }

  @override
  Widget build(BuildContext context) {
    final int completedCount =
        goals.where((g) => statuses[g] == true).length;
    final int total = goals.length;
    final bool allDone = completedCount == total && total > 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF252525), Color(0xFF000000)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: allDone
                ? Colors.cyanAccent.withValues(alpha: 0.3)
                : Colors.redAccent.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Dialog header ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "TASK BREAKDOWN",
                          style: _orbitron(
                            color: Colors.redAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formattedDate,
                          style: _orbitron(
                            color: Colors.white,
                            fontSize: 14,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Completion summary pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: allDone
                                ? Colors.cyanAccent.withValues(alpha: 0.12)
                                : Colors.redAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: allDone
                                  ? Colors.cyanAccent.withValues(alpha: 0.4)
                                  : Colors.redAccent.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            "$completedCount / $total COMPLETED",
                            style: _orbitron(
                              color: allDone
                                  ? Colors.cyanAccent
                                  : Colors.redAccent,
                              fontSize: 11,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close button
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white38, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 12),

            // ── Task list ──────────────────────────────────
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: goals.isEmpty
                  ? Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Text(
                  "No tasks were recorded for this day.",
                  style: _orbitron(
                    color: Colors.white38,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              )
                  : ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                itemCount: goals.length,
                itemBuilder: (context, index) {
                  final goal = goals[index];
                  final isDone = statuses[goal] ?? false;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isDone
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: isDone
                              ? Colors.cyanAccent
                              : Colors.white38,
                          size: 20,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            goal,
                            style: _orbitron(
                              color: isDone
                                  ? Colors.white
                                  : Colors.white54,
                              fontSize: 13,
                              height: 1.4,
                            ).copyWith(
                              decoration: isDone
                                  ? null
                                  : TextDecoration.lineThrough,
                              decorationColor: Colors.white24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}