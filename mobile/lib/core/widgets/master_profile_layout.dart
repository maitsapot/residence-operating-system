import 'package:flutter/material.dart';
import '../logger/app_logger.dart';
import '../theme/app_colors.dart';

/// MASTER LAYOUT (3 PANELS)
/// Panel 1 → Profile header
/// Panel 2 → Navigation
/// Panel 3 → Content

class MasterProfileLayout extends StatelessWidget {
  /// final = immutable (like Java final fields)
  final String title;
  final String subtitle;
  final String imageUrl;

  final Widget panel2;
  final Widget panel3;

  /// Constructor injection (like Java constructor)
  const MasterProfileLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.panel2,
    required this.panel3,
  });

  @override
  Widget build(BuildContext context) {
    logger.i("Building MasterProfileLayout for $title");

    return Scaffold(
      backgroundColor: AppColors.background,

///the vertical container
      body: Column(
        children: [

          /// ================= PANEL 1 =================
          /// Profile header with background + avatar
          Stack(
            children: [

              /// Background image
              Container(
                height: 220,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              /// Overlay for readability
              Container(
                height: 220,
                color: Colors.black.withOpacity(0.3),
              ),

              /// Profile info
              Positioned(
                bottom: 20,
                left: 20,
                child: Row(
                  children: [

                    /// Avatar
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 36,
                        backgroundImage: NetworkImage(imageUrl),
                      ),
                    ),

                    const SizedBox(width: 12),

                    /// Name + subtitle
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),

          /// ================= PANEL 2 =================
          Container(
            height: 80,
            color: AppColors.secondary,
            child: panel2,
          ),

          /// ================= PANEL 3 =================
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: panel3,
            ),
          )
        ],
      ),
    );
  }
}