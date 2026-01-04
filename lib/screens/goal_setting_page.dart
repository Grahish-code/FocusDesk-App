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
  final List<String> _goals = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  TextStyle get _orbitron => GoogleFonts.orbitron(fontStyle: FontStyle.italic);

  @override
  void initState() {
    super.initState();
    // Animation setup: Runs for 2 seconds when page opens
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
    super.dispose();
  }

  String _getGreeting() {
    int hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return "GOOD MORNING";
    if (hour >= 12 && hour < 17) return "GOOD AFTERNOON";
    return "GOOD EVENING";
  }

  @override
  Widget build(BuildContext context) {
    // 1. GET THE NAME FROM PROVIDER
    // We use .watch() so if the name somehow changes, this widget rebuilds.
    String userName = context.watch<AppProvider>().userName;

    // Fallback: If name is empty for some reason, show "Warrior"
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
                        // 2. DISPLAY THE GREETING + NAME HERE
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
                        onSubmitted: (_) {
                          if(_goalController.text.isNotEmpty) {
                            setState(() {
                              _goals.add(_goalController.text);
                              _goalController.clear();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    FloatingActionButton(
                        onPressed: () {
                          if(_goalController.text.isNotEmpty) {
                            setState(() {
                              _goals.add(_goalController.text);
                              _goalController.clear();
                            });
                          }
                        },
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
                        : () => context.read<AppProvider>().saveGoals(_goals),
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