import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Needed for date formatting
import '../providers/app_provider.dart';

class FailureReasonPage extends StatefulWidget {
  const FailureReasonPage({super.key});

  @override
  State<FailureReasonPage> createState() => _FailureReasonPageState();
}

class _FailureReasonPageState extends State<FailureReasonPage> with SingleTickerProviderStateMixin {
  final TextEditingController _reasonController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Match the Font Style exactly
  TextStyle get _orbitron => GoogleFonts.orbitron(fontStyle: FontStyle.italic);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(duration: const Duration(seconds: 2), vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeIn)
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutBack)
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  // Helper to get yesterday's date string
  String get _yesterdayDateString {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return DateFormat('EEEE, d MMM').format(yesterday).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // Access Data
    final provider = Provider.of<AppProvider>(context);
    final goals = provider.savedGoals;
    final status = provider.goalStates;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF252525), Color(0xFF000000)]
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
                        // CYAN Header instead of Red
                        Text(
                            "MISSION REPORT",
                            style: _orbitron.copyWith(
                                color: Colors.redAccent,
                                fontSize: 24,
                                fontWeight: FontWeight.bold
                            )
                        ),
                        const SizedBox(height: 5),
                        // Shows "FOR SUNDAY, 4 JAN"
                        Text(
                            "FOR $_yesterdayDateString",
                            style: _orbitron.copyWith(
                                color: Colors.white,
                                fontSize: 16,
                                letterSpacing: 1.5
                            )
                        ),
                        const SizedBox(height: 15),

                        // --- ENCOURAGING NOTE ---
                        Container(
                          padding: const EdgeInsets.only(left: 10),
                          decoration: const BoxDecoration(
                              border: Border(left: BorderSide(color: Colors.white24, width: 2))
                          ),
                          child: Text(
                              "It's okay to fail sometimes.\nThe important thing is to understand why.",
                              style: _orbitron.copyWith(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.5
                              )
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // --- 2. GOAL LIST ---
                Expanded(
                  child: ListView.builder(
                    itemCount: goals.length,
                    itemBuilder: (context, index) {
                      String goal = goals[index];
                      bool isDone = status[goal] ?? false;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white12)
                        ),
                        child: Row(
                          children: [
                            // Softened Icons: Cyan for success, Grey for missed
                            Icon(
                                isDone ? Icons.check_circle : Icons.circle_outlined,
                                color: isDone ? Colors.cyanAccent : Colors.white38,
                                size: 20
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                                child: Text(
                                    goal,
                                    style: _orbitron.copyWith(
                                      color: isDone ? Colors.white : Colors.white54,
                                      // Only strike through if done
                                      decoration: isDone ? null : TextDecoration.lineThrough,
                                      decorationColor: Colors.white24,
                                    )
                                )
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // --- 3. REASON INPUT ---
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("ANALYSIS:", style: _orbitron.copyWith(color: Colors.cyanAccent, fontSize: 12)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reasonController,
                      style: _orbitron.copyWith(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                          hintText: "What held you back yesterday?",
                          hintStyle: _orbitron.copyWith(color: Colors.white24),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none
                          ),
                          // CYAN Border on Focus (Friendly)
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.cyanAccent, width: 1)
                          )
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // --- 4. SUBMIT BUTTON ---
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_reasonController.text.trim().isNotEmpty) {
                        provider.submitFailureReason(_reasonController.text.trim());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent, // Cyan Button
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    child: Text(
                        "LOG & CONTINUE",
                        style: _orbitron.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16
                        )
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