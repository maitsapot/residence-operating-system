import 'package:flutter/material.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/widgets/master_profile_layout.dart';
import '../../../models/tenant_summary.dart';
import '../../../models/user_profile.dart';
import '../../../services/api_client.dart';
import '../widgets/profile_actions.dart';
import '../widgets/profile_content.dart';

/// StatefulWidget = screen with changing state
/// Think: Activity with mutable UI

class TenantProfileScreen extends StatefulWidget {
  final ApiClient apiClient;
  final TenantSummary tenant;

  const TenantProfileScreen({
    super.key,
    required this.apiClient,
    required this.tenant,
  });

  @override
  State<TenantProfileScreen> createState() => _TenantProfileScreenState();
}

class _TenantProfileScreenState extends State<TenantProfileScreen> {
  String selectedTab = "Profile";
  UserProfile? profile;
  bool loadingProfile = true;
  String? profileError;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      final data = await widget.apiClient.getUser(widget.tenant.id);

      if (!mounted) return;

      setState(() {
        profile = data;
        loadingProfile = false;
        profileError = null;
      });
    } catch (e) {
      logger.e("Failed to load tenant profile", error: e);

      if (!mounted) return;

      setState(() {
        loadingProfile = false;
        profileError = "Profile unavailable";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    logger.i("Building TenantProfileScreen, tab = $selectedTab");

    if (loadingProfile) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (profileError != null || profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profile")),
        body: Center(child: Text(profileError ?? "Profile unavailable")),
      );
    }

    final user = profile!;

    return MasterProfileLayout(
      title: user.fullName,
      subtitle: _subtitleFor(user),
      imageUrl: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e",
      panel2: buildPanel2((tab) {
        logger.i("Updating selectedTab to: $tab");

        setState(() {
          selectedTab = tab;
        });
      }),
      panel3: buildPanel3(selectedTab, user),
    );
  }

  String _subtitleFor(UserProfile user) {
    if (user.email != null && user.email!.isNotEmpty) {
      return "Tenant • ${user.email}";
    }

    if (user.cellphone.isNotEmpty) {
      return "Tenant • ${user.cellphone}";
    }

    return "Tenant";
  }
}
