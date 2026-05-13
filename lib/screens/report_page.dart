import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart'; // NEW: For sharing the PDF
import 'dart:ui';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import '../providers/app_provider.dart';
import '../services/report_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ReportService _reportService = ReportService();

  bool _isGenerating = false;
  bool _isLoadingFiles = true;
  String _statusMessage = "Ready to analyze performance.";

  List<File> _savedReports = [];

  @override
  void initState() {
    super.initState();
    _loadSavedReports();
  }

  Future<void> _loadSavedReports() async {
    try {
      final directory = await getTemporaryDirectory();
      final files = directory.listSync();

      List<File> pdfs = [];
      for (var file in files) {
        if (file is File && file.path.endsWith('.pdf') && file.path.contains('FocusDesk_Report_')) {
          pdfs.add(file);
        }
      }

      pdfs.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      if (mounted) {
        setState(() {
          _savedReports = pdfs;
          _isLoadingFiles = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFiles = false;
        });
      }
    }
  }

  void _generateReport() async {
    setState(() {
      _isGenerating = true;
      _statusMessage = "Compiling master data...\nInitializing AI analysis...";
    });

    try {
      final provider = context.read<AppProvider>();
      final Map<String, dynamic> fullContext = await provider.getFullContext();

      final pdfPath = await _reportService.fetchAndSaveReport(context: fullContext);

      if (!mounted) return;

      if (pdfPath != null) {
        setState(() {
          _statusMessage = "Report generated successfully.";
          _isGenerating = false;
        });

        await _loadSavedReports();

        final result = await OpenFile.open(pdfPath);
        if (result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Could not open PDF: ${result.message}")),
          );
        }
      } else {
        setState(() {
          _statusMessage = "Error: Server failed to generate report.";
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = "Critical Error occurred.";
        _isGenerating = false;
      });
    }
  }

  // --- NEW: Delete functionality ---
  Future<void> _deleteReport(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        await _loadSavedReports(); // Refresh the UI immediately
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Report deleted permanently.", style: GoogleFonts.inter()),
              backgroundColor: Colors.redAccent.withOpacity(0.8),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete report.")),
        );
      }
    }
  }

  // --- NEW: Share functionality ---
  void _shareReport(File file) {
    Share.shareXFiles(
      [XFile(file.path)],
      text: "Check out my FocusDesk Performance Report!",
    );
  }

  // --- NEW: The Long-Press Modal ---
  void _showOptionsModal(File file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.2), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // SHARE BUTTON
              ListTile(
                leading: const Icon(Icons.ios_share, color: Colors.cyanAccent),
                title: Text(
                  "Share Report",
                  style: GoogleFonts.orbitron(color: Colors.white, fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context); // Close modal
                  _shareReport(file);
                },
              ),
              Divider(color: Colors.white.withOpacity(0.05)),
              // DELETE BUTTON
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: Text(
                  "Delete Report",
                  style: GoogleFonts.orbitron(color: Colors.redAccent, fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context); // Close modal
                  _deleteReport(file);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF050505),
            const Color(0xFF000000),
            Colors.cyan.withOpacity(0.05),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "AI ANALYTICS",
            style: GoogleFonts.orbitron(
              color: Colors.white,
              letterSpacing: 2,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingFiles) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      );
    }

    if (_isGenerating) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 2),
              const SizedBox(height: 24),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  color: Colors.cyanAccent,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_savedReports.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.cyanAccent, Colors.blueAccent],
                ).createShader(bounds),
                child: const Icon(Icons.analytics_outlined, size: 100, color: Colors.white),
              ),
              const SizedBox(height: 32),
              Text(
                "Deep Performance Scan",
                style: GoogleFonts.orbitron(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Generate a comprehensive, AI-driven PDF report detailing your daily completion rates, behavioral patterns, and goal proximity.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white60,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              _buildGenerateButton("GENERATE REPORT"),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "REPORT VAULT",
            style: GoogleFonts.orbitron(
              color: Colors.cyanAccent,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: _savedReports.length,
              itemBuilder: (context, index) {
                final file = _savedReports[index];
                final date = file.lastModifiedSync();
                final dateString = DateFormat('MMM dd, yyyy - hh:mm a').format(date);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.picture_as_pdf, color: Colors.cyanAccent),
                    ),
                    title: Text(
                      "Performance Report",
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      dateString,
                      style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                    ),
                    // --- NEW: Added onLongPress ---
                    onLongPress: () => _showOptionsModal(file),
                    onTap: () async {
                      final result = await OpenFile.open(file.path);
                      if (result.type != ResultType.done && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Could not open PDF: ${result.message}")),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildGenerateButton("GENERATE NEW REPORT"),
        ],
      ),
    );
  }

  Widget _buildGenerateButton(String text) {
    return GestureDetector(
      onTap: _generateReport,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.cyanAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.cyanAccent.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: -5,
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.orbitron(
              color: Colors.cyanAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}