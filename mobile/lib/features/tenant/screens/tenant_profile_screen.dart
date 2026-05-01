import 'package:flutter/material.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/widgets/master_profile_layout.dart';
import '../widgets/profile_actions.dart';
import '../widgets/profile_content.dart';

/// StatefulWidget = screen with changing state
/// Think: Activity with mutable UI

class TenantProfileScreen extends StatefulWidget {
  const TenantProfileScreen({super.key});

  @override
  State<TenantProfileScreen> createState() => _TenantProfileScreenState();
}

class _TenantProfileScreenState extends State<TenantProfileScreen> {
  /// State variable (like a field in Java class)
  String selectedTab = "Profile";

  @override
  Widget build(BuildContext context) {
    logger.i("Building TenantProfileScreen, tab = $selectedTab");

    return MasterProfileLayout(
      title: "John Doe",
      subtitle: "Tenant • Room A12",

      /// Profile image (temporary)
      imageUrl: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e",

      /// PANEL 2
      panel2: buildPanel2((tab) {
        logger.i("Updating selectedTab to: $tab");

        /// setState = triggers UI re-render (like notify UI thread)
        setState(() {
          selectedTab = tab;
        });
      }),

      /// PANEL 3
      panel3: buildPanel3(selectedTab),
    );
  }
}
