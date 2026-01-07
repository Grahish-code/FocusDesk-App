import 'dart:ui'; // Required for ImageFilter (Blur effect)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';

class GoalSettingPage extends StatefulWidget {
  const GoalSettingPage({super.key});
  @override
  State<GoalSettingPage> createState() => _GoalSettingPageState();
}

class _GoalSettingPageState extends State<GoalSettingPage> with SingleTickerProviderStateMixin {
  final TextEditingController _goalController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // 1. Added ScrollController
  final List<String> _goals = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    _goalController.dispose();
    _scrollController.dispose(); // Dispose scroll controller
    super.dispose();
  }

  String _getGreeting() {
    int hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return "GOOD MORNING";
    if (hour >= 12 && hour < 17) return "GOOD AFTERNOON";
    return "GOOD EVENING";
  }

  // --- FEATURE 1: ADD GOAL & AUTO SCROLL ---
  void _addGoal() {
    if (_goalController.text.isNotEmpty) {
      setState(() {
        _goals.add(_goalController.text);
        _goalController.clear();
      });

      // Schedules the scroll to happen immediately after the widget builds the new item
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut
          );
        }
      });
    }
  }

  // --- FEATURE 2: AESTHETIC CONFIRMATION LOGIC ---
  void _handleLockIn() {
    int count = _goals.length;
    String title;
    String message;
    Color statusColor;

    if (count < 3) {
      title = "MINIMAL LOAD DETECTED";
      message = "Are you sure? Only $count goals for today?";
      statusColor = Colors.orangeAccent;
    } else if (count > 6) {
      title = "OVERLOAD WARNING";
      message = "Will you be able to complete all $count of them?";
      statusColor = Colors.redAccent;
    } else {
      title = "OPTIMAL STATE";
      message = "Perfect. Let's Start.";
      statusColor = Colors.cyanAccent;
    }

    _showConfirmationDialog(title, message, statusColor);
  }

  void _showConfirmationDialog(String title, String message, Color color) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withOpacity(0.8), // Darken background
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A).withOpacity(0.9),
                border: Border.all(color: color, width: 2),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.analytics_outlined, color: color, size: 40),
                  const SizedBox(height: 15),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: _orbitron.copyWith(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: _orbitron.copyWith(
                        color: Colors.white70,
                        fontSize: 14,
                        decoration: TextDecoration.none,
                        height: 1.5
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Cancel Button
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("ADJUST", style: _orbitron.copyWith(color: Colors.white54)),
                      ),
                      // Confirm Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 10,
                            shadowColor: color.withOpacity(0.5)
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          context.read<AppProvider>().saveGoals(_goals); // Save
                        },
                        child: Text(
                          "INITIATE",
                          style: _orbitron.copyWith(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack).value,
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String userName = context.watch<AppProvider>().userName;
    if (userName.isEmpty) {
      userName = "WARRIOR";
    }

    final dateString = DateFormat('EEEE, d MMM').format(DateTime.now());

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
                // ANIMATED HEADER
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            "${_getGreeting()}, $userName".toUpperCase(),
                            style: _orbitron.copyWith(
                                color: Colors.cyanAccent,
                                fontSize: 22,
                                fontWeight: FontWeight.bold
                            )
                        ),
                        const SizedBox(height: 5),
                        Text(
                            "TODAY IS $dateString".toUpperCase(),
                            style: _orbitron.copyWith(
                                color: Colors.white,
                                fontSize: 16,
                                letterSpacing: 1.5
                            )
                        ),
                        const SizedBox(height: 10),
                        Text(
                            "Please set your goals for today",
                            style: _orbitron.copyWith(color: Colors.white70, fontSize: 14)
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // GOAL LIST
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController, // ATTACHED CONTROLLER
                    itemCount: _goals.length,
                    itemBuilder: (context, index) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12)
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.circle_outlined, color: Colors.cyanAccent, size: 16),
                          const SizedBox(width: 15),
                          Expanded(
                              child: Text(
                                  _goals[index],
                                  style: _orbitron.copyWith(color: Colors.white)
                              )
                          ),
                          IconButton(
                              icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                              onPressed: () => setState(() => _goals.removeAt(index))
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // INPUT FIELD
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _goalController,
                        style: _orbitron.copyWith(color: Colors.white),
                        decoration: InputDecoration(
                            hintText: "Type a goal...",
                            hintStyle: _orbitron.copyWith(color: Colors.white24),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none
                            )
                        ),
                        onSubmitted: (_) => _addGoal(), // Uses new method
                      ),
                    ),
                    const SizedBox(width: 10),
                    FloatingActionButton(
                        onPressed: _addGoal, // Uses new method
                        backgroundColor: Colors.cyanAccent,
                        child: const Icon(Icons.add, color: Colors.black)
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // SAVE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _goals.isEmpty
                        ? null
                        : _handleLockIn, // USES NEW LOGIC
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _goals.isEmpty ? Colors.grey[800] : Colors.cyanAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    child: Text(
                        "LOCK IN GOALS",
                        style: _orbitron.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18
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