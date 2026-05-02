import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

const String mainThemeAsset = "assets/theme/union.png";
const String sidePanelReferenceAsset = "assets/theme/panel.png";

/// ================= LOGGER =================
/// Used instead of print() for structured logs
final logger = Logger();

/// ================= CONFIG =================
/// Your FastAPI endpoint
const String baseUrl = "http://20.164.20.15:8000/api/v1";

void main() {
  logger.i("🚀 ROS Mobile App Starting...");
  runApp(const MyApp());
}

/// ================= ROOT APP =================
/// Entry point widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LandingScreen(),
    );
  }
}

/// =====================================================
/// 📍 LANDING SCREEN
/// - Calls /users/fullname
/// - Displays dropdown
/// - Select user → navigate to TenantScreen
/// =====================================================
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

// ONLY THIS CLASS CHANGED ↓↓↓

class _LandingScreenState extends State<LandingScreen> {
  List residences = [];
  List tenants = [];

  Map? selectedResidence;
  Map? selectedTenant;

  bool loadingResidences = true;
  bool loadingTenants = false;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchResidences();
  }

  /// ================= API CALL 1 =================
  /// GET residences
  Future<void> fetchResidences() async {
    logger.i("📡 Fetching residences");

    try {
      final response = await http.get(Uri.parse("$baseUrl/residences/"));

      if (response.statusCode == 200) {
        setState(() {
          residences = jsonDecode(response.body);
          loadingResidences = false;
        });
      } else {
        throw Exception("Failed to load residences");
      }
    } catch (e) {
      logger.e("❌ Error fetching residences", error: e);

      setState(() {
        error = "Failed to load residences";
        loadingResidences = false;
      });
    }
  }

  /// ================= API CALL 2 =================
  /// GET tenants by residence
  Future<void> fetchTenants(String residenceId) async {
    logger.i("📡 Fetching tenants for residence: $residenceId");

    setState(() {
      loadingTenants = true;
      tenants = [];
      selectedTenant = null;
    });

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/tenants/by-residence/$residenceId"),
      );

      if (response.statusCode == 200) {
        setState(() {
          tenants = jsonDecode(response.body);
          loadingTenants = false;
        });
      } else {
        throw Exception("Failed to load tenants");
      }
    } catch (e) {
      logger.e("❌ Error fetching tenants", error: e);

      setState(() {
        loadingTenants = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: loadingResidences
            ? const CircularProgressIndicator()
            : error != null
            ? Text(error!)
            : Container(
                width: 300,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Select Residence & Tenant",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// ================= DROPDOWN 1 =================
                    /// RESIDENCE
                    DropdownButton<Map>(
                      isExpanded: true,
                      hint: const Text("Choose residence"),
                      value: selectedResidence,
                      items: residences.map<DropdownMenuItem<Map>>((r) {
                        return DropdownMenuItem(
                          value: r,
                          child: Text(r["name"]),
                        );
                      }).toList(),
                      onChanged: (value) {
                        logger.i("Selected residence: ${value?['name']}");

                        setState(() {
                          selectedResidence = value;
                        });

                        fetchTenants(value!["id"]);
                      },
                    ),

                    const SizedBox(height: 20),

                    /// ================= DROPDOWN 2 =================
                    /// TENANTS
                    loadingTenants
                        ? const CircularProgressIndicator()
                        : DropdownButton<Map>(
                            isExpanded: true,
                            hint: const Text("Choose tenant"),
                            value: selectedTenant,
                            items: tenants.map<DropdownMenuItem<Map>>((t) {
                              return DropdownMenuItem(
                                value: t,
                                child: Text(t["full_name"]),
                              );
                            }).toList(),
                            onChanged: (value) {
                              logger.i(
                                "Selected tenant: ${value?['full_name']}",
                              );

                              setState(() {
                                selectedTenant = value;
                              });
                            },
                          ),

                    const SizedBox(height: 20),

                    /// ================= BUTTON =================
                    ElevatedButton(
                      onPressed: selectedTenant == null
                          ? null
                          : () {
                              logger.i("➡️ Proceed");

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TenantScreen(
                                    user: selectedTenant!,
                                    residence: selectedResidence!,
                                  ),
                                ),
                              );
                            },
                      child: const Text("Proceed"),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class TenantScreen extends StatefulWidget {
  final Map user;
  final Map residence;

  const TenantScreen({super.key, required this.user, required this.residence});

  @override
  State<TenantScreen> createState() => _TenantScreenState();
}

class _TenantScreenState extends State<TenantScreen> {
  Map? userProfile;
  bool loadingProfile = true;
  String? profileError;
  _TenantSection selectedSection = _TenantSection.home;
  _HeroMenu? selectedHeroMenu;
  _HomeDetail? selectedHomeDetail;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  /// ================= API CALL =================
  /// Fetch full user details
  Future<void> fetchUserProfile() async {
    final userId = widget.user['id'];
    final profileUrl = "$baseUrl/users/$userId";

    logger.i("📡 Fetching user profile: $profileUrl");

    try {
      final response = await http
          .get(Uri.parse(profileUrl))
          .timeout(const Duration(seconds: 8));

      logger.d("Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        setState(() {
          userProfile = jsonDecode(response.body);
          loadingProfile = false;
          profileError = null;
        });
      } else {
        throw Exception("Failed to load user: ${response.statusCode}");
      }
    } catch (e) {
      logger.e("❌ Error fetching user", error: e);
      setState(() {
        loadingProfile = false;
        profileError = "Profile details unavailable";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    logger.i("🟢 TenantScreen build");

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      drawer: buildSidePanel(context),
      body: selectedSection == _TenantSection.profile
          ? buildProfile()
          : buildHome(),
      bottomNavigationBar: buildBottomNav(),
    );
  }

  Widget buildHome() {
    final residenceName = widget.residence["name"] ?? "your residence";

    return SafeArea(
      bottom: false,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          const Positioned.fill(child: ColoredBox(color: Colors.black)),
          buildTopBand(),
          Padding(
            padding: const EdgeInsets.only(top: 218),
            child: buildContentSheet(residenceName),
          ),
          Positioned(top: 166, child: buildHeroMenu()),
        ],
      ),
    );
  }

  Widget buildContentSheet(String residenceName) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 78, 24, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(44),
          topRight: Radius.circular(44),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 18),
        child: buildContentSheetBody(residenceName),
      ),
    );
  }

  Widget buildTopBand() {
    return SizedBox(
      height: 245,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: Image.asset(
              mainThemeAsset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.05)),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 22, 28, 0),
            child: Align(
              alignment: Alignment.topLeft,
              child: Builder(
                builder: (context) => IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildHeroMenu() {
    final items = [
      _HeroMenuItem(
        "Access\nControl",
        Icons.lock_outline_rounded,
        _HeroMenu.accessControl,
      ),
      _HeroMenuItem("My Res", Icons.home_work_outlined, _HeroMenu.myRes),
      _HeroMenuItem(
        "My\nProfile",
        Icons.account_circle_outlined,
        _HeroMenu.myProfile,
      ),
      _HeroMenuItem("Social\nSpace", Icons.groups_2_outlined, _HeroMenu.social),
    ];

    return SizedBox(
      width: MediaQuery.of(context).size.width - 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: SizedBox(
                  width: 74,
                  height: 92,
                  child: Column(
                    children: [
                      SizedBox(height: 82, child: buildHeroMenuTile(item)),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        width: selectedHeroMenu == item.menu ? 34 : 0,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD7192F),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget buildHeroMenuTile(_HeroMenuItem item) {
    final isSelected = selectedHeroMenu == item.menu;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        setState(() {
          selectedHeroMenu = item.menu;
          selectedHomeDetail = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.all(isSelected ? 4 : 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isSelected ? 0.38 : 0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF6AA84F) : Colors.white,
            width: isSelected ? 2.2 : 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.28 : 0.18),
              blurRadius: isSelected ? 18 : 14,
              offset: Offset(0, isSelected ? 10 : 8),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFD7192F),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, color: Colors.white, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        height: 1.02,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Positioned(
                  right: 7,
                  top: 7,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6AA84F),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildContentSheetBody(String residenceName) {
    return Column(
      children: [
        if (selectedHeroMenu == null && selectedHomeDetail == null) ...[
          Text(
            "Hello, $_firstName",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFC6283B),
              fontSize: 29,
              fontWeight: FontWeight.w300,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            residenceName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF555555),
              fontSize: 14.5,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 28),
        ],
        buildHomePanelContent(residenceName),
      ],
    );
  }

  Widget buildHomePanelContent(String residenceName) {
    if (selectedHomeDetail == _HomeDetail.profile) {
      return buildInlineProfileDetails(residenceName);
    }
    if (selectedHeroMenu == null) {
      return buildAdPlaceholder(residenceName);
    }
    return buildActionGrid();
  }

  Widget buildAdPlaceholder(String residenceName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.campaign_outlined, color: Color(0xFFC51F32), size: 26),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Residence updates",
                  style: TextStyle(
                    color: Color(0xFF343434),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "This area is reserved for notices, services, partner offers, and useful updates for $residenceName.",
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.28,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildActionGrid() {
    final actions = _actionsForSelectedMenu();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.15,
      ),
      itemBuilder: (context, index) => buildActionCard(actions[index]),
    );
  }

  List<_HomeAction> _actionsForSelectedMenu() {
    return switch (selectedHeroMenu!) {
      _HeroMenu.accessControl => [
        _HomeAction("Access Code", "View entry code", Icons.pin_outlined),
        _HomeAction("Visitors", "Manage guests", Icons.badge_outlined),
        _HomeAction("Revoke Access", "Remove permissions", Icons.block_rounded),
        _HomeAction("Request Access", "Ask for entry", Icons.key_rounded),
      ],
      _HeroMenu.myRes => [
        _HomeAction("My Room", "View room details", Icons.bed_outlined),
        _HomeAction(
          "Inspections",
          "View inspection history",
          Icons.fact_check_outlined,
        ),
        _HomeAction(
          "Maintenance",
          "Submit & track requests",
          Icons.handyman_outlined,
        ),
        _HomeAction(
          "Reservations",
          "Manage facilities",
          Icons.event_seat_outlined,
        ),
        _HomeAction(
          "Issues",
          "Report & follow up",
          Icons.warning_amber_rounded,
        ),
        _HomeAction("My Items", "Track my items", Icons.inventory_2_outlined),
      ],
      _HeroMenu.myProfile => [
        _HomeAction(
          "Me",
          "View profile details",
          Icons.account_circle_outlined,
          detail: _HomeDetail.profile,
        ),
        _HomeAction(
          "Guardian",
          "View guardian details",
          Icons.supervisor_account_outlined,
        ),
        _HomeAction(
          "Emergency Contact",
          "View emergency details",
          Icons.contact_emergency_outlined,
        ),
        _HomeAction("Academics", "View school details", Icons.school_outlined),
      ],
      _HeroMenu.social => [
        _HomeAction(
          "Chat",
          "Open conversations",
          Icons.chat_bubble_outline_rounded,
        ),
        _HomeAction(
          "Notifications",
          "View latest alerts",
          Icons.notifications_none_rounded,
        ),
        _HomeAction("Events", "Browse events", Icons.calendar_month_outlined),
        _HomeAction("Post", "Share an update", Icons.post_add_outlined),
      ],
    };
  }

  Widget buildActionCard(_HomeAction action) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        if (action.detail != null) {
          setState(() {
            selectedHomeDetail = action.detail;
          });
          return;
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("${action.label} coming soon")));
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 9, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: const Color(0xFFC51F32), size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.label,
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF252525),
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    action.subtitle,
                    textAlign: TextAlign.left,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF5E5E5E),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF8A8A8A),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInlineProfileDetails(String residenceName) {
    return Column(
      children: [
        if (loadingProfile) ...[
          const LinearProgressIndicator(color: Color(0xFFC51F32), minHeight: 3),
          const SizedBox(height: 14),
        ],
        buildProfileRow(Icons.badge_outlined, "Name", _displayName),
        buildProfileRow(Icons.home_work_outlined, "Residence", residenceName),
        buildProfileRow(
          Icons.mail_outline_rounded,
          "Email",
          _profileValue("email"),
        ),
        buildProfileRow(
          Icons.phone_outlined,
          "Cellphone",
          _profileValue("cellphone"),
        ),
        if (profileError != null) ...[
          const SizedBox(height: 8),
          Text(
            profileError!,
            style: const TextStyle(
              color: Color(0xFFC51F32),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ],
      ],
    );
  }

  Widget buildSidePanel(BuildContext context) {
    precacheImage(const AssetImage(sidePanelReferenceAsset), context);

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
            buildDrawerItem(Icons.swap_horiz_rounded, "Switch Residence"),
            buildDrawerItem(
              Icons.refresh_rounded,
              "Refresh",
              onTap: fetchUserProfile,
            ),
            buildDrawerItem(Icons.info_outline_rounded, "Need Help?"),
            buildDrawerItem(Icons.logout_rounded, "Log Out"),
          ],
        ),
      ),
    );
  }

  Widget buildDrawerItem(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        if (onTap != null) {
          onTap();
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("$label coming soon")));
      },
      child: Container(
        height: 96,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFEAEAEA))),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF5B9B43), size: 34),
            const SizedBox(width: 28),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF4C4C4C),
                  fontSize: 25,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBottomNav() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        child: SizedBox(
          height: 72,
          child: Column(
            children: [
              Container(height: 1, color: const Color(0xFFE6E6E6)),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildBottomNavItem(
                      icon: Icons.person_outline_rounded,
                      label: "My Profile",
                      color: const Color(0xFF2F2F2F),
                      onPressed: () {
                        setState(() {
                          selectedSection = _TenantSection.home;
                          selectedHeroMenu = _HeroMenu.myProfile;
                          selectedHomeDetail = _HomeDetail.profile;
                        });
                      },
                    ),
                    buildBottomNavItem(
                      icon: Icons.home_outlined,
                      label: "Home",
                      color: const Color(0xFFC51F32),
                      onPressed: () {
                        setState(() {
                          selectedSection = _TenantSection.home;
                          selectedHeroMenu = null;
                          selectedHomeDetail = null;
                        });
                      },
                    ),
                    buildBottomNavItem(
                      icon: Icons.settings_outlined,
                      label: "Settings",
                      color: const Color(0xFF2F2F2F),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Settings coming soon")),
                        );
                      },
                    ),
                    buildBottomNavItem(
                      emoji: "🚨",
                      label: "Emergency",
                      color: const Color(0xFFFF1738),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Emergency flow coming soon"),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildBottomNavItem({
    IconData? icon,
    String? emoji,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onPressed,
      child: SizedBox(
        width: 82,
        height: 62,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (emoji != null)
              Text(emoji, style: const TextStyle(fontSize: 27, height: 1))
            else
              Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProfile() {
    final residenceName = widget.residence["name"] ?? "your residence";

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: buildProfileHeader()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (loadingProfile) ...[
                  const LinearProgressIndicator(
                    color: Color(0xFFC51F32),
                    minHeight: 3,
                  ),
                  const SizedBox(height: 18),
                ],
                buildProfileRow(Icons.badge_outlined, "Name", _displayName),
                buildProfileRow(
                  Icons.home_work_outlined,
                  "Residence",
                  residenceName,
                ),
                buildProfileRow(
                  Icons.mail_outline_rounded,
                  "Email",
                  _profileValue("email"),
                ),
                buildProfileRow(
                  Icons.phone_outlined,
                  "Cellphone",
                  _profileValue("cellphone"),
                ),
                if (profileError != null) ...[
                  const SizedBox(height: 18),
                  Text(
                    profileError!,
                    style: const TextStyle(
                      color: Color(0xFFC51F32),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProfileHeader() {
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            mainThemeAsset,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          Container(color: Colors.black.withValues(alpha: 0.08)),
          Positioned(
            top: 18,
            left: 16,
            child: Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildProfileAvatar(),
                const SizedBox(height: 16),
                Text(
                  _displayName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 31,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProfileAvatar() {
    return Container(
      width: 124,
      height: 124,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFD7192F),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          _initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }

  Widget buildProfileRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 9,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFC51F32), size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF6D6D6D),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF2F2F2F),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _firstName {
    final firstName = userProfile?["first_name"]?.toString();
    if (firstName != null &&
        firstName.trim().isNotEmpty &&
        !_isSeedName(firstName)) {
      return firstName.trim();
    }

    final fullName = widget.user["full_name"]?.toString() ?? "Tenant";
    return _cleanDisplayName(fullName).split(RegExp(r"\s+")).first;
  }

  String get _displayName {
    final fullName = userProfile?["full_name"]?.toString();
    if (fullName != null && fullName.trim().isNotEmpty) {
      return _cleanDisplayName(fullName);
    }

    return _cleanDisplayName(widget.user["full_name"]?.toString() ?? "Tenant");
  }

  String _profileValue(String key) {
    final value = userProfile?[key]?.toString().trim();
    if (value == null || value.isEmpty) {
      return "-";
    }
    return value;
  }

  String get _initials {
    final firstName = userProfile?["first_name"]?.toString() ?? "";
    final lastName = userProfile?["last_name"]?.toString() ?? "";

    final initials = [
      if (firstName.trim().isNotEmpty && !_isSeedName(firstName))
        firstName.trim()[0],
      if (lastName.trim().isNotEmpty && !_isSeedName(lastName))
        lastName.trim()[0],
    ].join().toUpperCase();

    if (initials.isNotEmpty) {
      return initials;
    }

    final fullName = widget.user["full_name"]?.toString() ?? "Tenant";
    return _cleanDisplayName(fullName)
        .split(RegExp(r"\s+"))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
  }

  String _cleanDisplayName(String fullName) {
    final visibleParts = fullName
        .trim()
        .split(RegExp(r"\s+"))
        .where((part) => part.isNotEmpty && !_isSeedName(part))
        .toList();

    return visibleParts.isEmpty ? "Tenant" : visibleParts.join(" ");
  }

  bool _isSeedName(String value) {
    return RegExp(r"^seed\d+$", caseSensitive: false).hasMatch(value.trim());
  }
}

class _HomeAction {
  const _HomeAction(this.label, this.subtitle, this.icon, {this.detail});

  final String label;
  final String subtitle;
  final IconData icon;
  final _HomeDetail? detail;
}

class _HeroMenuItem {
  const _HeroMenuItem(this.label, this.icon, this.menu);

  final String label;
  final IconData icon;
  final _HeroMenu menu;
}

enum _TenantSection { home, profile }

enum _HomeDetail { profile }

enum _HeroMenu { accessControl, myRes, myProfile, social }
