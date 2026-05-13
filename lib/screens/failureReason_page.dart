import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';

class FailureReasonPage extends StatefulWidget {
  const FailureReasonPage({super.key});

  @override
  State<FailureReasonPage> createState() => _FailureReasonPageState();
}

class _FailureReasonPageState extends State<FailureReasonPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _reasonController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  TextStyle get _orbitron =>
      GoogleFonts.orbitron(fontStyle: FontStyle.italic);

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeIn));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _animController, curve: Curves.easeOutBack));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  // ── Date label helpers ──────────────────────────────────────────────────

  /// Returns a display string for the date range the user needs to account for.
  ///
  /// Single missed day  → "SUNDAY, 4 MAY"
  /// Multiple missed days → "MAY 21 – MAY 22"
  String _buildDateLabel(List<String> missedDays) {
    if (missedDays.isEmpty) {
      // Standard case: just yesterday
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      return DateFormat('EEEE, d MMM').format(yesterday).toUpperCase();
    }

    if (missedDays.length == 1) {
      final day = DateTime.parse(missedDays.first);
      return DateFormat('EEEE, d MMM').format(day).toUpperCase();
    }

    // Range: first missed day → last missed day
    final first = DateTime.parse(missedDays.first);
    final last = DateTime.parse(missedDays.last);
    final firstStr = DateFormat('d MMM').format(first).toUpperCase();
    final lastStr = DateFormat('d MMM').format(last).toUpperCase();
    return '$firstStr – $lastStr';
  }

  /// Returns the subtitle shown under the goal list explaining which day's
  /// goals are being displayed (always the most recent missed day).
  String _buildGoalDayLabel(List<String> missedDays) {
    if (missedDays.isEmpty) {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      return DateFormat('EEEE, d MMM').format(yesterday).toUpperCase();
    }
    final last = DateTime.parse(missedDays.last);
    return DateFormat('EEEE, d MMM').format(last).toUpperCase();
  }

  /// Hint text for the input field.
  String _buildHintText(List<String> missedDays) {
    if (missedDays.length > 1) {
      return "What held you back during these days?";
    }
    return "What held you back?";
  }

  /// Contextual note shown under the header.
  String _buildNote(List<String> missedDays) {
    if (missedDays.length > 1) {
      return "It's okay. Your reason will be logged for all ${missedDays.length} missed days.\nBe honest — understanding why is how you get better.";
    }
    return "It's okay to fail sometimes.\nThe important thing is to understand why.";
  }

  // ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final goals = provider.savedGoals;
    final status = provider.goalStates;
    final missedDays = provider.missedDays; // List<String> of missed date keys

    final dateLabel = _buildDateLabel(missedDays);
    final goalDayLabel = _buildGoalDayLabel(missedDays);
    final hintText = _buildHintText(missedDays);
    final noteText = _buildNote(missedDays);
    final isMultiDay = missedDays.length > 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF252525), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. HEADER SECTION ---
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "MISSION REPORT",
                          style: _orbitron.copyWith(
                            color: Colors.redAccent,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),

                        // Date range label — single day or "MAY 21 – MAY 22"
                        Text(
                          "FOR $dateLabel",
                          style: _orbitron.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                            letterSpacing: 1.5,
                          ),
                        ),

                        // Multi-day badge — only shown when gap > 1 day
                        if (isMultiDay) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: Colors.redAccent.withValues(alpha: 0.4),
                                  width: 1),
                            ),
                            child: Text(
                              "${missedDays.length} DAYS UNACCOUNTED",
                              style: _orbitron.copyWith(
                                color: Colors.redAccent,
                                fontSize: 11,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 15),

                        // Contextual encouraging note
                        Container(
                          padding: const EdgeInsets.only(left: 10),
                          decoration: const BoxDecoration(
                            border: Border(
                                left: BorderSide(
                                    color: Colors.white24, width: 2)),
                          ),
                          child: Text(
                            noteText,
                            style: _orbitron.copyWith(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- 2. GOAL LIST SECTION HEADER ---
                // Clarifies which day's goals are shown (always the most
                // recent missed day so the user has context).
                Row(
                  children: [
                    Text(
                      "GOALS FOR $goalDayLabel:",
                      style: _orbitron.copyWith(
                        color: Colors.cyanAccent,
                        fontSize: 11,
                        letterSpacing: 1.1,
                      ),
                    ),
                    if (isMultiDay) ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message:
                        "Showing goals from your most recent missed day.\nYour reason will apply to all missed days.",
                        child: Icon(
                          Icons.info_outline,
                          color: Colors.white38,
                          size: 14,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 10),

                // --- 3. GOAL LIST ---
                Expanded(
                  child: ListView.builder(
                    itemCount: goals.length,
                    itemBuilder: (context, index) {
                      final goal = goals[index];
                      final isDone = status[goal] ?? false;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(15),
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
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                goal,
                                style: _orbitron.copyWith(
                                  color: isDone
                                      ? Colors.white
                                      : Colors.white54,
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

                const SizedBox(height: 20),

                // --- 4. REASON INPUT ---
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ANALYSIS:",
                      style: _orbitron.copyWith(
                          color: Colors.cyanAccent, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reasonController,
                      style: _orbitron.copyWith(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle:
                        _orbitron.copyWith(color: Colors.white24),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Colors.cyanAccent, width: 1),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // --- 5. SUBMIT BUTTON ---
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_reasonController.text.trim().isNotEmpty) {
                        provider.submitFailureReason(
                            _reasonController.text.trim());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      "LOG & CONTINUE",
                      style: _orbitron.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}