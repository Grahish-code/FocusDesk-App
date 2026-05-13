library;
import 'dart:async';
import 'dart:ui';

import 'package:focusdesk/screens/longTermVision_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';


// --- MODELS & PROVIDERS ---
import 'package:focusdesk/models/app_state.dart';
import 'package:focusdesk/providers/app_provider.dart';
import 'package:focusdesk/providers/quests_provider.dart';
import 'package:focusdesk/providers/notification_provider.dart';

// --- SCREEN IMPORTS ---
import 'package:focusdesk/screens/nameInput_page.dart';
import 'package:focusdesk/screens/dailyGoalSet_page.dart';
import 'package:focusdesk/screens/nightRest_page.dart';
import 'package:focusdesk/screens/animation_page.dart';
import 'package:focusdesk/screens/failureReason_page.dart';

// ✅ Required by flutter_overlay_window.
// Without this the package throws "Could not resolve main entrypoint"
// on every launch because it tries to boot its own Flutter engine
// and looks for this function by name. Must be at top level.
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: SizedBox.shrink(),
      ),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Global Flutter error handler — prevents blank screens on
  // unhandled framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  // ✅ Global async/platform error handler — returns true so the
  // error is marked as handled and the app doesn't crash
  PlatformDispatcher.instance.onError = (error, stack) {
    return true;
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => QuestsProvider()..loadSideQuests()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Focus Desk',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.robotoTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: const ScreenRouter(),
    );
  }
}

// ─── SCREEN ROUTER ────────────────────────────────────────────────────────────
class ScreenRouter extends StatefulWidget {
  const ScreenRouter({super.key});

  @override
  State<ScreenRouter> createState() => _ScreenRouterState();
}

class _ScreenRouterState extends State<ScreenRouter> {
  int _retryCount = 0;
  static const _maxAutoRetries = 3;
  bool _hardFailed = false;
  Timer? _watchdog;

  @override
  void initState() {
    super.initState();
    _startWatchdog();
  }

  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer(const Duration(seconds: 8), () {
      if (!mounted) return;
      final state = context.read<AppProvider>().currentState;

      // Already moved past loading — do nothing
      if (state != AppState.loading) return;

      if (_retryCount < _maxAutoRetries) {
        _retryCount++;
        context.read<AppProvider>().retryInit();
        _startWatchdog();
      } else {
        // All auto retries exhausted — show manual button
        setState(() => _hardFailed = true);
      }
    });
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppProvider>().currentState;

    // Cancel watchdog the moment we leave loading
    if (appState != AppState.loading) {
      _watchdog?.cancel();
    }

    // Hard fail — shown only after 3 silent auto-retries (~24 seconds total)
    if (_hardFailed) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, color: Colors.white54, size: 48),
              const SizedBox(height: 16),
              const Text(
                "Taking longer than usual...",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                "Check your connection and try again",
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hardFailed = false;
                    _retryCount = 0;
                  });
                  context.read<AppProvider>().retryInit();
                  _startWatchdog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                ),
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    switch (appState) {
      case AppState.loading:
        return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: CircularProgressIndicator(color: Colors.cyanAccent),
          ),
        );
      case AppState.nameInput:
        return const NameInputPage();
      case AppState.goalSetting:
        return const GoalSettingPage();
      case AppState.longTermGoalSetting:
        return const LongGoalPage();
      case AppState.nightRest:
        return const NightRestPage();
      case AppState.dashboard:
        return const FocusAnimationPage();
      case AppState.failureReason:
        return const FailureReasonPage();
      default:
        return const Scaffold(
          body: Center(child: Text("Error: Unknown State")),
        );
    }
  }
}