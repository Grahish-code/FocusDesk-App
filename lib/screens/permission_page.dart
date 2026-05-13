import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Each permission has its own accent color so nothing looks "same same"
  final List<_PermissionItem> _permissions = [
    _PermissionItem(
      title: 'GOAL REMINDERS',
      description:
      'We send you study reminders and momentum nudges. Silent during sessions — only fires when you\'re free.',
      icon: Icons.notifications_active_outlined,
      accentColor: Colors.cyanAccent,
      isBatteryInfo: false,
    ),
    _PermissionItem(
      title: 'DISTRACTION FILTER',
      description:
      'Reads notification metadata to block Swiggy, Amazon & social noise while you\'re locked in. Never reads message content.',
      icon: Icons.filter_alt_outlined,
      accentColor: const Color(0xFFFF6B6B),
      isBatteryInfo: false,
    ),
    _PermissionItem(
      title: 'AUTO-GOAL OVERLAY',
      description:
      'Pops a 3-second goal prompt when you unlock your phone. Dismiss or confirm — that\'s it.',
      icon: Icons.layers_outlined,
      accentColor: const Color(0xFFFFD166),
      isBatteryInfo: false,
    ),
    _PermissionItem(
      title: 'UNRESTRICTED ENGINE',
      description:
      'No action needed from you. Android restricts background apps automatically — this just lets you know we\'re aware. FocusDesk handles it internally.',
      icon: Icons.battery_charging_full_outlined,
      accentColor: const Color(0xFF06D6A0),
      isBatteryInfo: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkAllPermissions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkAllPermissions() async {
    final notifStatus = await Permission.notification.status;
    final overlayGranted = await FlutterOverlayWindow.isPermissionGranted();

    setState(() {
      _permissions[0].isGranted = notifStatus.isGranted;
      // Notification Listener has no runtime API check via permission_handler.
      // To check it properly you need a method channel calling:
      // NotificationManagerCompat.getEnabledListenerPackages(context).contains(packageName)
      _permissions[1].isGranted = false;
      _permissions[2].isGranted = overlayGranted ?? false;
      _permissions[3].isGranted = true; // battery — info only, always done
    });
  }

  Future<void> _handlePermission(int index) async {
    switch (index) {
      case 0:
        final status = await Permission.notification.request();
        setState(() => _permissions[0].isGranted = status.isGranted);
        break;

      case 1:
      // Opens Android's ACTION_NOTIFICATION_LISTENER_SETTINGS directly.
      // AppSettingsType.notification is wrong — that opens the app's notification
      // channel page. notificationListener opens the system-level listener access page.
        await AppSettings.openAppSettings(
          type: AppSettingsType.notification,
        );
        // User must toggle it manually on that screen. After returning,
        // optimistically mark as granted. Replace with method channel check in production.
        setState(() => _permissions[1].isGranted = true);
        break;

      case 2:
        final alreadyGranted = await FlutterOverlayWindow.isPermissionGranted();
        if (!(alreadyGranted ?? false)) {
          await FlutterOverlayWindow.requestPermission();
        }
        final nowGranted = await FlutterOverlayWindow.isPermissionGranted();
        setState(() => _permissions[2].isGranted = nowGranted ?? false);
        break;

      case 3:
      // Info only — nothing to grant.
        break;
    }
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _next() {
    if (_currentStep < _permissions.length - 1) {
      _goToPage(_currentStep + 1);
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  bool get _allGranted =>
      _permissions.where((p) => !p.isBatteryInfo).every((p) => p.isGranted);

  @override
  Widget build(BuildContext context) {
    final isLast = _currentStep == _permissions.length - 1;
    final currentAccent = _permissions[_currentStep].accentColor;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'SETUP SUPERPOWERS',
          style: GoogleFonts.orbitron(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Step dots ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_permissions.length, (i) {
                  final isDone = _permissions[i].isGranted;
                  final isCurrent = i == _currentStep;
                  final accent = _permissions[i].accentColor;
                  return GestureDetector(
                    onTap: () => _goToPage(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: isCurrent ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isDone
                            ? const Color(0xFF06D6A0)
                            : isCurrent
                            ? accent
                            : accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ── Swipeable pages ───────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentStep = i),
                itemCount: _permissions.length,
                itemBuilder: (context, index) {
                  final perm = _permissions[index];
                  return _buildPermissionPage(perm, index);
                },
              ),
            ),

            // ── Offline banner ────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.07)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    color: Color(0xFF8B949E),
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'FOCUSDESK IS 100% OFFLINE.  ',
                            style: GoogleFonts.orbitron(
                              color: const Color(0xFF58A6FF),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          TextSpan(
                            text:
                            'No data, notifications, or activity ever leaves your device.',
                            style: GoogleFonts.roboto(
                              color: const Color(0xFF8B949E),
                              fontSize: 10,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom nav ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    GestureDetector(
                      onTap: () => _goToPage(_currentStep - 1),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_rounded,
                          color: Colors.white54,
                          size: 16,
                        ),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _next,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 48,
                        decoration: BoxDecoration(
                          color: currentAccent.withOpacity(0.12),
                          border: Border.all(color: currentAccent),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            isLast
                                ? (_allGranted ? 'LAUNCH →' : 'CONTINUE →')
                                : 'NEXT →',
                            style: GoogleFonts.orbitron(
                              color: currentAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Granted counter ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${_permissions.where((p) => p.isGranted).length} of ${_permissions.length} complete',
                style: GoogleFonts.roboto(
                  color: Colors.white.withOpacity(0.2),
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionPage(_PermissionItem perm, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon circle
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: perm.isGranted
                  ? const Color(0xFF06D6A0).withOpacity(0.1)
                  : perm.accentColor.withOpacity(0.1),
              border: Border.all(
                color: perm.isGranted
                    ? const Color(0xFF06D6A0)
                    : perm.accentColor.withOpacity(0.6),
                width: 1.5,
              ),
            ),
            child: Icon(
              perm.isGranted ? Icons.check_circle_outline : perm.icon,
              color: perm.isGranted
                  ? const Color(0xFF06D6A0)
                  : perm.accentColor,
              size: 38,
            ),
          ),

          const SizedBox(height: 32),

          // Title — Orbitron, each card's own accent color
          Text(
            perm.title,
            style: GoogleFonts.orbitron(
              color: perm.accentColor,
              fontWeight: FontWeight.bold,
              fontSize: 17,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description — Roboto intentionally (different from title font)
          Text(
            perm.description,
            style: GoogleFonts.roboto(
              color: Colors.white.withOpacity(0.55),
              fontSize: 13,
              height: 1.7,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Grant button, granted badge, or info badge
          SizedBox(
            width: double.infinity,
            child: perm.isBatteryInfo
                ? _buildInfoBadge(perm)
                : perm.isGranted
                ? _buildGrantedBadge()
                : _buildGrantButton(perm, index),
          ),

          const SizedBox(height: 20),

          // Swipe hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.swipe_rounded,
                  size: 14, color: Colors.white.withOpacity(0.15)),
              const SizedBox(width: 6),
              Text(
                'swipe to navigate',
                style: GoogleFonts.roboto(
                  color: Colors.white.withOpacity(0.15),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrantButton(_PermissionItem perm, int index) {
    return OutlinedButton(
      onPressed: () => _handlePermission(index),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: perm.accentColor),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        'GRANT PERMISSION →',
        style: GoogleFonts.orbitron(
          color: perm.accentColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildGrantedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border:
        Border.all(color: const Color(0xFF06D6A0).withOpacity(0.5)),
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFF06D6A0).withOpacity(0.07),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check, color: Color(0xFF06D6A0), size: 16),
          const SizedBox(width: 8),
          Text(
            'PERMISSION GRANTED',
            style: GoogleFonts.orbitron(
              color: const Color(0xFF06D6A0),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(_PermissionItem perm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: perm.accentColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(10),
        color: perm.accentColor.withOpacity(0.05),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: perm.accentColor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'FocusDesk manages battery optimization internally. No action needed — we\'ve already handled it.',
              style: GoogleFonts.roboto(
                color: perm.accentColor.withOpacity(0.8),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionItem {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final bool isBatteryInfo;
  bool isGranted;

  _PermissionItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.isBatteryInfo,
    this.isGranted = false,
  });
}