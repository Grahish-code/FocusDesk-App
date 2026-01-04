import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:battery_plus/battery_plus.dart';
import '../providers/app_provider.dart';

class FocusAnimationPage extends StatefulWidget {
  const FocusAnimationPage({super.key});

  @override
  State<FocusAnimationPage> createState() => _FocusAnimationPageState();
}

class _FocusAnimationPageState extends State<FocusAnimationPage> {
  // --- CONFIGURATION ---
  final List<String> _currentImages = [];
  final List<String> _defaultAssets = [
    'assets/bg1.jpg',
    'assets/bg2.jpg',
    'assets/bg3.jpg',
    'assets/bg4.jpg',
    'assets/bg5.jpg',
  ];

  // --- STATE VARIABLES ---
  int _imageIndex = 0;
  Timer? _slideshowTimer;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  // Battery State
  final Battery _battery = Battery();
  int _batteryLevel = 100;

  // Clock State
  Offset _clockPosition = const Offset(100, 100);
  double _clockFontSize = 30.0;
  double _baseScaleFactor = 1.0;
  double _scaleFactor = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePage();
    });
  }

  void _initializePage() {
    final provider = context.read<AppProvider>();

    // 1. CHECK WALLPAPER STATUS FROM PROVIDER
    if (provider.isWallpaperSetupDone && provider.wallpaperPaths.isNotEmpty) {
      setState(() {
        _currentImages.addAll(provider.wallpaperPaths);
      });
      _enterFocusMode();
    } else {
      // First time? Show setup dialog
      _showSetupDialog();
    }

    _getBatteryLevel();
  }

  @override
  void dispose() {
    _slideshowTimer?.cancel();
    _clockTimer?.cancel();
    // Reset to Portrait and Show Status Bar when leaving
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // --- BATTERY LOGIC ---
  Future<void> _getBatteryLevel() async {
    try {
      final level = await _battery.batteryLevel;
      // mounted mean the screen which need to display the battery user is on that screen only than update it
      if (mounted) setState(() => _batteryLevel = level);
    } catch (e) {
      debugPrint("Battery Error: $e");
    }
  }

  void _enterFocusMode() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    // Sticky Immersive: Swipe from edge to see bars, they auto-hide
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _startTimers();
  }

  void _startTimers() {
    // 1. Clock & Battery Timer
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _now = DateTime.now());
        // Update battery every 60 seconds
        if (timer.tick % 60 == 0) _getBatteryLevel();
      }
    });

    // 2. Slideshow Timer (30 Minutes to save battery)
    _slideshowTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      if (mounted && _currentImages.isNotEmpty) {
        setState(() => _imageIndex = (_imageIndex + 1) % _currentImages.length);
      }
    });
  }

  // --- UI BUILDER ---
  @override
  Widget build(BuildContext context) {
    String timeString = DateFormat('HH:mm').format(_now);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. BACKGROUND SLIDESHOW
          if (_currentImages.isNotEmpty)
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Container(
                  key: ValueKey<int>(_imageIndex),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: _getImageProvider(_currentImages[_imageIndex]),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(color: Colors.black.withValues(alpha: 0.3)),
                ),
              ),
            ),

          // 2. DRAGGABLE CLOCK
          if (_currentImages.isNotEmpty)
            Positioned(
              left: _clockPosition.dx,
              top: _clockPosition.dy,
              child: GestureDetector(
                onScaleStart: (details) {
                  _baseScaleFactor = _scaleFactor;
                },
                onScaleUpdate: (details) {
                  setState(() {
                    _clockPosition += details.focalPointDelta;
                    if (details.scale != 1.0) {
                      _scaleFactor = (_baseScaleFactor * details.scale).clamp(0.5, 4.0);
                    }
                  });
                },
                child: Text(
                  timeString,
                  style: GoogleFonts.orbitron(
                    fontSize: _clockFontSize * _scaleFactor,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [const Shadow(blurRadius: 10, color: Colors.black, offset: Offset(2, 2))],
                  ),
                ),
              ),
            ),

          // 3. TOP-RIGHT BUTTON (GOALS)
          Positioned(
            top: 20,
            right: 20,
            child: _buildGlassButton(
              icon: Icons.list_alt,
              onTap: () => _openSideMenu(isRightSide: true),
            ),
          ),

          // 4. BOTTOM-LEFT BUTTON (INFO)
          Positioned(
            bottom: 20,
            left: 20,
            child: _buildGlassButton(
              icon: Icons.info_outline,
              onTap: () {
                _getBatteryLevel();
                _openSideMenu(isRightSide: false);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(icon, color: Colors.white54), // Subtle Grey/White
          ),
        ),
      ),
    );
  }

  void _openSideMenu({required bool isRightSide}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return Align(
          alignment: isRightSide ? Alignment.centerRight : Alignment.centerLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 350,
              height: double.infinity,
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
                color: Colors.black.withValues(alpha: 0.6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    // Load specific content
                    child: isRightSide ? _buildGoalsContent(ctx) : _buildInfoContent(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        final offsetTween = isRightSide
            ? Tween(begin: const Offset(1, 0), end: Offset.zero)
            : Tween(begin: const Offset(-1, 0), end: Offset.zero);
        return SlideTransition(position: anim1.drive(offsetTween), child: child);
      },
    );
  }

  // --- GOALS CONTENT (RIGHT MENU) ---
  Widget _buildGoalsContent(BuildContext ctx) {
    // FIX: Use Consumer so the list rebuilds INSTANTLY when a checkbox is toggled
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final goals = provider.savedGoals;
        final goalStates = provider.goalStates;

        if (goals.isEmpty) {
          return Center(child: Text("No Goals Set", style: GoogleFonts.orbitron(color: Colors.white54)));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("TODAY'S GOALS", style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 22, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white24),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: goals.length,
                itemBuilder: (context, index) {
                  String goal = goals[index];
                  bool isDone = goalStates[goal] ?? false;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: Checkbox(
                        value: isDone,
                        activeColor: Colors.cyanAccent,
                        checkColor: Colors.black,
                        side: const BorderSide(color: Colors.white54),
                        onChanged: (val) {
                          // This saves status AND triggers the Consumer to rebuild UI immediately
                          provider.toggleGoalStatus(goal, val ?? false);
                        },
                      ),
                      title: Text(
                        goal,
                        style: GoogleFonts.orbitron(
                          color: isDone ? Colors.white38 : Colors.white,
                          fontSize: 16,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          decorationColor: Colors.cyanAccent,
                          decorationThickness: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // --- INFO CONTENT (LEFT MENU) ---
  Widget _buildInfoContent() {
    String time = DateFormat('HH:mm').format(DateTime.now());
    String date = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(time, style: GoogleFonts.orbitron(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Text("$_batteryLevel%", style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 18)),
                const SizedBox(width: 5),
                Icon(
                    _batteryLevel > 80 ? Icons.battery_full :
                    _batteryLevel > 50 ? Icons.battery_5_bar :
                    _batteryLevel > 20 ? Icons.battery_3_bar : Icons.battery_alert,
                    color: _batteryLevel < 20 ? Colors.redAccent : Colors.cyanAccent
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(date.toUpperCase(), style: GoogleFonts.orbitron(color: Colors.white54, fontSize: 14, letterSpacing: 1.5)),
        const SizedBox(height: 30),
        Text("NOTIFICATIONS", style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(color: Colors.white24),
        Expanded(
          child: ListView(
            children: [
              _buildNotificationItem("Instagram", "Sanajana liked your story.", "2m ago"),
              _buildNotificationItem("WhatsApp", "Mom: Come for dinner.", "15m ago"),
              _buildNotificationItem("System", "Update downloaded.", "1h ago"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationItem(String app, String msg, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(app, style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(time, style: GoogleFonts.orbitron(color: Colors.white38, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 5),
          Text(msg, style: GoogleFonts.orbitron(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  void _showSetupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text("Focus Mode Setup", style: GoogleFonts.orbitron(color: Colors.cyanAccent)),
        content: const Text("Choose your environment...", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              final paths = _defaultAssets;
              // SAVE SELECTION VIA PROVIDER
              context.read<AppProvider>().saveWallpapers(paths);

              setState(() => _currentImages.addAll(paths));
              Navigator.pop(ctx);
              _enterFocusMode();
            },
            child: const Text("DEFAULTS"),
          ),
          TextButton(
            onPressed: () async {
              final picker = ImagePicker();
              final List<XFile> images = await picker.pickMultiImage(limit: 5);
              if (images.length == 5) {
                final paths = images.map((e) => e.path).toList();
                // SAVE SELECTION VIA PROVIDER
                context.read<AppProvider>().saveWallpapers(paths);

                setState(() => _currentImages.addAll(paths));
                if(mounted) Navigator.pop(ctx);
                _enterFocusMode();
              }
            },
            child: const Text("PICK 5"),
          ),
        ],
      ),
    );
  }

  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    } else {
      return FileImage(File(path));
    }
  }
}