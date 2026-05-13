import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardHeader extends StatelessWidget {
  final String name;
  final String date;
  final String avatarUrl;
  final VoidCallback onAvatarTap;
  final VoidCallback onBackTap;

  const DashboardHeader({
    super.key,
    required this.name,
    required this.date,
    required this.avatarUrl,
    required this.onAvatarTap,
    required this.onBackTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Avatar & Name
        Row(
          children: [
            GestureDetector(
              onTap: onAvatarTap,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.cyanAccent.withOpacity(0.5),
                    width: 2,
                  ),
                  image: DecorationImage(
                    image: NetworkImage(avatarUrl),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toUpperCase(),
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  date,
                  style: GoogleFonts.orbitron(
                    color: Colors.cyanAccent,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Right: Back button
        GestureDetector(
          onTap: onBackTap,
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(2, 2),
                )
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.keyboard_return,
                color: Colors.cyanAccent,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}