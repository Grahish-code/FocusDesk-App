import 'package:focusdesk/screens/longTermVision_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_provider.dart';

class NameInputPage extends StatefulWidget {
  const NameInputPage({super.key});

  @override
  State<NameInputPage> createState() => _NameInputPageState();
}

class _NameInputPageState extends State<NameInputPage> {

  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  TextStyle get _appFont => GoogleFonts.orbitron(
    textStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
        letterSpacing: 1.5),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        //Automatically capitalize the first word enter in this widget
        textCapitalization : TextCapitalization.sentences,
        style: _appFont.copyWith(color: Colors.white, fontSize: 14),
        cursorColor: Colors.cyanAccent,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: _appFont.copyWith(color: Colors.grey, fontSize: 12),
          prefixIcon: Icon(icon, color: Colors.cyanAccent.withOpacity(0.7), size: 20),
          enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white24),
              borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.5),
              borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF252525), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),
                  Text("FOCUS DESK",
                      style: GoogleFonts.orbitron(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 3.0,
                          color: Colors.white)),
                  const SizedBox(height: 140),

                  Text(
                    "ENTER YOUR NAME ",
                    style: _appFont.copyWith(
                        fontSize: 22, color: Colors.cyanAccent),
                  ),
                  const SizedBox(height: 30),

                  _buildTextField(
                    controller: _nameController,
                    label: "USER NAME",
                    icon: Icons.person_outline,
                  ),

                  const SizedBox(height: 20),

                  // Main Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                "Please enter a name to proceed.",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: Colors.redAccent,
                              behavior: SnackBarBehavior.floating, // Makes it float instead of sticking to the bottom
                              elevation: 10.0, // Gives it the shadow
                              margin: const EdgeInsets.all(20.0), // Adds space around the floating box
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0), // Rounds the edges
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          return;
                        }

                        // Save Data to Provider
                        context.read<AppProvider>().saveName(_nameController.text.trim());
                        //After saving the data to the provider provider itself take the page to
                        // next screen no need of manual navigation
                        // Navigate to the next screen
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center, // Centers both items in the button
                          children: [
                            Text(
                              "PROCEED TO NEXT",
                              style: GoogleFonts.orbitron(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(width: 12), // Adds a clean, exact gap between text and icon
                            const Icon(
                              Icons.arrow_forward_rounded, // Sleeker arrow than play_arrow
                              color: Colors.black,
                              size: 22, // Sized to match the font perfectly
                            ),
                          ],
                        ),
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
}