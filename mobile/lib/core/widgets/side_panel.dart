import 'package:flutter/material.dart';

class SidePanel extends StatelessWidget {
  final VoidCallback onRefresh;

  const SidePanel({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.60,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 44),

            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                padding: const EdgeInsets.only(left: 28),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFFC51F32),
                  size: 38,
                ),
              ),
            ),

            const SizedBox(height: 70),

            _item(context, Icons.swap_horiz_rounded, "Switch Residence"),
            _item(context, Icons.refresh_rounded, "Refresh", onTap: onRefresh),
            _item(context, Icons.info_outline_rounded, "Need Help?"),
            _item(context, Icons.logout_rounded, "Log Out"),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        if (onTap != null) {
          onTap();
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("$label coming soon")));
        }
      },
      child: Container(
        height: 96,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFEAEAEA))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF5B9B43), size: 30),
            const SizedBox(width: 28),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF4C4C4C),
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
