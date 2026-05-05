import 'package:flutter/material.dart';

enum HeroMenuType { accessControl, myRes, myProfile, myContacts, social }

class HeroMenu extends StatelessWidget {
  final HeroMenuType? selectedMenu;
  final Function(HeroMenuType) onSelect;

  final ScrollController controller;
  final bool showLeftEllipsis;
  final bool showRightEllipsis;
  final VoidCallback onSnap;

  const HeroMenu({
    super.key,
    required this.selectedMenu,
    required this.onSelect,
    required this.controller,
    required this.showLeftEllipsis,
    required this.showRightEllipsis,
    required this.onSnap,
  });

  @override
  Widget build(BuildContext context) {
    const double tileWidth = 74;
    const double spacing = 6;
    const int visibleTiles = 4;

    final items = [
      _Item(
        "Access\nControl",
        Icons.lock_outline_rounded,
        HeroMenuType.accessControl,
      ),
      _Item("My Residence", Icons.home_work_outlined, HeroMenuType.myRes),
      _Item(
        "My\nProfile",
        Icons.account_circle_outlined,
        HeroMenuType.myProfile,
      ),
      _Item("My\nContacts", Icons.contacts_outlined, HeroMenuType.myContacts),
      _Item("Social\nSpace", Icons.groups_2_outlined, HeroMenuType.social),
    ];

    final double viewportWidth =
        (tileWidth * visibleTiles) + (spacing * visibleTiles);

    return SizedBox(
      width: viewportWidth,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          ClipRect(
            child: NotificationListener<ScrollEndNotification>(
              onNotification: (notification) {
                onSnap();
                return true;
              },
              child: SingleChildScrollView(
                controller: controller,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: items.map((item) {
                    final isSelected = selectedMenu == item.type;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: SizedBox(
                        width: tileWidth,
                        height: 92,
                        child: Column(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => onSelect(item.type),
                              child: Container(
                                height: 82,
                                padding: EdgeInsets.all(isSelected ? 4 : 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(
                                    alpha: isSelected ? 0.38 : 0.25,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF6AA84F)
                                        : Colors.white,
                                    width: isSelected ? 2.2 : 1.1,
                                  ),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD7192F),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          item.icon,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.label,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),

                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: isSelected ? 34 : 0,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD7192F),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          if (showLeftEllipsis)
            const Positioned(
              left: 2,
              child: Text(
                "…",
                style: TextStyle(fontSize: 22, color: Color(0xFFB0B0B0)),
              ),
            ),

          if (showRightEllipsis)
            const Positioned(
              right: 2,
              child: Text(
                "…",
                style: TextStyle(fontSize: 22, color: Color(0xFFB0B0B0)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Item {
  final String label;
  final IconData icon;
  final HeroMenuType type;

  _Item(this.label, this.icon, this.type);
}
