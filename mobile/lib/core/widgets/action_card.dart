import 'package:flutter/material.dart';

class ActionCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;

  final int pendingIssues;
  final int activeIssues;
  final int resolvedIssues;

  final VoidCallback onTap;

  const ActionCard({
    super.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.pendingIssues,
    required this.activeIssues,
    required this.resolvedIssues,
  });

  Color _getAccentColor(String label) {
    switch (label) {
      /// 🏠 MY RESIDENCE
      case "My Room":
        return const Color(0xFF4F6EF7);
      case "Inspections":
        return const Color(0xFF22C55E);
      case "Maintenance":
        return const Color(0xFFF59E0B);
      case "Reservations":
        return const Color(0xFF3B82F6);
      case "Issues":
        return const Color(0xFFEF4444);
      case "My Items":
        return const Color(0xFF6366F1);

      /// 🔐 ACCESS CONTROL
      case "Access Code":
        return const Color(0xFF6366F1);
      case "Visitors":
        return const Color(0xFF10B981);
      case "Revoke Access":
        return const Color(0xFFEF4444);
      case "Request Access":
        return const Color(0xFFF59E0B);
      case "Access Logs":
        return const Color(0xFF6B7280);
      case "Permissions":
        return const Color(0xFF3B82F6);

      /// 👤 PROFILE
      case "Me":
        return const Color(0xFF4F46E5);
      case "Guardian":
        return const Color(0xFF0EA5E9);
      case "Emergency Contact":
        return const Color(0xFFEF4444);
      case "Academics":
        return const Color(0xFF22C55E);
      case "Documents":
        return const Color(0xFF8B5CF6);
      case "Settings":
        return const Color(0xFF6B7280);

      /// 📞 CONTACTS
      case "Contacts":
        return const Color(0xFF3B82F6);
      case "Caretakers":
        return const Color(0xFF10B981);
      case "Management":
        return const Color(0xFF6366F1);
      case "Security":
        return const Color(0xFFEF4444);
      case "Emergency":
        return const Color(0xFFDC2626);
      case "Directory":
        return const Color(0xFF6B7280);

      /// 🌐 SOCIAL
      case "Chat":
        return const Color(0xFF3B82F6);
      case "Notifications":
        return const Color(0xFFF59E0B);
      case "Events":
        return const Color(0xFF22C55E);
      case "Post":
        return const Color(0xFF8B5CF6);
      case "Groups":
        return const Color(0xFF6366F1);
      case "Explore":
        return const Color(0xFF0EA5E9);

      default:
        return const Color(0xFF9CA3AF);
    }
  }

  Widget _buildIndicator(String text) {
    Color bgColor;
    Color textColor;

    if (text.contains("pending")) {
      bgColor = const Color(0xFFFFF4E5);
      textColor = const Color(0xFFE65100);
    } else if (text.contains("new")) {
      bgColor = const Color(0xFFE8F5E9);
      textColor = const Color(0xFF2E7D32);
    } else if (text.contains("active")) {
      bgColor = const Color(0xFFEAF4FF);
      textColor = const Color(0xFF007AFF);
    } else {
      bgColor = const Color(0xFFEDEDED);
      textColor = const Color(0xFF555555);
    }

    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = _getAccentColor(label);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ), // 👈 reduced height
        decoration: BoxDecoration(
          color: Colors.white, // 👈 PURE WHITE CARD
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            /// LEFT COLOR STRIP
            Container(
              width: 3, // 👈 slightly thinner
              height: 48, // 👈 reduced height
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            const SizedBox(width: 12),

            /// ICON BOX
            Container(
              width: 42, // 👈 smaller
              height: 42,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 22), // 👈 smaller icon
            ),

            const SizedBox(width: 12),

            /// TEXT + INDICATORS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // 👈 important (reduces height)
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14.5, // 👈 slightly reduced
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      if (label == "Visitors") _buildIndicator("3 active"),

                      if (label == "Issues")
                        _buildIndicator(
                          pendingIssues > 0
                              ? "$pendingIssues pending"
                              : activeIssues > 0
                              ? "$activeIssues active"
                              : resolvedIssues > 0
                              ? "$resolvedIssues done"
                              : "No issues",
                        ),

                      if (label == "Notifications") _buildIndicator("5 new"),
                    ],
                  ),

                  const SizedBox(height: 2), // 👈 tighter spacing

                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 11.5, // 👈 slightly reduced
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),

            /// ARROW
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9CA3AF),
              size: 20, // 👈 smaller
            ),
          ],
        ),
      ),
    );
  }
}
