import 'package:flutter/material.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../models/residence.dart';
import '../../../models/tenant_summary.dart';
import '../../../services/api_client.dart';

class LandingScreen extends StatefulWidget {
  final ApiClient apiClient;

  const LandingScreen({super.key, required this.apiClient});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  List<Residence> residences = [];
  List<TenantSummary> tenants = [];

  Residence? selectedResidence;
  TenantSummary? selectedTenant;

  bool loadingResidences = true;
  bool loadingTenants = false;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchResidences();
  }

  Future<void> fetchResidences() async {
    logger.i('Fetching residences');

    try {
      final data = await widget.apiClient.getResidences();

      setState(() {
        residences = data;
        loadingResidences = false;
        error = null;
      });
    } catch (e) {
      logger.e('Error fetching residences', error: e);

      setState(() {
        error = 'Failed to load residences';
        loadingResidences = false;
      });
    }
  }

  Future<void> fetchTenants(Residence residence) async {
    logger.i('Fetching tenants for residence: ${residence.id}');

    setState(() {
      selectedResidence = residence;
      loadingTenants = true;
      tenants = [];
      selectedTenant = null;
    });

    try {
      final data = await widget.apiClient.getTenants(residence.id);

      setState(() {
        tenants = data;
        loadingTenants = false;
      });
    } catch (e) {
      logger.e('Error fetching tenants', error: e);

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
                      'Select Residence & Tenant',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButton<Residence>(
                      isExpanded: true,
                      hint: const Text('Choose residence'),
                      value: selectedResidence,
                      items: residences.map<DropdownMenuItem<Residence>>((r) {
                        return DropdownMenuItem(value: r, child: Text(r.name));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          fetchTenants(value);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    loadingTenants
                        ? const CircularProgressIndicator()
                        : DropdownButton<TenantSummary>(
                            isExpanded: true,
                            hint: const Text('Choose tenant'),
                            value: selectedTenant,
                            items: tenants.map<DropdownMenuItem<TenantSummary>>(
                              (t) {
                                return DropdownMenuItem(
                                  value: t,
                                  child: Text(t.fullName),
                                );
                              },
                            ).toList(),
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
                              final residence = selectedResidence;
                              final tenant = selectedTenant;

                              if (residence == null || tenant == null) {
                                return;
                              }

                              Navigator.pushNamed(
                                context,
                                AppRoutes.tenantHome,
                                arguments: TenantHomeRouteArgs(
                                  tenant: tenant,
                                  residence: residence,
                                ),
                              );
                            },
                      child: const Text('Proceed'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
