import 'package:FocusDesk/screens/DisciplineGraph.dart';
import 'package:FocusDesk/screens/animation_page.dart';
import 'package:FocusDesk/screens/night_rest_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // Required for SystemChrome
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

    // FORCE PORTRAIT MODE
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _animController =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _fadeAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _loadHistory();
    _animController.forward();
  }

  @override
  void dispose() {
    // --- RELEASE THE LOCK ---
    // // This allows other pages to be landscape if they want
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.landscapeRight,
    //   DeviceOrientation.landscapeLeft,
    //   DeviceOrientation.portraitUp,
    //   DeviceOrientation.portraitDown,
    // ]);

    // Don't forget to dispose your animation controller too!
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    List<Map<String, dynamic>> data = await provider.getHistory();
    if (mounted) {
      setState(() {
        _history = data;
        _isLoading = false;
      });
    }
  }

  // --- NEW: SERVER-BASED PICKER ---
  void _showAvatarPicker() {
    final List<String> realHumans = [
      "https://api.dicebear.com/9.x/lorelei/png?seed=Leo",
      "https://api.dicebear.com/9.x/lorelei/png?seed=Mia",
      "https://api.dicebear.com/9.x/lorelei/png?seed=Max",
      "https://api.dicebear.com/9.x/lorelei/png?seed=Zoe",
      "https://api.dicebear.com/9.x/lorelei/png?seed=Kai",
      "https://api.dicebear.com/9.x/lorelei/png?seed=Ava",
      "https://api.dicebear.com/9.x/lorelei/png?seed=Sasha",
      "https://api.dicebear.com/9.x/lorelei/png?seed=Bella",
      "https://api.dicebear.com/9.x/lorelei/png?seed=Luna",
      "https://api.dicebear.com/9.x/lorelei/png?seed=Zara",
      "https://api.dicebear.com/9.x/lorelei/png?seed=Mila",
      "https://api.dicebear.com/9.x/lorelei/png?seed=Coco",
      "https://api.dicebear.com/9.x/lorelei/png?seed=Annie",
      "https://api.dicebear.com/9.x/lorelei/png?seed=Maya",
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Important for the floating look
      isScrollControlled: true,
      builder: (context) {
        // Local state for the sheet so we can update the preview instantly
        String tempSelectedUrl = Provider.of<AppProvider>(context, listen: false).avatarUrl;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Container(
              height: 500, // Taller, more premium feel
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F0F).withOpacity(0.95),
                // Deep dark glass
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30)),
                border: Border(
                  top: BorderSide(
                      color: Colors.cyanAccent.withOpacity(0.3), width: 1),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.cyanAccent.withOpacity(0.1),
                      blurRadius: 40,
                      spreadRadius: 0)
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              child: Column(
                children: [
                  // --- 1. TITLE ---
                  Text(
                    "IDENTITY SYNCHRONIZATION",
                    style: GoogleFonts.orbitron(
                        color: Colors.cyanAccent,
                        fontSize: 12,
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold
                    ),
                  ),

                  const Spacer(),

                  // --- 2. THE HOLO-PREVIEW (Big Central Avatar) ---
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glowing rings
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.cyanAccent.withOpacity(0.2),
                                width: 1),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.cyanAccent.withOpacity(0.15),
                                  blurRadius: 30,
                                  spreadRadius: 10)
                            ]
                        ),
                      ),
                      //inner glowing circle
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.cyanAccent.withOpacity(0.5),
                              width: 2),
                        ),
                      ),
                      // The Image
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.black12,
                        backgroundImage: NetworkImage(tempSelectedUrl),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Text(
                      "SELECTED PROFILE",
                      style: GoogleFonts.orbitron(
                          color: Colors.white38, fontSize: 10, letterSpacing: 2)
                  ),

                  const Spacer(),

                  // --- 3. THE SELECTION STRIP (Horizontal Carousel) ---
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: realHumans.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final url = realHumans[index];
                        final isSelected = tempSelectedUrl == url;

                        return GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              tempSelectedUrl = url;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                  color: Colors.cyanAccent, width: 2)
                                  : Border.all(color: Colors.white12, width: 1),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                    color: Colors.cyanAccent.withOpacity(0.4),
                                    blurRadius: 10)
                              ]
                                  : [],
                            ),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white10,
                              backgroundImage: NetworkImage(url),
                              // Dim the unselected ones
                              child: isSelected ? null : Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- 4. CONFIRM BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      // Inside the ElevatedButton onPressed in _showAvatarPicker
                      onPressed: () {
                        // CALL THE PROVIDER TO SAVE PERMANENTLY
                        Provider.of<AppProvider>(context, listen: false).updateAvatar(tempSelectedUrl);

                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius
                            .circular(15)),
                        elevation: 10,
                        shadowColor: Colors.cyanAccent.withOpacity(0.4),
                      ),
                      child: Text(
                          "INITIALIZE",
                          style: GoogleFonts.orbitron(fontWeight: FontWeight
                              .bold, letterSpacing: 2)
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- DYNAMIC BACK NAVIGATION ---
  void _handleBackNavigation() {
    final int hour = DateTime.now().hour;

    // Logic: If it is between 12 AM (0) and 6 AM (6), go to NightRestPage.
    // Otherwise (Morning/Day/Evening), go to AnimationPage.
    if (hour >= 0 && hour < 6) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      // Replace this with your actual NightRestPage import
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const NightRestPage()));
      print("Navigating to NightRestPage (Night Mode)");
    } else {
      // Replace this with your actual AnimationPage import
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const FocusAnimationPage()));
      print("Navigating to AnimationPage (Day Mode)");
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final todayStr = DateFormat('EEEE, d MMM')
        .format(DateTime.now())
        .toUpperCase();

    // ... (Your Stats Logic) ...
    int totalDays = _history.isEmpty ? 1 : _history.length;
    int successfulDays = _history
        .where((e) => e['status'] == 'Completed')
        .length;
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
              ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent))
              : FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24.0, vertical: 16),
              child: Column(
                children: [
                  // --- HEADER WITH REAL PROFILE PIC ---
                  _buildHeader(provider.userName, todayStr, provider.avatarUrl),

                  const SizedBox(height: 30),

                  // ... (Rest of your UI remains exactly the same) ...
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("DISCIPLINE WAVE (30 DAYS)",
                          style: GoogleFonts.orbitron(color: Colors.white,
                              fontSize: 10,
                              letterSpacing: 2)
                      ),
                      const Icon(
                          Icons.swipe_left, color: Colors.white24, size: 16),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DisciplineGraphWidget(history: _history),
                  const SizedBox(height: 20),
                  // You can uncomment this now, it will look normal

// --- PERFORMANCE STATS (Removed Expanded) ---
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    // Optional small padding
                    child: Row(
                      children: [
                        // CIRCLE SCORE
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: isHighPerformance
                                      ? Colors.cyanAccent
                                      : Colors.redAccent,
                                  width: 3
                              ),
                              boxShadow: [
                                BoxShadow(
                                    color: (isHighPerformance ? Colors
                                        .cyanAccent : Colors.redAccent)
                                        .withOpacity(0.2),
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
                                  style: GoogleFonts.orbitron(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text("SCORE", style: GoogleFonts.orbitron(
                                    color: Colors.white54, fontSize: 8)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),

                        // MESSAGE
                        Expanded( // This inner Expanded is fine (it handles horizontal text width)
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isHighPerformance
                                    ? "SYSTEM OPTIMAL"
                                    : "ANALYSIS REQUIRED",
                                style: GoogleFonts.orbitron(
                                    color: isHighPerformance
                                        ? Colors.cyanAccent
                                        : Colors.redAccent,
                                    fontSize: 12, fontWeight: FontWeight.bold
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                isHighPerformance
                                    ? "Momentum verified. Keep pushing."
                                    : "Frequent issue: \"$_mostFrequentExcuse\".",
                                style: GoogleFonts.orbitron(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

// --- IMPORTANT: ADD SPACER HERE ---
// This pushes everything above it UP and the button below it DOWN
                  const Spacer(),

                  // --- AI BUTTON ---
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
                          side: const BorderSide(
                              color: Colors.cyanAccent, width: 1),
                        ),
                      ),
                      child: Text("INITIATE AI ASSISTANT",
                          style: GoogleFonts.orbitron(fontWeight: FontWeight
                              .bold)),
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

  // --- UPDATED HEADER ---
  Widget _buildHeader(String name, String date,String avatarUrl) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Push items to edges
      children: [
        // --- LEFT SIDE: AVATAR & NAME ---
        Row(
          children: [
            GestureDetector(
              onTap: _showAvatarPicker,
              child: Container(
                width: 50, // Slightly smaller to look cleaner
                height: 50,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.cyanAccent.withOpacity(0.5), width: 2),
                    image: DecorationImage(
                      image: NetworkImage(avatarUrl),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ]
                ),
              ),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    name.toUpperCase(),
                    style: GoogleFonts.orbitron(color: Colors.white,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold)
                ),
                Text(
                    date,
                    style: GoogleFonts.orbitron(color: Colors.cyanAccent,
                        fontSize: 10,
                        letterSpacing: 1.5)
                ),
              ],
            )
          ],
        ),

        // --- RIGHT SIDE: GAMING BACK BUTTON ---
        // --- RIGHT SIDE: GAMING BACK BUTTON ---
        GestureDetector(
          onTap: () {
            print("Back Button Tapped!"); // Check your console for this
            _handleBackNavigation();
          },
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05), // Dark Glass effect
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24, width: 1),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(2, 2)
                  )
                ]
            ),
            // Center the icon so it looks perfect
            child: const Center(
              child: Icon(
                  Icons.keyboard_return,
                  color: Colors.cyanAccent,
                  size: 20
              ),
            ),
          ),
        ),
      ],
    );
  }
}