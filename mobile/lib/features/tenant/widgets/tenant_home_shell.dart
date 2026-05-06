import 'package:flutter/material.dart';

import '../../../core/config/app_assets.dart';
import '../../../core/widgets/hero_menu.dart';
import '../../../core/widgets/top_band.dart';
import 'tenant_home_content_sheet.dart';

class TenantHomeShell extends StatelessWidget {
  final String firstName;
  final Widget child;
  final HeroMenuType? selectedHeroMenu;
  final ValueChanged<HeroMenuType> onHeroMenuSelected;
  final ScrollController heroScrollController;
  final bool showLeftEllipsis;
  final bool showRightEllipsis;
  final VoidCallback onHeroMenuSnap;

  const TenantHomeShell({
    super.key,
    required this.firstName,
    required this.child,
    required this.selectedHeroMenu,
    required this.onHeroMenuSelected,
    required this.heroScrollController,
    required this.showLeftEllipsis,
    required this.showRightEllipsis,
    required this.onHeroMenuSnap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          const Positioned.fill(child: ColoredBox(color: Colors.white)),
          TopBand(firstName: firstName, imageAsset: AppAssets.mainTheme),
          Padding(
            padding: const EdgeInsets.only(top: 185),
            child: TenantHomeContentSheet(child: child),
          ),
          Positioned(
            top: 135,
            child: HeroMenu(
              selectedMenu: selectedHeroMenu,
              onSelect: onHeroMenuSelected,
              controller: heroScrollController,
              showLeftEllipsis: showLeftEllipsis,
              showRightEllipsis: showRightEllipsis,
              onSnap: onHeroMenuSnap,
            ),
          ),
        ],
      ),
    );
  }
}
