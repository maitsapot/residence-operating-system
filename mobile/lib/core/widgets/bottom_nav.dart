import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final VoidCallback onProfile;
  final VoidCallback onHome;
  final VoidCallback onSettings;
  final VoidCallback onEmergency;

  const BottomNav({
    super.key,
    required this.onProfile,
    required this.onHome,
    required this.onSettings,
    required this.onEmergency,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      elevation: 8,
      child: SizedBox(
        height: 56,
        child: Column(
          children: [
            Container(height: 1, color: const Color(0xFFE6E6E6)),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _item(Icons.person_outline_rounded, "My Profile", onProfile),
                  _item(Icons.home_outlined, "Home", onHome),
                  _item(Icons.settings_outlined, "Settings", onSettings),
                  _emoji("🚨", "Emergency", onEmergency),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 78,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF2F2F2F), size: 22),
            const SizedBox(height: 1),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emoji(String emoji, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 78,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 1),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
