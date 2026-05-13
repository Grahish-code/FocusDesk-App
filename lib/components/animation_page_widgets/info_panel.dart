import 'package:focusdesk/providers/notification_provider.dart';
import 'package:focusdesk/screens/notification_pannel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'live_battery_widget.dart';

class InfoPanel extends StatelessWidget {
  const InfoPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(DateTime.now());
    final date = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time & Battery Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              time,
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const LiveBatteryWidget(),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          date.toUpperCase(),
          style: GoogleFonts.orbitron(
            color: Colors.white54,
            fontSize: 14,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 30),

        // Notifications Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "NOTIFICATIONS",
              style: GoogleFonts.orbitron(
                color: Colors.cyanAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              tooltip: "Grant Permission",
              icon: const Icon(Icons.security, color: Colors.white54, size: 20),
              // THE FIX: Read the provider HERE inside build's context,
              // then pass it into the dialog method.
              onPressed: () {
                final notificationProvider =
                context.read<NotificationProvider>();
                _showPrivacyDialog(context, notificationProvider);
              },
            ),
          ],
        ),
        const Divider(color: Colors.white24),

        // Notification List
        const Expanded(child: NotificationPanel()),
      ],
    );
  }

  // THE FIX: Accept NotificationProvider as a parameter instead of
  // reading it from context inside this method.
  void _showPrivacyDialog(
      BuildContext context,
      NotificationProvider notificationProvider,
      ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: Colors.white10),
        ),
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: Colors.cyanAccent),
            const SizedBox(width: 10),
            Text(
              "PRIVACY & CONTROL",
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
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
                border: Border.all(
                  color: Colors.cyanAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    color: Colors.cyanAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Your Data Stays Here.\nWe process notifications locally on this device. We never store, read, or transmit your personal messages or OTPs to any server.",
                      style: GoogleFonts.roboto(
                        color: Colors.cyanAccent,
                        fontSize: 12,
                        height: 1.4,
                      ),
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
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              "CANCEL",
              style: GoogleFonts.orbitron(color: Colors.white54),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.cyanAccent.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              notificationProvider.openNotificationSettings();
            },
            child: Text(
              "PROCEED TO SETTINGS",
              style: GoogleFonts.orbitron(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}