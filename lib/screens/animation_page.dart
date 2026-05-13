import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:focusdesk/providers/quests_provider.dart';
import 'package:focusdesk/components/animation_page_widgets/glass_button.dart';
import 'package:focusdesk/components/animation_page_widgets/goals_and_side_quests_panel.dart';
import 'package:focusdesk/components/animation_page_widgets/info_panel.dart';
import 'package:focusdesk/components/animation_page_widgets/wallpaper_setup_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:focusdesk/screens/dashboard_page.dart';
import 'package:focusdesk/screens/nightRest_page.dart';
import '../models/app_state.dart';
import '../providers/app_provider.dart';
import '../providers/notification_provider.dart';


class FocusAnimationPage extends StatefulWidget {
  const FocusAnimationPage({super.key});

  @override
  State<FocusAnimationPage> createState() => _FocusAnimationPageState();
}

class _FocusAnimationPageState extends State<FocusAnimationPage>
    with WidgetsBindingObserver {
  final List<String> _currentImages = [];
  AppProvider? _appProvider;

  final List<String> _defaultAssets = [
    'assets/bg1.jpg',
    'assets/bg2.jpg',
    'assets/bg3.jpg',
    'assets/bg4.jpg',
    'assets/bg5.jpg',
  ];

  int _imageIndex = 0;
  Timer? _slideshowTimer;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  Offset _clockPosition = const Offset(100, 100);
  double _clockFontSize = 30.0;
  double _baseScaleFactor = 1.0;
  double _scaleFactor = 1.0;

  @override
  void initState() {
    super.initState();
    _forceLandscapeMode();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePage();
      context.read<AppProvider>().addListener(_checkAppState);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appProvider = context.read<AppProvider>();
  }

  void _forceLandscapeMode() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _initializePage() {
    final appProvider = context.read<AppProvider>();
    final notifProvider = context.read<NotificationProvider>();

    notifProvider.startListeningToNotifications();

    if (appProvider.isWallpaperSetupDone &&
        appProvider.wallpaperPaths.isNotEmpty) {
      setState(() => _currentImages.addAll(appProvider.wallpaperPaths));
      _enterFocusMode();
    } else {
      WallpaperSetupDialog.show(
        context: context,
        defaultAssets: _defaultAssets,
        onWallpapersSelected: (paths) {
          setState(() => _currentImages.addAll(paths));
          _enterFocusMode();
        },
      );
    }
  }

  void _enterFocusMode() {
    _forceLandscapeMode();
    _startTimers();
  }

  void _startTimers() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    _slideshowTimer =
        Timer.periodic(const Duration(minutes: 30), (timer) {
          if (mounted && _currentImages.isNotEmpty) {
            setState(
                    () => _imageIndex = (_imageIndex + 1) % _currentImages.length);
          }
        });
  }

  @override
  void dispose() {
    _slideshowTimer?.cancel();
    _clockTimer?.cancel();
    _appProvider?.removeListener(_checkAppState);
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {

      final route = ModalRoute.of(context);
      if (route != null && route.isCurrent) {
        _forceLandscapeMode();
      }
      // what was happening that either from dashboard or any page when i close the app temp and
      // again resume it they were forcing it to be landscape and that should not happen it should
      // happen only for focusAnimation but earlier it was happening so by adding this it check
      // focusLandscape only if last page which was open was focusAnimation page


      _checkAppState();
    }
  }

  void _checkAppState() {
    if (!mounted) return;
    final provider = context.read<AppProvider>();
    if (provider.currentState == AppState.nightRest) {
      provider.removeListener(_checkAppState);
      WidgetsBinding.instance.removeObserver(this);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NightRestPage()),
      );
    }
  }

  void _openSideMenu({required bool isRightSide}) {
    // Capture providers BEFORE entering the dialog
    final appProvider = context.read<AppProvider>();
    final questsProvider = context.read<QuestsProvider>();
    final notifProvider = context.read<NotificationProvider>();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: appProvider),
            ChangeNotifierProvider.value(value: questsProvider),
            ChangeNotifierProvider.value(value: notifProvider),
          ],
          child: Align(
            alignment:
            isRightSide ? Alignment.centerRight : Alignment.centerLeft,
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
                      child: isRightSide
                          ? const GoalsAndSideQuestsPanel()
                          : const InfoPanel(),
                    ),
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
        return SlideTransition(
          position: anim1.drive(offsetTween),
          child: child,
        );
      },
    );
  }

  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('assets/')) return AssetImage(path);
    return FileImage(File(path));
  }

  @override
  Widget build(BuildContext context) {
    final timeString = DateFormat('HH:mm').format(_now);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background slideshow
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
                  child:
                  Container(color: Colors.black.withValues(alpha: 0.3)),
                ),
              ),
            ),

          // Draggable clock
          if (_currentImages.isNotEmpty)
            Positioned(
              left: _clockPosition.dx,
              top: _clockPosition.dy,
              child: GestureDetector(
                onScaleStart: (_) => _baseScaleFactor = _scaleFactor,
                onScaleUpdate: (details) {
                  setState(() {
                    _clockPosition += details.focalPointDelta;
                    if (details.scale != 1.0) {
                      _scaleFactor =
                          (_baseScaleFactor * details.scale).clamp(0.5, 4.0);
                    }
                  });
                },
                child: Text(
                  timeString,
                  style: GoogleFonts.orbitron(
                    fontSize: _clockFontSize * _scaleFactor,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(
                          blurRadius: 10,
                          color: Colors.black,
                          offset: Offset(2, 2))
                    ],
                  ),
                ),
              ),
            ),

          // Top-right: Goals button
          Positioned(
            top: 20,
            right: 20,
            child: GlassButton(
              icon: Icons.list_alt,
              onTap: () => _openSideMenu(isRightSide: true),
            ),
          ),

          // Bottom-left: Notifications button
          Positioned(
            bottom: 20,
            left: 20,
            child: Consumer<NotificationProvider>(
              builder: (context, notifProvider, child) {
                return GlassButton(
                  icon: Icons.info_outline,
                  isGlowing: notifProvider.hasNewNotifications,
                  onTap: () {
                    notifProvider.markNotificationsAsRead();
                    _openSideMenu(isRightSide: false);
                  },
                );
              },
            ),
          ),

          // Bottom-right: Dashboard button
          Positioned(
            bottom: 20,
            right: 20,
            child: GlassButton(
              icon: Icons.insights,
              onTap: () async {
                await SystemChrome.setPreferredOrientations(
                    [DeviceOrientation.portraitUp]);
                if (!context.mounted) return;
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DashboardPage()),
                );
                _enterFocusMode();
              },
            ),
          ),
        ],
      ),
    );
  }
}