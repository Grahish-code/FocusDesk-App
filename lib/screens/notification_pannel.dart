import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// --- MODELS & PROVIDERS ---
import 'package:focusdesk/models/notification_event.dart';
import '../providers/notification_provider.dart';

class NotificationPanel extends StatelessWidget {
  const NotificationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. CHANGE: Listen to NotificationProvider instead of AppProvider
    return Consumer<NotificationProvider>(
      builder: (context, notifProvider, child) {
        final notifs = notifProvider.notifications;

        // 1. Empty State
        if (notifs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.notifications_off_outlined, color: Colors.white24, size: 40),
                const SizedBox(height: 10),
                Text("NO ALERTS", style: GoogleFonts.orbitron(color: Colors.white24)),
              ],
            ),
          );
        }

        // 2. List of Notifications
        return ListView.builder(
          itemCount: notifs.length,
          itemBuilder: (context, index) {
            final notification = notifs[index];

            return Dismissible(
              key: Key(notification.id), // The ID in your model is non-nullable, so we don't need ??
              direction: DismissDirection.horizontal,
              onDismissed: (direction) {
                // 2. CHANGE: Call dismiss from notifProvider
                notifProvider.dismissNotificationById(notification.id);
              },
              background: Container(color: Colors.transparent),

              // 3. CHANGE: Pass notifProvider to the helper widget
              child: _buildItem(context, notification, notifProvider),
            );
          },
        );
      },
    );
  }

  // 4. CHANGE: Update the parameter to expect NotificationProvider
  Widget _buildItem(BuildContext context, NotificationBridge event, NotificationProvider notifProvider) {
    return GestureDetector(
      // 5. CHANGE: Call openApp from notifProvider
      onTap: () => notifProvider.openAppFromNotification(event.packageName),
      child: Container(
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
                Expanded(
                  child: Text(
                    event.title, // Non-nullable in your model
                    style: GoogleFonts.orbitron(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(width: 10),

                Text(
                    _formatTime(event.createAt),
                    style: GoogleFonts.orbitron(
                        color: Colors.white38,
                        fontSize: 10
                    )
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
                event.text, // Non-nullable in your model
                style: GoogleFonts.roboto(color: Colors.white70, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return "--:--";
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }
}