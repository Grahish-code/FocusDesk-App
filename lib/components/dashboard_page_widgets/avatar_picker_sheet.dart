import 'package:focusdesk/providers/app_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';



class AvatarPickerSheet {
  static final List<String> _avatars = [
    "https://api.dicebear.com/9.x/lorelei/png?seed=Leo",
    "https://api.dicebear.com/9.x/lorelei/png?seed=Mia",
    "https://api.dicebear.com/9.x/lorelei/png?seed=Max",
    "https://api.dicebear.com/9.x/lorelei/png?seed=Zoe",
    "https://api.dicebear.com/9.x/lorelei/png?seed=Kai",
    "https://api.dicebear.com/9.x/lorelei/png?seed=Ava",
    "https://api.dicebear.com/9.x/lorelei/png?seed=Sasha",
    "https://api.dicebear.com/9.x/lorelei/png?seed=Bella",
    "https://api.dicebear.com/9.x/lorelei/png?seed=Luna",
    "https://api.dicebear.com/9.x/lorelei/png?seed=Zara",
    "https://api.dicebear.com/9.x/lorelei/png?seed=Mila",
    "https://api.dicebear.com/9.x/lorelei/png?seed=Coco",
    "https://api.dicebear.com/9.x/lorelei/png?seed=Annie",
    "https://api.dicebear.com/9.x/lorelei/png?seed=Maya",
  ];

  static void show(BuildContext context) {
    final currentUrl =
        Provider.of<AppProvider>(context, listen: false).avatarUrl;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        String tempSelectedUrl = currentUrl;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Container(
              height: 500,
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F0F).withOpacity(0.95),
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border(
                  top: BorderSide(
                    color: Colors.cyanAccent.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.1),
                    blurRadius: 40,
                  )
                ],
              ),
              padding:
              const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              child: Column(
                children: [
                  // Title
                  Text(
                    "IDENTITY SYNCHRONIZATION",
                    style: GoogleFonts.orbitron(
                      color: Colors.cyanAccent,
                      fontSize: 12,
                      letterSpacing: 4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const Spacer(),

                  // Holo preview
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.cyanAccent.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withOpacity(0.15),
                              blurRadius: 30,
                              spreadRadius: 10,
                            )
                          ],
                        ),
                      ),
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.cyanAccent.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                      ),
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.black12,
                        backgroundImage: NetworkImage(tempSelectedUrl),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Text(
                    "SELECTED PROFILE",
                    style: GoogleFonts.orbitron(
                      color: Colors.white38,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),

                  const Spacer(),

                  // Avatar carousel
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _avatars.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final url = _avatars[index];
                        final isSelected = tempSelectedUrl == url;

                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => tempSelectedUrl = url),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin:
                            const EdgeInsets.symmetric(horizontal: 10),
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                  color: Colors.cyanAccent, width: 2)
                                  : Border.all(
                                  color: Colors.white12, width: 1),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: Colors.cyanAccent
                                      .withOpacity(0.4),
                                  blurRadius: 10,
                                )
                              ]
                                  : [],
                            ),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white10,
                              backgroundImage: NetworkImage(url),
                              child: isSelected
                                  ? null
                                  : Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                  Colors.black.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        Provider.of<AppProvider>(context, listen: false)
                            .updateAvatar(tempSelectedUrl);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 10,
                        shadowColor: Colors.cyanAccent.withOpacity(0.4),
                      ),
                      child: Text(
                        "INITIALIZE",
                        style: GoogleFonts.orbitron(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}