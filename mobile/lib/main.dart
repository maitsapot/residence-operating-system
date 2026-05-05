import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'core/widgets/top_band.dart';
import 'core/widgets/action_card.dart';
import 'core/widgets/hero_menu.dart';
import 'core/widgets/side_panel.dart';
import 'core/widgets/bottom_nav.dart';
import 'services/api_service.dart';

const String mainThemeAsset = "assets/theme/union.png";

final logger = Logger();

void main() {
  logger.i("🚀 ROS Mobile App Starting...");
  runApp(const MyApp());
}

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
/// LANDING SCREEN
/// =====================================================
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

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

  Future<void> fetchResidences() async {
    logger.i("📡 Fetching residences");

    try {
      final data = await ApiService.getResidences();

      setState(() {
        residences = data;
        loadingResidences = false;
        error = null;
      });
    } catch (e) {
      logger.e("❌ Error fetching residences", error: e);

      setState(() {
        error = "Failed to load residences";
        loadingResidences = false;
      });
    }
  }

  Future<void> fetchTenants(String residenceId) async {
    logger.i("📡 Fetching tenants for residence: $residenceId");

    setState(() {
      loadingTenants = true;
      tenants = [];
      selectedTenant = null;
    });

    try {
      final data = await ApiService.getTenants(residenceId);

      setState(() {
        tenants = data;
        loadingTenants = false;
      });
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
                        setState(() {
                          selectedResidence = value;
                        });
                        fetchTenants(value!["id"]);
                      },
                    ),

                    const SizedBox(height: 20),

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
                              setState(() {
                                selectedTenant = value;
                              });
                            },
                          ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: selectedTenant == null
                          ? null
                          : () {
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

/// =====================================================
/// TENANT SCREEN
/// =====================================================
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

  int pendingIssues = 0;
  int activeIssues = 0;
  int resolvedIssues = 0;

  final ScrollController _heroScrollController = ScrollController();

  bool showLeftEllipsis = false;
  bool showRightEllipsis = true;
  bool _isSnapping = false;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
    fetchIssues();

    _heroScrollController.addListener(() {
      final maxScroll = _heroScrollController.position.maxScrollExtent;
      final current = _heroScrollController.offset;

      setState(() {
        showLeftEllipsis = current > 2;
        showRightEllipsis = current < (maxScroll - 2);
      });
    });
  }

  @override
  void dispose() {
    _heroScrollController.dispose();
    super.dispose();
  }

  HeroMenuType? _mapMenu(_HeroMenu? menu) {
    if (menu == null) return null;

    switch (menu) {
      case _HeroMenu.accessControl:
        return HeroMenuType.accessControl;
      case _HeroMenu.myRes:
        return HeroMenuType.myRes;
      case _HeroMenu.myProfile:
        return HeroMenuType.myProfile;
      case _HeroMenu.myContacts:
        return HeroMenuType.myContacts;
      case _HeroMenu.social:
        return HeroMenuType.social;
    }
  }

  _HeroMenu _reverseMap(HeroMenuType menu) {
    switch (menu) {
      case HeroMenuType.accessControl:
        return _HeroMenu.accessControl;
      case HeroMenuType.myRes:
        return _HeroMenu.myRes;
      case HeroMenuType.myProfile:
        return _HeroMenu.myProfile;
      case HeroMenuType.myContacts:
        return _HeroMenu.myContacts;
      case HeroMenuType.social:
        return _HeroMenu.social;
    }
  }

  void _snapHeroMenu() {
    if (_isSnapping) return;

    _isSnapping = true;

    const double tileWidth = 74;
    const double spacing = 6;
    const double fullItemWidth = tileWidth + spacing;

    final currentOffset = _heroScrollController.offset;
    final targetIndex = (currentOffset / fullItemWidth).round();
    final targetOffset = targetIndex * fullItemWidth;

    _heroScrollController
        .animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        )
        .then((_) => _isSnapping = false);
  }

  Future<void> fetchUserProfile() async {
    try {
      final data = await ApiService.getUser(widget.user['id']);

      setState(() {
        userProfile = data;
        loadingProfile = false;
        profileError = null;
      });
    } catch (e) {
      setState(() {
        loadingProfile = false;
        profileError = "Profile unavailable";
      });
    }
  }

  Future<void> fetchIssues() async {
    try {
      final data = await ApiService.getIssues();

      int pending = 0, active = 0, resolved = 0;

      for (var issue in data) {
        final status = issue["status"];

        if (status == "open") pending++;
        if (status == "assigned" || status == "in_progress") active++;
        if (status == "resolved") resolved++;
      }

      setState(() {
        pendingIssues = pending;
        activeIssues = active;
        resolvedIssues = resolved;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SidePanel(onRefresh: fetchUserProfile),
      body: buildHome(),
      bottomNavigationBar: BottomNav(
        onProfile: () {},
        onHome: () {
          setState(() {
            selectedHeroMenu = null; // 👈 THIS RETURNS TO HOME
            selectedHomeDetail = null;
          });
        },
        onSettings: () {},
        onEmergency: () {},
      ),
    );
  }

  Widget buildHome() {
    return SafeArea(
      bottom: false,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          const Positioned.fill(child: ColoredBox(color: Colors.white)),

          /// 🔴 TOP BAND
          TopBand(firstName: _firstName, imageAsset: mainThemeAsset),

          /// ⚪ CONTENT
          Padding(
            padding: const EdgeInsets.only(top: 185),
            child: buildContent(),
          ),

          /// 🟢 HERO MENU (THIS WAS MISSING)
          Positioned(
            top: 135,
            child: HeroMenu(
              selectedMenu: _mapMenu(selectedHeroMenu),
              onSelect: (menu) {
                setState(() {
                  selectedHeroMenu = _reverseMap(menu);
                  selectedHomeDetail = null;
                });
              },
              controller: _heroScrollController,
              showLeftEllipsis: showLeftEllipsis,
              showRightEllipsis: showRightEllipsis,
              onSnap: _snapHeroMenu,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16,
      ), // 👈 creates floating sides
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // 👈 pure white sheet
          borderRadius: BorderRadius.circular(18), // 👈 rounded
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 70, 16, 16),

            // 👆 THIS creates separation from hero menu
            child: selectedHeroMenu == null
                ? buildHomeDashboard()
                : buildActionGrid(),
          ),
        ),
      ),
    );
  }

  Widget buildHomeDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🔴 EMERGENCY
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFD7192F),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Emergency\nI'm in trouble. I need immediate assistance.",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),

        /// 🟢 LIFE COMMENTARY
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            "Response on issue #4587: The leak in the bathroom has been fixed.",
            style: TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget buildActionGrid() {
    final actions = _actionsForSelectedMenu();

    return SingleChildScrollView(
      child: Column(
        children: actions
            .map(
              (action) => Padding(
                padding: const EdgeInsets.only(
                  bottom: 14,
                ), // 👈 slightly tighter spacing
                child: ActionCard(
                  label: action.label,
                  subtitle: action.subtitle,
                  icon: action.icon,
                  pendingIssues: pendingIssues,
                  activeIssues: activeIssues,
                  resolvedIssues: resolvedIssues,
                  onTap: () {
                    if (action.detail != null) {
                      setState(() {
                        selectedHomeDetail = action.detail;
                      });
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${action.label} coming soon")),
                    );
                  },
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  List<_HomeAction> _actionsForSelectedMenu() {
    switch (selectedHeroMenu) {
      case _HeroMenu.accessControl:
        return [
          _HomeAction("Access Code", "View entry code", Icons.pin_outlined),
          _HomeAction("Visitors", "Manage guests", Icons.badge_outlined),
          _HomeAction(
            "Revoke Access",
            "Remove permissions",
            Icons.block_rounded,
          ),
          _HomeAction("Request Access", "Ask for entry", Icons.key_rounded),
          _HomeAction("Access Logs", "View history", Icons.history_outlined),
          _HomeAction("Permissions", "Manage access rules", Icons.lock_outline),
        ];

      case _HeroMenu.myRes:
        return [
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
        ];

      case _HeroMenu.myProfile:
        return [
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
          _HomeAction(
            "Academics",
            "View school details",
            Icons.school_outlined,
          ),
          _HomeAction(
            "Documents",
            "View uploaded files",
            Icons.folder_open_outlined,
          ),
          _HomeAction(
            "Settings",
            "Manage preferences",
            Icons.settings_outlined,
          ),
        ];

      case _HeroMenu.myContacts:
        return [
          _HomeAction(
            "Contacts",
            "View your contacts",
            Icons.contacts_outlined,
          ),
          _HomeAction(
            "Caretakers",
            "Residence caretakers",
            Icons.support_agent_outlined,
          ),
          _HomeAction(
            "Management",
            "Residence management",
            Icons.business_outlined,
          ),
          _HomeAction("Security", "Security contacts", Icons.shield_outlined),
          _HomeAction("Emergency", "Emergency numbers", Icons.call_outlined),
          _HomeAction(
            "Directory",
            "Full contact directory",
            Icons.list_alt_outlined,
          ),
        ];

      case _HeroMenu.social:
        return [
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
          _HomeAction("Groups", "Join communities", Icons.groups_outlined),
          _HomeAction("Explore", "Discover activity", Icons.explore_outlined),
        ];

      default:
        return [
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
        ];
    }
  }

  String get _firstName {
    return widget.user["full_name"].toString().split(" ").first;
  }
}

class _HomeAction {
  final String label;
  final String subtitle;
  final IconData icon;
  final _HomeDetail? detail;

  _HomeAction(this.label, this.subtitle, this.icon, {this.detail});
}

enum _TenantSection { home, profile }

enum _HomeDetail { profile }

enum _HeroMenu { accessControl, myRes, myProfile, myContacts, social }
