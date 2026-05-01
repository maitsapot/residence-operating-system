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
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  /// ================= API CALL =================
  /// Fetch full user details
  Future<void> fetchUserProfile() async {
    logger.i("📡 Fetching user profile");

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/users/${widget.user['id']}"),
      );

      logger.d("Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        setState(() {
          userProfile = jsonDecode(response.body);
          loading = false;
        });
      } else {
        throw Exception("Failed to load user");
      }
    } catch (e) {
      logger.e("❌ Error fetching user", error: e);
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    logger.i("🟢 TenantScreen build");

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      drawer: buildSidePanel(context),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : userProfile == null
          ? const Center(child: Text("Failed to load profile"))
          : buildHome(),
      bottomNavigationBar: buildBottomNav(),
    );
  }

  Widget buildHome() {
    final residenceName = widget.residence["name"] ?? "your residence";

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            buildTopBand(),
            Padding(
              padding: const EdgeInsets.only(top: 170),
              child: buildContentSheet(residenceName),
            ),
            Positioned(top: 92, child: buildInitialsAvatar()),
          ],
        ),
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

  Widget buildInitialsAvatar() {
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

  Widget buildContentSheet(String residenceName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 72, 24, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(44),
          topRight: Radius.circular(44),
        ),
      ),
      child: Column(
        children: [
          Text(
            "Hello, $_firstName",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFC6283B),
              fontSize: 34,
              fontWeight: FontWeight.w300,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "You are a tenant at $residenceName",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF555555),
              fontSize: 17,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 28),
          buildActionGrid(),
          const SizedBox(height: 28),
          buildEmergencyButton(),
        ],
      ),
    );
  }

  Widget buildActionGrid() {
    final actions = [
      _HomeAction("Access Control", Icons.lock_outline_rounded),
      _HomeAction("My Profile", Icons.account_circle_outlined),
      _HomeAction("My Room", Icons.bed_outlined),
      _HomeAction("Notifications", Icons.notifications_none_rounded),
      _HomeAction("Issues", Icons.warning_amber_rounded),
      _HomeAction("Reserve Space", Icons.event_seat_outlined),
      _HomeAction("Events", Icons.calendar_month_outlined),
      _HomeAction("Chats", Icons.chat_bubble_outline_rounded),
      _HomeAction("My Res", Icons.home_work_outlined),
      _HomeAction("Contacts", Icons.contacts_outlined),
      _HomeAction("Partners", Icons.people_outline_rounded),
      _HomeAction("Facilities", Icons.directions_bike_outlined),
      _HomeAction("Buy & Rent", Icons.apartment_rounded),
      _HomeAction("Utilities", Icons.crop_portrait_rounded),
      _HomeAction("Directory", Icons.contact_page_outlined),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        childAspectRatio: 1.42,
      ),
      itemBuilder: (context, index) => buildActionCard(actions[index]),
    );
  }

  Widget buildActionCard(_HomeAction action) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("${action.label} coming soon")));
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.13),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(action.icon, color: const Color(0xFFC51F32), size: 37),
            const SizedBox(height: 8),
            Text(
              action.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF474747),
                fontSize: 18,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
                height: 1.08,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEmergencyButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Emergency flow coming soon")),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFFF1738),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.sos_rounded, color: Colors.white, size: 40),
            SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Emergency",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    "I need immediate assistance",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
            buildDrawerItem(Icons.refresh_rounded, "Refresh"),
            buildDrawerItem(Icons.info_outline_rounded, "Need Help?"),
            buildDrawerItem(Icons.logout_rounded, "Log Out"),
          ],
        ),
      ),
    );
  }

  Widget buildDrawerItem(IconData icon, String label) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
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
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFFC51F32),
      unselectedItemColor: Colors.black,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      currentIndex: 2,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.sos_outlined, size: 32),
          label: "Emergency",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.lock_outline_rounded, size: 32),
          label: "Access",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined, size: 34),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded, size: 34),
          label: "Profile",
        ),
        BottomNavigationBarItem(
          icon: Badge(
            label: Text("22"),
            child: Icon(Icons.mail_outline_rounded, size: 34),
          ),
          label: "Chats",
        ),
      ],
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
  const _HomeAction(this.label, this.icon);

  final String label;
  final IconData icon;
}
