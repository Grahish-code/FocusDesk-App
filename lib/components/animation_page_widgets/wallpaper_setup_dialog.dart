import 'dart:ui';
import 'package:focusdesk/providers/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';



class WallpaperSetupDialog extends StatelessWidget {
  final List<String> defaultAssets;
  final void Function(List<String> paths) onWallpapersSelected;

  const WallpaperSetupDialog({
    super.key,
    required this.defaultAssets,
    required this.onWallpapersSelected,
  });

  /// Call this to show the dialog. It is non-dismissible.
  static void show({
    required BuildContext context,
    required List<String> defaultAssets,
    required void Function(List<String> paths) onWallpapersSelected,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => WallpaperSetupDialog(
        defaultAssets: defaultAssets,
        onWallpapersSelected: onWallpapersSelected,
      ),
      transitionBuilder: (ctx, anim1, anim2, child) => Transform.scale(
        scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack).value,
        child: FadeTransition(opacity: anim1, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wallpaper,
                      color: Colors.cyanAccent, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    "WALLPAPER SETUP",
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tip banner
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.cyanAccent.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.cyanAccent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "For optimal visual immersion, we recommend using landscape-oriented imagery.",
                            style: GoogleFonts.roboto(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Option 1: System Defaults
                  _SetupOption(
                    title: "System Defaults",
                    subtitle: "Curated high-res landscape visuals.",
                    icon: Icons.rocket_launch_outlined,
                    onTap: () {
                      context
                          .read<AppProvider>()
                          .saveWallpapers(defaultAssets);
                      Navigator.pop(context);
                      onWallpapersSelected(defaultAssets);
                    },
                  ),
                  const SizedBox(height: 8),

                  // Option 2: Custom
                  _SetupOption(
                    title: "Select Custom",
                    subtitle: "Choose 5 images from your gallery.",
                    icon: Icons.photo_library_outlined,
                    isOutlined: true,
                    onTap: () async {
                      final picker = ImagePicker();
                      final images =
                      await picker.pickMultiImage(limit: 5);
                      if (images.length == 5) {
                        final paths =
                        images.map((e) => e.path).toList();
                        if (context.mounted) {
                          context
                              .read<AppProvider>()
                              .saveWallpapers(paths);
                          Navigator.pop(context);
                        }
                        onWallpapersSelected(paths);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isOutlined;

  const _SetupOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding:
        const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isOutlined
              ? Colors.transparent
              : Colors.cyanAccent.withValues(alpha: 0.1),
          border: Border.all(
            color: isOutlined
                ? Colors.white24
                : Colors.cyanAccent.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isOutlined ? Colors.white70 : Colors.cyanAccent,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 12, color: Colors.white30),
          ],
        ),
      ),
    );
  }
}