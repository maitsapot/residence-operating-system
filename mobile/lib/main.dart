import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

/// ================= LOGGER =================
/// Used instead of print() for structured logs
final logger = Logger();

/// ================= CONFIG =================
/// Your FastAPI endpoint
const String baseUrl = "http://4.222.235.174:8000";

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
      final response =
          await http.get(Uri.parse("$baseUrl/residences/"));

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
                              fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 20),

                        /// ================= DROPDOWN 1 =================
                        /// RESIDENCE
                        DropdownButton<Map>(
                          isExpanded: true,
                          hint: const Text("Choose residence"),
                          value: selectedResidence,
                          items: residences
                              .map<DropdownMenuItem<Map>>((r) {
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
                                items: tenants
                                    .map<DropdownMenuItem<Map>>((t) {
                                  return DropdownMenuItem(
                                    value: t,
                                    child: Text(t["full_name"]),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  logger.i("Selected tenant: ${value?['full_name']}");

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
/// 📍 TENANT SCREEN (@Me + tabs)
/// - Receives selected user (id + full_name)
/// - Calls /users/{id}
/// - Displays full profile
/// =====================================================
class TenantScreen extends StatefulWidget {
  final Map user;

  /// Constructor injection (like Java constructor)
  const TenantScreen({super.key, required this.user});

  @override
  State<TenantScreen> createState() => _TenantScreenState();
}

class _TenantScreenState extends State<TenantScreen> {
  Map? userProfile;
  bool loading = true;

  /// Tabs (panel 2)
  final List<String> tabs = [
    "@Me",
    "Chat",
    "Contacts",
    "My Res",
    "My Space",
    "My Items",
    "Issues",
  ];

  String selectedTab = "@Me";

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
      body: Column(
        children: [
          buildHeader(),
          buildActions(),
          Expanded(child: buildContent()),
        ],
      ),
    );
  }

  /// ================= PANEL 1 =================
  /// Header with user name
  Widget buildHeader() {
    return Container(
      height: 200,
      color: Colors.blue,
      child: Center(
        child: Text(
          widget.user['full_name'],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// ================= PANEL 2 =================
  /// Horizontal tabs
  Widget buildActions() {
    return Container(
      height: 80,
      color: Colors.orange,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: tabs.map((tab) => buildTab(tab)).toList(),
      ),
    );
  }

  Widget buildTab(String label) {
    return GestureDetector(
      onTap: () {
        logger.i("Tab: $label");

        setState(() {
          selectedTab = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        child: Text(label,
            style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  /// ================= PANEL 3 =================
  /// Dynamic content
  Widget buildContent() {
    if (selectedTab == "@Me") {
      if (loading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (userProfile == null) {
        return const Center(child: Text("Failed to load profile"));
      }

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Name
            Text(
              "${userProfile!['first_name']} ${userProfile!['last_name']}",
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            /// Core details
            Text("Email: ${userProfile!['email'] ?? ''}"),
            Text("Cellphone: ${userProfile!['cellphone'] ?? ''}"),

            const SizedBox(height: 20),

            /// Additional
            Text("Gender: ${userProfile!['gender'] ?? ''}"),
            Text("Race: ${userProfile!['race'] ?? ''}"),
          ],
        ),
      );
    }

    /// Default other tabs
    return Center(child: Text("$selectedTab content"));
  }
}