import 'package:focusdesk/components/longTermVision_page_widgets/cyber_save_button.dart';
import 'package:focusdesk/components/longTermVision_page_widgets/holo_input_card.dart';
import 'package:focusdesk/components/longTermVision_page_widgets/tech_tab_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:focusdesk/providers/app_provider.dart';

// ============================================================================
// PAGE WIDGET
// ============================================================================
class LongGoalPage extends StatefulWidget {
  const LongGoalPage({super.key});

  @override
  State<LongGoalPage> createState() => _LongGoalPageState();
}

class _LongGoalPageState extends State<LongGoalPage> with TickerProviderStateMixin {

  // ============================================================================
  // VARIABLES & CONTROLLERS
  // ============================================================================
  final TextEditingController _goal30Controller = TextEditingController();
  final TextEditingController _goal60Controller = TextEditingController();
  final TextEditingController _longTermController = TextEditingController();

  int _selectedIndex = 0;
  late AnimationController _pulseController;

  // ============================================================================
  // LIFECYCLE METHODS
  // ============================================================================
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    final provider = context.read<AppProvider>();
    _goal30Controller.text = provider.goal30;
    _goal60Controller.text = provider.goal60;
    _longTermController.text = provider.goalLongTerm;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _goal30Controller.dispose();
    _goal60Controller.dispose();
    _longTermController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ============================================================================
  // STATE LOGIC
  // ============================================================================
  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Color get _activeColor {
    switch (_selectedIndex) {
      case 0:
        return Colors.cyanAccent;
      case 1:
        return const Color(0xFFD946EF);
      case 2:
        return const Color(0xFF00FF9D);
      default:
        return Colors.cyanAccent;
    }
  }

  // ============================================================================
  // MAIN PAGE BUILDER
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: _activeColor,
          selectionColor: _activeColor.withValues(alpha: 0.3),
          selectionHandleColor: _activeColor,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 2. Main Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black,
                    ],
                  ),
                ),
              ),
            ),

            // 3. Main Content
            SafeArea(
              child: Column(
                children: [
                  // --- TOP HEADER ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(25, 25, 25, 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _activeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _activeColor.withValues(alpha: 0.3)),
                          ),
                          child: Icon(Icons.hub_rounded, color: _activeColor, size: 20),
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "STRATEGY SETUP",
                              style: GoogleFonts.orbitron(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                              ),
                            ),
                            Text(
                              "Define your roadmap",
                              style: GoogleFonts.orbitron(
                                color: Colors.white38,
                                fontSize: 10,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // --- TECH SELECTOR ROW ---
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    child: Row(
                      children: [
                        TechTabButton(
                          index: 0,
                          label: "PHASE 1",
                          subLabel: "30 DAYS",
                          selectedIndex: _selectedIndex,
                          onTap: _selectTab,
                        ),
                        TechTabButton(
                          index: 1,
                          label: "PHASE 2",
                          subLabel: "60 DAYS",
                          selectedIndex: _selectedIndex,
                          onTap: _selectTab,
                        ),
                        TechTabButton(
                          index: 2,
                          label: "VISION",
                          subLabel: " LONG\nTERM",
                          selectedIndex: _selectedIndex,
                          onTap: _selectTab,
                        ),
                      ],
                    ),
                  ),

                  // --- MAIN HOLO CARD ---
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: HoloInputCard(
                        selectedIndex: _selectedIndex,
                        activeColor: _activeColor,
                        pulseController: _pulseController,
                        goal30Controller: _goal30Controller,
                        goal60Controller: _goal60Controller,
                        longTermController: _longTermController,
                      ),
                    ),
                  ),

                  // --- SAVE BUTTON (CYBER SLAB) ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                    child: CyberSaveButton(
                      goal30Controller: _goal30Controller,
                      goal60Controller: _goal60Controller,
                      longTermController: _longTermController,
                      activeColor: _activeColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}