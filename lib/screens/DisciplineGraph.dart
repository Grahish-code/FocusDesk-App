import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;

class DisciplineGraphWidget extends StatefulWidget {
  final List<Map<String, dynamic>> history;

  const DisciplineGraphWidget({super.key, required this.history});

  @override
  State<DisciplineGraphWidget> createState() => _DisciplineGraphWidgetState();
}

class _DisciplineGraphWidgetState extends State<DisciplineGraphWidget> {
  int _selectedIndex = -1;
  bool _isFitToScreen = true; // Toggle State

  final double _fixedDayWidth = 60.0;
  final double _graphHeight = 180.0;

  @override
  void initState() {
    super.initState();
    // DEFAULT 1: Automatically select the LATEST day (last item) on startup
    if (widget.history.isNotEmpty) {
      _selectedIndex = widget.history.length - 1;
    }
  }

  @override
  void didUpdateWidget(covariant DisciplineGraphWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If data changes (e.g. loads from API), reset selection to latest
    if (widget.history != oldWidget.history && widget.history.isNotEmpty) {
      setState(() {
        // Keep current selection logic or reset to latest
        _selectedIndex = widget.history.length - 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.history.isEmpty) {
      return Container(
        height: _graphHeight,
        alignment: Alignment.center,
        child: Text("No Data Available", style: GoogleFonts.orbitron(color: Colors.white38)),
      );
    }

    return LayoutBuilder(
        builder: (context, constraints) {
          // 1. CALCULATE WIDTHS
          double availableWidth = constraints.maxWidth;
          double effectiveDayWidth = _isFitToScreen
              ? availableWidth / widget.history.length
              : _fixedDayWidth;

          double totalCanvasWidth = _isFitToScreen
              ? availableWidth
              : widget.history.length * _fixedDayWidth;

          return Column(
            children: [
              // --- HEADER WITH ZOOM TOGGLE ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        _isFitToScreen ? "30-DAY OVERVIEW" : "SCROLL TO INSPECT",
                        style: GoogleFonts.orbitron(color: Colors.white38, fontSize: 10, letterSpacing: 2)
                    ),

                    // ZOOM BUTTON
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isFitToScreen = !_isFitToScreen;

                          // LOGIC CHANGED HERE AS REQUESTED:
                          // If switching TO Fit (Overview) -> Select LATEST (Last index)
                          // If switching TO Scroll (Inspect) -> Select FIRST (Index 0)
                          if (_isFitToScreen) {
                            _selectedIndex = widget.history.length - 1;
                          } else {
                            _selectedIndex = 0;
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                                _isFitToScreen ? Icons.zoom_in : Icons.zoom_out,
                                color: Colors.cyanAccent,
                                size: 14
                            ),
                            const SizedBox(width: 6),
                            Text(
                                _isFitToScreen ? "EXPAND" : "FIT ALL",
                                style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold)
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // --- THE GRAPH ---
              SizedBox(
                height: _graphHeight,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: _isFitToScreen ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                  reverse: !_isFitToScreen,
                  child: GestureDetector(
                    onTapUp: (details) {
                      double dx = details.localPosition.dx;
                      int index = (dx / effectiveDayWidth).floor();

                      if (index >= 0 && index < widget.history.length) {
                        setState(() {
                          _selectedIndex = index;
                        });
                      }
                    },
                    child: CustomPaint(
                      size: Size(totalCanvasWidth, _graphHeight),
                      painter: _ScrollableGraphPainter(
                        history: widget.history,
                        dayWidth: effectiveDayWidth,
                        selectedIndex: _selectedIndex,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // --- THE DETAIL POPUP (ALWAYS VISIBLE NOW) ---
              // Removed AnimatedOpacity logic that hid it when -1
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildDetailCard(),
              ),
            ],
          );
        }
    );
  }

  Widget _buildDetailCard() {
    // Safety check: If list is empty, return spacer.
    // If _selectedIndex is -1 (shouldn't happen now), show nothing.
    if (widget.history.isEmpty || _selectedIndex == -1 || _selectedIndex >= widget.history.length) {
      return const SizedBox(height: 60);
    }

    final data = widget.history[_selectedIndex];
    final date = data['date'];
    final completed = (data['completed_goals'] as List).length;
    final total = (data['total_goals'] as List).length;
    final isSuccess = data['status'] == 'Completed';

    // Key to trigger animation when data changes
    return Container(
      key: ValueKey(_selectedIndex),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
            color: isSuccess ? Colors.cyanAccent.withValues(alpha: 0.3) : Colors.redAccent.withValues(alpha: 0.3)
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "DATE RECORD",
                style: GoogleFonts.orbitron(color: Colors.white38, fontSize: 10, letterSpacing: 1),
              ),
              const SizedBox(height: 4),
              Text(
                date.toString().substring(5), // Shows MM-DD
                style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Container(width: 1, height: 30, color: Colors.white12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "PERFORMANCE",
                style: GoogleFonts.orbitron(color: Colors.white38, fontSize: 10, letterSpacing: 1),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    "$completed/$total",
                    style: GoogleFonts.orbitron(
                        color: isSuccess ? Colors.cyanAccent : Colors.redAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                  Text(
                    " TASKS",
                    style: GoogleFonts.orbitron(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScrollableGraphPainter extends CustomPainter {
  final List<Map<String, dynamic>> history;
  final double dayWidth;
  final int selectedIndex;

  _ScrollableGraphPainter({
    required this.history,
    required this.dayWidth,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint glowPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.4)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final Paint dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Paint gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;

    double topY = 0;
    double bottomY = size.height;

    // Grid
    canvas.drawLine(Offset(0, topY), Offset(size.width, topY), gridPaint);
    canvas.drawLine(Offset(0, size.height/2), Offset(size.width, size.height/2), gridPaint);
    canvas.drawLine(Offset(0, bottomY), Offset(size.width, bottomY), gridPaint);

    // Vertical Separators
    for(int i=0; i<history.length; i++) {
      double x = i * dayWidth + (dayWidth/2);
      canvas.drawLine(Offset(x, topY), Offset(x, bottomY), gridPaint..color = Colors.white.withValues(alpha: 0.02));
    }

    // Curve Path
    Path path = Path();

    for (int i = 0; i < history.length; i++) {
      List<dynamic> total = history[i]['total_goals'] ?? [];
      List<dynamic> completed = history[i]['completed_goals'] ?? [];

      double ratio = 0.0;
      if (total.isNotEmpty) ratio = completed.length / total.length;

      double x = i * dayWidth + (dayWidth / 2);
      double y = bottomY - (ratio * (bottomY - topY));
      y = y.clamp(topY + 10, bottomY - 10);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        double prevX = (i - 1) * dayWidth + (dayWidth / 2);

        List<dynamic> prevTotal = history[i-1]['total_goals'] ?? [];
        List<dynamic> prevCompleted = history[i-1]['completed_goals'] ?? [];
        double prevRatio = 0.0;
        if (prevTotal.isNotEmpty) prevRatio = prevCompleted.length / prevTotal.length;

        double prevY = bottomY - (prevRatio * (bottomY - topY));
        prevY = prevY.clamp(topY + 10, bottomY - 10);

        path.cubicTo(prevX + dayWidth/2, prevY, prevX + dayWidth/2, y, x, y);
      }

      // Dynamic Dot Size
      double dotRadius = dayWidth < 30 ? 2 : 4;
      canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);

      // Selected Highlight
      if (i == selectedIndex) {
        final Paint selectPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawCircle(Offset(x, y), dotRadius + 6, selectPaint);

        final Paint indicatorPaint = Paint()
          ..shader = ui.Gradient.linear(
              Offset(x, y), Offset(x, bottomY),
              [Colors.cyanAccent, Colors.transparent]
          )
          ..strokeWidth = 1;

        canvas.drawLine(Offset(x, y + 10), Offset(x, bottomY), indicatorPaint);
      }
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}