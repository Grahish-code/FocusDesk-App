import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// Import your files
import 'providers/app_provider.dart';
import 'screens/name_input_page.dart';
import 'screens/goal_setting_page.dart';
import 'screens/night_rest_page.dart';
import 'screens/animation_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
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
      ),
      home: const ScreenRouter(),
    );
  }
}

class ScreenRouter extends StatelessWidget {
  const ScreenRouter({super.key});

  @override
  Widget build(BuildContext context) {
    // This widget listens to AppProvider and switches screens automatically
    final appState = context.watch<AppProvider>().currentState;

    switch (appState) {
      case AppState.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)));
      case AppState.nameInput:
        return const NameInputPage();
      case AppState.goalSetting:
        return const GoalSettingPage();
      case AppState.nightRest:
        return const NightRestPage();
      case AppState.dashboard:
        return const FocusAnimationPage();
      default:
        return const Scaffold(body: Center(child: Text("Error: Unknown State")));
    }
  }
}