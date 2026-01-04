import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_provider.dart';

class NameInputPage extends StatefulWidget {
  const NameInputPage({super.key});
  //In one sentence: You are creating a screen named NameInputPage, giving it a unique ID badge so the system can track it, and marking it as "permanent" so the phone runs faster.
  @override
  State<NameInputPage> createState() => _NameInputPageState();
}

class _NameInputPageState extends State<NameInputPage> {
  final TextEditingController _nameController = TextEditingController();

  TextStyle get _appFont => GoogleFonts.orbitron(
    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, letterSpacing: 1.5),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF252525), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
            child: Column(
              children: [
                Text("FOCUS DESK", style: GoogleFonts.orbitron(fontSize: 28, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 3.0, color: Colors.white)),
                const Spacer(),
                Text("Please Enter \n Your Name", textAlign: TextAlign.center, style: _appFont.copyWith(fontSize: 26, color: Colors.cyanAccent, height: 1.5)),
                const SizedBox(height: 50),
                TextField(
                  controller: _nameController,
                  style: _appFont.copyWith(color: Colors.white),
                  cursorColor: Colors.cyanAccent,
                  decoration: InputDecoration(
                    labelText: "ENTER YOUR NAME",
                    labelStyle: _appFont.copyWith(color: Colors.grey, fontSize: 14),
                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.cyanAccent, width: 2), borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_nameController.text.isNotEmpty) {
                        // Use Provider to save
                        context.read<AppProvider>().saveName(_nameController.text);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text("GET STARTED", style: GoogleFonts.orbitron(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}