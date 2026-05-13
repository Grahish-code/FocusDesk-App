import 'dart:math' as math; // Required for the random flame flicker
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';


class DashboardStats extends StatefulWidget {
  final int successfulDays;
  final int totalDays;
  final int currentStreak;

  const DashboardStats({
    super.key,
    required this.successfulDays,
    required this.totalDays,
    required this.currentStreak,
  });

  @override
  State<DashboardStats> createState() => _DashboardStatsState();
}

class _DashboardStatsState extends State<DashboardStats> {
  @override
  Widget build(BuildContext context) {
    final double percentage =
    widget.totalDays > 0 ? widget.successfulDays / widget.totalDays : 0.0;

    final bool isHighPerformance = percentage >= 0.65;
    final Color accentColor =
    isHighPerformance ? Colors.cyanAccent : Colors.redAccent;

    return Container(
      // Matching the horizontal padding and background feel of the GraphDetailCard
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // --- LEFT: ARC PROGRESS CIRCLE ---
          SizedBox(
            width: 100, // Slightly increased for better ratio
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(100, 100),
                  painter: _ArcPainter(
                    progress: percentage,
                    color: accentColor,
                    backgroundColor: accentColor.withValues(alpha: 0.1),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${widget.successfulDays}/${widget.totalDays}",
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 16, // Matches Date headline size
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "SCORE",
                      style: GoogleFonts.orbitron(
                        color: Colors.white38,
                        fontSize: 10, // Matches DATE RECORD label size
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 25), // Increased spacing for visual separation

          // --- RIGHT: STATS BREAKDOWN ---
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatRow(
                  label: "Completed",
                  value: "${widget.successfulDays}d",
                  color: isHighPerformance ? accentColor : Colors.white38,
                  isHighlighted: isHighPerformance,
                ),
                const SizedBox(height: 8),
                _StatRow(
                  label: "Remaining",
                  value: "${widget.totalDays - widget.successfulDays}d",
                  color: !isHighPerformance ? accentColor : Colors.white38,
                  isHighlighted: !isHighPerformance,
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 6, // Slightly thicker to match the heavier UI
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${(percentage * 100).toStringAsFixed(0)}% OF ${DateFormat('MMMM').format(DateTime.now()).toUpperCase()} DONE",
                  style: GoogleFonts.orbitron(
                    color: Colors.white30,
                    fontSize: 10, // Matches standard label size
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isHighlighted;

  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.orbitron(
            color: isHighlighted ? color.withValues(alpha: 0.7) : Colors.white38,
            fontSize: 9, // Normalized to 10px
            letterSpacing: 1.2,
          ),
        ),
        Container(
          padding: isHighlighted
              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
              : EdgeInsets.zero,
          decoration: isHighlighted
              ? BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
          )
              : null,
          child: Text(
            value,
            style: GoogleFonts.orbitron(
              color: color,
              fontSize: 13, // Slightly larger for readability
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// --- Arc painter ---
class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _ArcPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 6;
    const strokeWidth = 5.0;
    const startAngle = -math.pi / 2;
    const fullSweep = 2 * math.pi;

    // Background track
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      fullSweep,
      false,
      bgPaint,
    );

    // Glow layer
    final glowPaint = Paint()
      ..color = color.withOpacity(0.25)
      ..strokeWidth = strokeWidth + 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      fullSweep * progress,
      false,
      glowPaint,
    );

    // Foreground arc
    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      fullSweep * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class DashboardActions extends StatelessWidget {
  final VoidCallback onStrategyTap;
  final VoidCallback onAutoWakeTap;
  final VoidCallback onAiAssistantTap;

  const DashboardActions({
    super.key,
    required this.onStrategyTap,
    required this.onAutoWakeTap,
    required this.onAiAssistantTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Strategy + Auto-wake row
        Row(
          children: [
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: onStrategyTap,
                  icon: const Icon(Icons.track_changes,
                      color: Colors.white70, size: 16),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  label: Text(
                    "STRATEGY",
                    style: GoogleFonts.orbitron(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: onAutoWakeTap,
                  icon: const Icon(Icons.layers_outlined,
                      color: Colors.cyanAccent, size: 16),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.cyanAccent.withOpacity(0.3),
                    ),
                    backgroundColor: Colors.cyanAccent.withOpacity(0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  label: Text(
                    "PERMISSION",
                    style: GoogleFonts.orbitron(
                      color: Colors.cyanAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),

        // AI Assistant button
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: onAiAssistantTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent.withOpacity(0.1),
              foregroundColor: Colors.cyanAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.cyanAccent, width: 1),
              ),
            ),
            child: Text(
              "PERFORMANCE  REPORT",
              style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}