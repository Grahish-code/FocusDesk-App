import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import 'package:focusdesk/screens/dashboard_page.dart';

class NightRestPage extends StatefulWidget {
  const NightRestPage({super.key});

  @override
  State<NightRestPage> createState() => _NightRestPageState();
}

class _NightRestPageState extends State<NightRestPage> {

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  // --- NEW LOGIC: Calculate yesterday's exact success rate ---
  Future<bool> _checkYesterdaysVictory() async {
    final yesterdayKey = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));
    final storage = StorageService();

    final yesterdayGoals = await storage.getTodayGoals(yesterdayKey);

    // If they had no goals yesterday, they didn't technically "win"
    if (yesterdayGoals.isEmpty) return false;

    final yesterdayStates = await storage.getGoalStatuses(yesterdayKey);

    // Check if every single goal from yesterday was marked true
    return yesterdayGoals.every((g) => yesterdayStates[g] == true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF101010), Color(0xFF000000)]
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            // --- NEW LOGIC: FutureBuilder waits for the DB check ---
            child: FutureBuilder<bool>(
                future: _checkYesterdaysVictory(),
                builder: (context, snapshot) {

                  // Show a subtle loader while it checks the database (usually takes 1ms)
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.cyanAccent),
                    );
                  }

                  final didWinYesterday = snapshot.data ?? false;

                  String message = didWinYesterday
                      ? "You have worked good today.\nKeep your body at rest."
                      : "We did not win today's battle,\nbut fresh day, fresh start.\n\nTill then take rest and prepare for tomorrow.";

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      const Icon(Icons.nights_stay, color: Colors.cyanAccent, size: 50),
                      const SizedBox(height: 40),
                      Text(
                          message,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              height: 1.5
                          )
                      ),
                      const SizedBox(height: 30),
                      Text(
                          "\nTime to rest.\nWe will set our goal tomorrow morning.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.orbitron(
                              color: Colors.grey,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              height: 1.5
                          )
                      ),
                      const Spacer(),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const DashboardPage())
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.cyanAccent, width: 1),
                            backgroundColor: Colors.cyanAccent.withValues(alpha: 0.05),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.insights, color: Colors.cyanAccent),
                              const SizedBox(width: 10),
                              Text(
                                  "ACCESS DASHBOARD",
                                  style: GoogleFonts.orbitron(
                                      color: Colors.cyanAccent,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5
                                  )
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                }
            ),
          ),
        ),
      ),
    );
  }
}