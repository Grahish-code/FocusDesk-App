import 'package:FocusDesk/screens/DisciplineGraph.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math'; // Needed for fake data generation if testing
import '../providers/app_provider.dart';


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String _mostFrequentExcuse = "Distraction by Social Media";

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);


    // _generateSmartTestData(); <--- CALL THIS FOR CHECKING THE UI WITH FAKE DATA
    _loadHistory(); // <--- CALL THIS
    _animController.forward();



  }

  // --- USE THIS FOR REAL APP ---
  Future<void> _loadHistory() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    List<Map<String, dynamic>> data = await provider.getHistory();
    data.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

    if (mounted) {
      setState(() {
        _history = data;
        _isLoading = false;
      });
    }
  }

  // --- USE THIS FOR TESTING GRAPH UI ---
  void _generateSmartTestData() {
    List<Map<String, dynamic>> fakeData = [];
    final now = DateTime.now();
    final random = Random();

    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: 29 - i));
      String dateStr = DateFormat('yyyy-MM-dd').format(date);

      int totalCount = 3 + random.nextInt(5);
      // Generate varied completion rates (0.0 to 1.0)
      int completedCount = random.nextInt(totalCount + 1);

      fakeData.add({
        "date": dateStr,
        "status": completedCount == totalCount ? "Completed" : "Incomplete",
        "total_goals": List.filled(totalCount, "Goal"),
        "completed_goals": List.filled(completedCount, "Done"),
        "reason": "Test"
      });
    }

    setState(() {
      _history = fakeData;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final todayStr = DateFormat('EEEE, d MMM').format(DateTime.now()).toUpperCase();

    int totalDays = _history.isEmpty ? 1 : _history.length;
    int successfulDays = _history.where((e) => e['status'] == 'Completed').length;
    bool isHighPerformance = successfulDays >= (totalDays * 0.7);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
              : FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Column(
                children: [
                  // --- 1. HEADER ---
                  _buildHeader(provider.userName, todayStr),

                  const SizedBox(height: 30),

                  // --- 2. THE NEW GRAPH WIDGET ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("DISCIPLINE WAVE (30 DAYS)",
                          style: GoogleFonts.orbitron(color: Colors.white38, fontSize: 10, letterSpacing: 2)
                      ),
                      Icon(Icons.swipe_left, color: Colors.white24, size: 16), // Hint to scroll
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Injecting the isolated widget here
                  DisciplineGraphWidget(history: _history),

                  const SizedBox(height: 20),

                  // --- 3. PERFORMANCE STATS ---
                  Expanded(
                    child: Row(
                      children: [
                        // CIRCLE SCORE
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: isHighPerformance ? Colors.cyanAccent : Colors.redAccent,
                                  width: 3
                              ),
                              boxShadow: [
                                BoxShadow(
                                    color: (isHighPerformance ? Colors.cyanAccent : Colors.redAccent).withOpacity(0.2),
                                    blurRadius: 20,
                                    spreadRadius: 2
                                )
                              ]
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "$successfulDays/$totalDays",
                                  style: GoogleFonts.orbitron(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Text("SCORE", style: GoogleFonts.orbitron(color: Colors.white54, fontSize: 8)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // MESSAGE
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isHighPerformance ? "SYSTEM OPTIMAL" : "ANALYSIS REQUIRED",
                                style: GoogleFonts.orbitron(
                                    color: isHighPerformance ? Colors.cyanAccent : Colors.redAccent,
                                    fontSize: 12, fontWeight: FontWeight.bold
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                isHighPerformance
                                    ? "Momentum verified. Keep pushing."
                                    : "Frequent issue: \"$_mostFrequentExcuse\".",
                                style: GoogleFonts.orbitron(color: Colors.white70, fontSize: 12, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- 4. AI BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent.withOpacity(0.1),
                        foregroundColor: Colors.cyanAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.cyanAccent, width: 1),
                        ),
                      ),
                      child: Text("INITIATE AI ASSISTANT", style: GoogleFonts.orbitron(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name, String date) {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.white10,
          backgroundImage: const NetworkImage("https://i.pravatar.cc/150?img=11"),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name.toUpperCase(), style: GoogleFonts.orbitron(color: Colors.white, fontSize: 18, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)),
            Text(date, style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 12, letterSpacing: 1.5)),
          ],
        )
      ],
    );
  }
}