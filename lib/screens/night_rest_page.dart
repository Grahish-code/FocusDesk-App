import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_provider.dart';

class NightRestPage extends StatelessWidget {
  const NightRestPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Read directly from Provider
    final completed = context.read<AppProvider>().goalsCompleted;

    String message = completed
        ? "You have worked good today.\nKeep your body at rest."
        : "We did not win today's battle,\nbut fresh day, fresh start.\n\nTill then take rest and prepare for tomorrow.";

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF101010), Color(0xFF000000)]),
        ),
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.nights_stay, color: Colors.cyanAccent, size: 50),
              const SizedBox(height: 40),
              Text(message, textAlign: TextAlign.center, style: GoogleFonts.orbitron(color: Colors.white, fontSize: 18, fontStyle: FontStyle.italic, height: 1.5)),
              const SizedBox(height: 30),
              Text("\nTime to rest.\nWe will set our goal tomorrow morning.", textAlign: TextAlign.center, style: GoogleFonts.orbitron(color: Colors.grey, fontSize: 14, fontStyle: FontStyle.italic, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}