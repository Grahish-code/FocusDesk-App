import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class NotificationPanel extends StatelessWidget {
  const NotificationPanel({super.key});


  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final notifs = provider.notifications;

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

            // Inside NotificationPanel -> build -> ListView.builder
            return Dismissible(
              key: Key(notification.id ?? DateTime.now().toString()),
              direction: DismissDirection.horizontal,
              onDismissed: (direction) {
                provider.dismissNotificationById(notification.id);
              },
              // CHANGE: Remove the red container entirely.
              // We use an empty Container() so it is transparent.
              background: Container(color: Colors.transparent),

              child: _buildItem(context, notification, provider),
            );
          },
        );
      },
    );
  }

  Widget _buildItem(BuildContext context, NotificationEvent event, AppProvider provider) {
    return GestureDetector(
      onTap: () => provider.openAppFromNotification(event.packageName),
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
                // --- FIX: Wrap Title in Expanded ---
                Expanded(
                  child: Text(
                    event.title ?? "System",
                    style: GoogleFonts.orbitron(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12
                    ),
                    maxLines: 1, // Force single line
                    overflow: TextOverflow.ellipsis, // Adds "..." if too long
                  ),
                ),

                const SizedBox(width: 10), // Add some spacing so they don't touch

                // Time stays as is (it doesn't expand)
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
                event.text ?? "",
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