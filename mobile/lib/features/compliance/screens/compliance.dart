import 'package:flutter/material.dart';

import '../../../models/compliance_report.dart';
import '../../../models/residence.dart';
import '../../../models/space.dart';
import '../../../services/api_client.dart';
import '../../../services/api_service.dart';

class ComplianceScreen extends StatefulWidget {
  final ApiClient? apiClient;

  const ComplianceScreen({super.key, this.apiClient});

  @override
  State<ComplianceScreen> createState() => _ComplianceScreenState();
}

class _ComplianceScreenState extends State<ComplianceScreen> {
  static const String _systemUserId = '1e1a5f74-cefc-4e80-a5ea-b4c6eec65dbf';

  List<Residence> residences = [];
  List<Space> spaces = [];

  Residence? selectedResidence;
  Space? selectedSpace;

  ComplianceReport? compliance;

  ApiClient get _apiClient {
    return widget.apiClient ?? ApiService.shared;
  }

  @override
  void initState() {
    super.initState();
    fetchResidences();
  }

  // =============================
  // FETCH RESIDENCES
  // =============================
  Future<void> fetchResidences() async {
    final data = await _apiClient.getResidences();

    setState(() {
      residences = data;
    });
  }

  // =============================
  // FETCH SPACES
  // =============================
  Future<void> fetchSpaces(Residence residence) async {
    final data = await _apiClient.getSpacesByResidence(residence.id);

    setState(() {
      selectedResidence = residence;
      spaces = data.where((space) => space.isRoom).toList();
    });
  }

  // =============================
  // FETCH COMPLIANCE
  // =============================
  Future<void> fetchCompliance() async {
    if (selectedSpace == null) return;

    final data = await _apiClient.getSpaceCompliance(selectedSpace!.id);

    setState(() {
      compliance = data;
    });
  }

  // =============================
  // GENERATE ISSUES
  // =============================
  Future<void> generateIssues() async {
    if (selectedSpace == null) return;

    await _apiClient.generateIssues(
      spaceId: selectedSpace!.id,
      reportedBy: _systemUserId,
    );

    fetchCompliance();
  }

  // =============================
  // RESOLVE ISSUES
  // =============================
  Future<void> resolveIssues() async {
    if (selectedSpace == null) return;

    await _apiClient.resolveIssues(
      spaceId: selectedSpace!.id,
      updatedBy: _systemUserId,
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
            DropdownButtonFormField<Residence>(
              hint: const Text("Select Residence"),
              initialValue: selectedResidence,
              items: residences
                  .map<DropdownMenuItem<Residence>>(
                    (r) => DropdownMenuItem(value: r, child: Text(r.name)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedResidence = value;
                  selectedSpace = null;
                  compliance = null;
                });
                if (value != null) {
                  fetchSpaces(value);
                }
              },
            ),

            const SizedBox(height: 16),

            // =============================
            // SPACE DROPDOWN
            // =============================
            DropdownButtonFormField<Space>(
              hint: const Text("Select Room"),
              initialValue: selectedSpace,
              items: spaces
                  .map<DropdownMenuItem<Space>>(
                    (s) => DropdownMenuItem(value: s, child: Text(s.name)),
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
                "Score: ${compliance!.score.compliancePercentage}%",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text("Bad Items:"),
              ...compliance!.badItems.map(
                (item) => Text("- ${item.itemName} (${item.condition})"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
