import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ComplianceScreen extends StatefulWidget {
  const ComplianceScreen({super.key});

  @override
  State<ComplianceScreen> createState() => _ComplianceScreenState();
}

class _ComplianceScreenState extends State<ComplianceScreen> {
  final String baseUrl = "http://4.222.235.174:8000/api/v1";

  List residences = [];
  List spaces = [];

  String? selectedResidence;
  String? selectedSpace;

  Map<String, dynamic>? compliance;

  @override
  void initState() {
    super.initState();
    fetchResidences();
  }

  // =============================
  // FETCH RESIDENCES
  // =============================
  Future<void> fetchResidences() async {
    final res = await http.get(Uri.parse("$baseUrl/residences"));
    if (res.statusCode == 200) {
      setState(() {
        residences = jsonDecode(res.body);
      });
    }
  }

  // =============================
  // FETCH SPACES
  // =============================
  Future<void> fetchSpaces(String residenceId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/spaces/residence/$residenceId"),
    );

    if (res.statusCode == 200) {
      setState(() {
        spaces = jsonDecode(
          res.body,
        ).where((s) => s['space_type'] == 'room').toList();
      });
    }
  }

  // =============================
  // FETCH COMPLIANCE
  // =============================
  Future<void> fetchCompliance() async {
    if (selectedSpace == null) return;

    final res = await http.get(
      Uri.parse("$baseUrl/spaces/$selectedSpace/compliance"),
    );

    if (res.statusCode == 200) {
      setState(() {
        compliance = jsonDecode(res.body);
      });
    }
  }

  // =============================
  // GENERATE ISSUES
  // =============================
  Future<void> generateIssues() async {
    if (selectedSpace == null) return;

    await http.post(
      Uri.parse(
        "$baseUrl/spaces/$selectedSpace/generate-issues?reported_by=1e1a5f74-cefc-4e80-a5ea-b4c6eec65dbf",
      ),
    );

    fetchCompliance();
  }

  // =============================
  // RESOLVE ISSUES
  // =============================
  Future<void> resolveIssues() async {
    if (selectedSpace == null) return;

    await http.post(
      Uri.parse(
        "$baseUrl/spaces/$selectedSpace/resolve-issues?updated_by=1e1a5f74-cefc-4e80-a5ea-b4c6eec65dbf",
      ),
    );

    fetchCompliance();
  }

  // =============================
  // UI
  // =============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Room Compliance")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // =============================
            // RESIDENCE DROPDOWN
            // =============================
            DropdownButtonFormField<String>(
              hint: const Text("Select Residence"),
              initialValue: selectedResidence,
              items: residences
                  .map<DropdownMenuItem<String>>(
                    (r) => DropdownMenuItem(
                      value: r['id'],
                      child: Text(r['name']),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedResidence = value;
                  selectedSpace = null;
                  compliance = null;
                });
                fetchSpaces(value!);
              },
            ),

            const SizedBox(height: 16),

            // =============================
            // SPACE DROPDOWN
            // =============================
            DropdownButtonFormField<String>(
              hint: const Text("Select Room"),
              initialValue: selectedSpace,
              items: spaces
                  .map<DropdownMenuItem<String>>(
                    (s) => DropdownMenuItem(
                      value: s['id'],
                      child: Text(s['name']),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedSpace = value;
                });
                fetchCompliance();
              },
            ),

            const SizedBox(height: 20),

            // =============================
            // BUTTONS
            // =============================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: generateIssues,
                  child: const Text("Generate Issues"),
                ),
                ElevatedButton(
                  onPressed: resolveIssues,
                  child: const Text("Resolve Issues"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // =============================
            // COMPLIANCE DISPLAY
            // =============================
            if (compliance != null) ...[
              Text(
                "Score: ${compliance!['score']['compliance_percentage']}%",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text("Bad Items:"),
              ...List.from(compliance!['bad_items'] ?? []).map(
                (item) => Text("- ${item['item_name']} (${item['condition']})"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
