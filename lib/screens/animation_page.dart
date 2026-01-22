import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:FocusDesk/screens/night_rest_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:battery_plus/battery_plus.dart';

// Import your project files
import 'package:FocusDesk/screens/dashboard_page.dart';
import 'package:FocusDesk/screens/notification_pannel.dart';
import '../providers/app_provider.dart';

class FocusAnimationPage extends StatefulWidget {
  const FocusAnimationPage({super.key});

  @override
  State<FocusAnimationPage> createState() => _FocusAnimationPageState();
}

class _FocusAnimationPageState extends State<FocusAnimationPage> with WidgetsBindingObserver {
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

  // Clock State
  Offset _clockPosition = const Offset(100, 100);
  double _clockFontSize = 30.0;
  double _baseScaleFactor = 1.0;
  double _scaleFactor = 1.0;

  @override
  void initState() {
    super.initState();

    // 1. FORCE LANDSCAPE IMMEDIATELY ON INIT
    _forceLandscapeMode();

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePage();
      // We attach a listener so this page reacts INSTANTLY when Provider changes
      context.read<AppProvider>().addListener(_checkAppState);
    });

  }

  // 2. SEPARATED LOGIC: Purely for forcing UI mode
  void _forceLandscapeMode() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _initializePage() {
    final provider = context.read<AppProvider>();

    provider.startListeningToNotifications();

    // 1. CHECK WALLPAPER STATUS
    if (provider.isWallpaperSetupDone && provider.wallpaperPaths.isNotEmpty) {
      setState(() {
        _currentImages.addAll(provider.wallpaperPaths);
      });
      _startTimers();
      _enterFocusMode();
    } else {
      _showSetupDialog();
    }
  }

  // --- NEW HELPER: Just handles orientation ---


  @override
  void dispose() {
    // 3. ADD THESE TWO LINES
    WidgetsBinding.instance.removeObserver(this);
    context.read<AppProvider>().removeListener(_checkAppState);

    _slideshowTimer?.cancel();
    _clockTimer?.cancel();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _forceLandscapeOnly() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }


  void _enterFocusMode() {
    _forceLandscapeOnly();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _startTimers();
  }

  void _startTimers() {
    // 1. Clock Timer
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });

    // 2. Slideshow Timer (30 Minutes)
    _slideshowTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      if (mounted && _currentImages.isNotEmpty) {
        setState(() => _imageIndex = (_imageIndex + 1) % _currentImages.length);
      }
    });
  }



  // --- ADD THIS NEW FUNCTION ---


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _forceLandscapeMode();
      _checkAppState(); // Check immediately when app wakes up
    }
  }

  void _checkAppState() {
    // 1. Safety check: Is the page still open?
    if (!mounted) return;

    final provider = context.read<AppProvider>();

    // 2. The Logic: If Provider says it's Night Time, LEAVE IMMEDIATELY.
    if (provider.currentState == AppState.nightRest) {

      // Stop listening so we don't trigger this twice
      provider.removeListener(_checkAppState);
      WidgetsBinding.instance.removeObserver(this);

      // Go to Night Rest Page
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NightRestPage())
      );
    }
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
            child: Consumer<AppProvider>(
              builder: (context, provider, child) {
                return _buildGlassButton(
                  icon: Icons.info_outline,
                  isGlowing: provider.hasNewNotifications,
                  onTap: () {
                    provider.markNotificationsAsRead();
                    _openSideMenu(isRightSide: false);
                  },
                );
              },
            ),
          ),

          // 5. DASHBOARD BUTTON
          Positioned(
            bottom: 20,
            right: 20,
            child: _buildGlassButton(
              icon: Icons.insights,
              onTap: () async {
                await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                if (!context.mounted) return;
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DashboardPage()),
                );
                _enterFocusMode();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isGlowing = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: isGlowing
              ? [
            BoxShadow(
              color: Colors.cyanAccent.withValues(alpha: 0.6),
              blurRadius: 15,
              spreadRadius: 2,
            )
          ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isGlowing
                    ? Colors.cyanAccent.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.1),
                border: Border.all(
                    color: isGlowing
                        ? Colors.cyanAccent.withValues(alpha: 0.8)
                        : Colors.white24),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                icon,
                color: isGlowing ? Colors.cyanAccent : Colors.white54,
              ),
            ),
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

  // --- GOALS CONTENT ---
  Widget _buildGoalsContent(BuildContext ctx) {
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

  // --- INFO CONTENT (Uses LiveBatteryWidget) ---
  Widget _buildInfoContent() {
    String time = DateFormat('HH:mm').format(DateTime.now());
    String date = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. TIME & BATTERY
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(time, style: GoogleFonts.orbitron(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
            // !!! HERE IS THE FIX: Using the separate widget !!!
            const LiveBatteryWidget(),
          ],
        ),
        const SizedBox(height: 5),
        Text(date.toUpperCase(), style: GoogleFonts.orbitron(color: Colors.white54, fontSize: 14, letterSpacing: 1.5)),
        const SizedBox(height: 30),

        // 2. HEADER WITH PERMISSION BUTTON
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("NOTIFICATIONS", style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              tooltip: "Grant Permission",
              icon: const Icon(Icons.security, color: Colors.white54, size: 20),
              onPressed: () {
                _showPrivacyDialog();
              },
            )
          ],
        ),
        const Divider(color: Colors.white24),

        // 3. THE LIST
        const Expanded(
          child: NotificationPanel(),
        ),
      ],
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.white10)
        ),
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: Colors.cyanAccent),
            const SizedBox(width: 10),
            Text("PRIVACY & CONTROL", style: GoogleFonts.orbitron(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "To maintain your focus, FocusDesk needs permission to filter incoming interruptions.",
              style: GoogleFonts.roboto(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_outline, color: Colors.cyanAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Your Data Stays Here.\nWe process notifications locally on this device. We never store, read, or transmit your personal messages or OTPs to any server.",
                      style: GoogleFonts.roboto(color: Colors.cyanAccent, fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Text(
              "Please enable 'FocusDesk' in the next screen.",
              style: GoogleFonts.roboto(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("CANCEL", style: GoogleFonts.orbitron(color: Colors.white54)),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.cyanAccent.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AppProvider>().openNotificationSettings();
            },
            child: Text("PROCEED TO SETTINGS", style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
          ),
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
        content: const Text("Choose your Wallpaper", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              final paths = _defaultAssets;
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
                context.read<AppProvider>().saveWallpapers(paths);
                setState(() => _currentImages.addAll(paths));
                if (mounted) Navigator.pop(ctx);
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

// ---------------------------------------------------------
// NEW CLASS: Handles live battery updates inside the Dialog
// ---------------------------------------------------------
class LiveBatteryWidget extends StatefulWidget {
  const LiveBatteryWidget({super.key});

  @override
  State<LiveBatteryWidget> createState() => _LiveBatteryWidgetState();
}

class _LiveBatteryWidgetState extends State<LiveBatteryWidget> {
  final Battery _battery = Battery();
  int _batteryLevel = 100;
  BatteryState _batteryState = BatteryState.full;
  StreamSubscription<BatteryState>? _batteryStateSubscription;
  Timer? _levelTimer;

  @override
  void initState() {
    super.initState();
    _initBattery();
  }

  void _initBattery() {
    // 1. Listen to State Changes (Charging/Discharging)
    _batteryStateSubscription = _battery.onBatteryStateChanged.listen((state) {
      if (mounted) {
        setState(() => _batteryState = state);
        // Refresh level immediately when state changes
        _getBatteryLevel();
      }
    });

    // 2. Get Initial Level
    _getBatteryLevel();

    // 3. Poll Level every 10 seconds to keep percentage accurate
    _levelTimer = Timer.periodic(const Duration(seconds: 10), (_) => _getBatteryLevel());
  }

  Future<void> _getBatteryLevel() async {
    try {
      final level = await _battery.batteryLevel;
      if (mounted) setState(() => _batteryLevel = level);
    } catch (e) {
      debugPrint("Battery Error: $e");
    }
  }

  @override
  void dispose() {
    _batteryStateSubscription?.cancel();
    _levelTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
            "$_batteryLevel%",
            style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 18)
        ),
        const SizedBox(width: 5),
        Icon(
          // Icon Logic
          _batteryState == BatteryState.charging
              ? Icons.battery_charging_full
              : _batteryLevel > 80 ? Icons.battery_full
              : _batteryLevel > 50 ? Icons.battery_5_bar
              : _batteryLevel > 20 ? Icons.battery_3_bar
              : Icons.battery_alert,
          // Color Logic
          color: (_batteryLevel < 20 && _batteryState != BatteryState.charging)
              ? Colors.redAccent
              : Colors.cyanAccent,
        ),
      ],
    );
  }
}