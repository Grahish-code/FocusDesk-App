import 'package:focusdesk/components/Dashboard_page_widgets/avatar_picker_sheet.dart';
import 'package:focusdesk/components/Dashboard_page_widgets/dashboard_header.dart';
import 'package:focusdesk/components/Dashboard_page_widgets/dashboard_widgets.dart';
import 'package:focusdesk/screens/disciplineGraph.dart';
import 'package:focusdesk/screens/longTermVision_page.dart';
import 'package:focusdesk/screens/animation_page.dart';
import 'package:focusdesk/screens/nightRest_page.dart';
import 'package:focusdesk/screens/permission_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:focusdesk/screens/report_page.dart';
import '../providers/app_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _animController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _loadHistory();
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final data = await provider.getHistory();
    if (mounted) {
      setState(() {
        _history = data;
        _isLoading = false;
      });
    }
  }

  void _handleBackNavigation() {
    final int hour = DateTime.now().hour;
    if (hour >= 0 && hour < 6) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NightRestPage()),
      );
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FocusAnimationPage()),
      );
    }
  }

  // --- Filter history to current calendar month only ---
  List<Map<String, dynamic>> get _currentMonthHistory {
    final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    return _history
        .where((e) => (e['date'] as String).startsWith(currentMonth))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final todayStr =
    DateFormat('EEEE, d MMM').format(DateTime.now()).toUpperCase();

    // Score is now month-scoped — resets automatically on 1st of each month
    final List<Map<String, dynamic>> monthHistory = _currentMonthHistory;
    final int totalDays = monthHistory.isEmpty ? 1 : monthHistory.length;
    final int successfulDays =
        monthHistory.where((e) => e['status'] == 'Completed').length;

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
            child:
            CircularProgressIndicator(color: Colors.cyanAccent),
          )
              : FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16,
              ),
              child: Column(
                children: [
                  // Header
                  DashboardHeader(
                    name: provider.userName,
                    date: todayStr,
                    avatarUrl: provider.avatarUrl,
                    onAvatarTap: () => AvatarPickerSheet.show(context),
                    onBackTap: _handleBackNavigation,
                  ),
                  const SizedBox(height: 30),

                  // Graph label
                  // Discipline graph
                  DisciplineGraphWidget(history: _history),
                  const SizedBox(height: 20),

                  // Stats — now monthly score
                  DashboardStats(
                    successfulDays: successfulDays,
                    totalDays: totalDays,
                    currentStreak: provider.currentStreak,
                  ),

                  const Spacer(),

                  // Action buttons
                  DashboardActions(
                    onStrategyTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LongGoalPage(),
                        ),
                      ).then((_) => _loadHistory());
                    },
                      onAutoWakeTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PermissionPage(),
                          ),
                        );
                      },
                    onAiAssistantTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReportScreen(),
                        ),
                      );
                    },
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}