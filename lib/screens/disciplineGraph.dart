import 'package:focusdesk/components/disciplineGraph_Widgets/graph_detail_card.dart';
import 'package:focusdesk/components/disciplineGraph_Widgets/graph_header_row.dart';
import 'package:focusdesk/components/disciplineGraph_Widgets/graph_painter.dart';
import 'package:focusdesk/components/disciplineGraph_Widgets/month_selector_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';



class DisciplineGraphWidget extends StatefulWidget {
  final List<Map<String, dynamic>> history;

  const DisciplineGraphWidget({super.key, required this.history});

  @override
  State<DisciplineGraphWidget> createState() => _DisciplineGraphWidgetState();
}

class _DisciplineGraphWidgetState extends State<DisciplineGraphWidget> {
  int _selectedIndex = -1;
  bool _isFitToScreen = true;

  List<Map<String, dynamic>> _sortedHistory = [];
  List<String> _availableMonths = [];
  String _selectedMonth = "LAST 30";

  static const double _fixedDayWidth = 60.0;
  static const double _graphHeight = 180.0;

  @override
  void initState() {
    super.initState();
    _buildAvailableMonths();
    _processData();
  }

  @override
  void didUpdateWidget(covariant DisciplineGraphWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.history != oldWidget.history) {
      _buildAvailableMonths();
      _processData();
    }
  }

  void _buildAvailableMonths() {
    if (widget.history.isEmpty) {
      _availableMonths = ["LAST 30"];
      return;
    }

    final sorted = List<Map<String, dynamic>>.from(widget.history)
      ..sort((a, b) => a['date'].compareTo(b['date']));

    final earliestDate = DateTime.parse(sorted.first['date']);
    final latestDate = DateTime.parse(sorted.last['date']);

    final List<String> months = ["LAST 30"];
    DateTime cursor = DateTime(earliestDate.year, earliestDate.month);
    final DateTime end = DateTime(latestDate.year, latestDate.month);

    while (!cursor.isAfter(end)) {
      months.add("${cursor.year}-${cursor.month.toString().padLeft(2, '0')}");
      cursor = DateTime(cursor.year, cursor.month + 1);
    }

    _availableMonths = months;
    if (!_availableMonths.contains(_selectedMonth)) {
      _selectedMonth = "LAST 30";
    }
  }

  void _processData() {
    setState(() {
      final fullHistory = List<Map<String, dynamic>>.from(widget.history)
        ..sort((a, b) => a['date'].compareTo(b['date']));

      if (_selectedMonth == "LAST 30") {
        _sortedHistory = fullHistory.length > 30
            ? fullHistory.sublist(fullHistory.length - 30)
            : fullHistory;
      } else {
        _sortedHistory = fullHistory
            .where((e) => (e['date'] as String).startsWith(_selectedMonth))
            .toList();
      }

      _selectedIndex =
      _sortedHistory.isNotEmpty ? _sortedHistory.length - 1 : -1;
    });
  }

  void _onMonthSelected(String month) {
    setState(() {
      _selectedMonth = month;
      _isFitToScreen = true;
    });
    _processData();
  }

  void _onZoomToggle() {
    setState(() {
      _isFitToScreen = !_isFitToScreen;
      _selectedIndex = _isFitToScreen ? _sortedHistory.length - 1 : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.history.isEmpty) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final double effectiveDayWidth = _isFitToScreen
            ? (_sortedHistory.isNotEmpty
            ? availableWidth / _sortedHistory.length
            : availableWidth)
            : _fixedDayWidth;

        final double totalCanvasWidth = _isFitToScreen
            ? availableWidth
            : _sortedHistory.length * _fixedDayWidth;

        return Column(
          children: [
            GraphHeaderRow(
              selectedMonth: _selectedMonth,
              isFitToScreen: _isFitToScreen,
              availableMonths: _availableMonths,
              onZoomToggle: _onZoomToggle,
              onMonthSelected: _onMonthSelected,
            ),

            const SizedBox(height: 10),

            _buildGraph(effectiveDayWidth, totalCanvasWidth),

            const SizedBox(height: 15),

            GraphDetailCard(
              sortedHistory: _sortedHistory,
              selectedIndex: _selectedIndex,
            ),
          ],
        );
      },
    );
  }

  Widget _buildGraph(double effectiveDayWidth, double totalCanvasWidth) {
    if (_sortedHistory.isEmpty) {
      return Container(
        height: _graphHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Center(
          child: Text(
            "NO DATA FOR ${formatMonthLabel(_selectedMonth)}",
            style: GoogleFonts.orbitron(
              color: Colors.white24,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: _graphHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: _isFitToScreen
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics(),
        reverse: !_isFitToScreen,
        child: GestureDetector(
          onTapUp: (details) {
            final int index =
            (details.localPosition.dx / effectiveDayWidth).floor();
            if (index >= 0 && index < _sortedHistory.length) {
              setState(() => _selectedIndex = index);
            }
          },
          child: CustomPaint(
            size: Size(totalCanvasWidth, _graphHeight),
            painter: ScrollableGraphPainter(
              history: _sortedHistory,
              dayWidth: effectiveDayWidth,
              selectedIndex: _selectedIndex,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
          child: Row(
            children: [
              Text(
                "DISCIPLINE WAVE",
                style: GoogleFonts.orbitron(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: _graphHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: double.infinity,
                child: CustomPaint(
                  painter: ScrollableGraphPainter(
                    history: const [],
                    dayWidth: 60,
                    selectedIndex: -1,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.show_chart_rounded,
                    color: Colors.cyanAccent.withValues(alpha: 0.3),
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "WELCOME TO FocusDesk",
                    style: GoogleFonts.orbitron(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Complete your first day to start the trend.",
                    style: GoogleFonts.roboto(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
          ),
          child: Center(
            child: Text(
              "NO PERFORMANCE DATA YET",
              style: GoogleFonts.orbitron(
                color: Colors.white24,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}