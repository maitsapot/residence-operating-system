import 'package:flutter/material.dart';
import '../../../core/logger/app_logger.dart';
import '../../../models/user_profile.dart';

/// Dynamic content based on selected tab
Widget buildPanel3(String selectedTab, UserProfile profile) {
  logger.i("Rendering Panel 3 for: $selectedTab");

  switch (selectedTab) {
    case "Profile":
      return _ProfileDetails(profile: profile);
    case "Spaces":
      return const Center(child: Text("Spaces list here"));
    case "Items":
      return const Center(child: Text("Items list here"));
    case "Issues":
      return const Center(child: Text("Issues list here"));
    default:
      return const Center(child: Text("Select a section"));
  }
}

class _ProfileDetails extends StatelessWidget {
  final UserProfile profile;

  const _ProfileDetails({required this.profile});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _ProfileField(label: "Full name", value: profile.fullName),
        _ProfileField(label: "First name", value: profile.firstName),
        if (profile.middleName != null && profile.middleName!.isNotEmpty)
          _ProfileField(label: "Middle name", value: profile.middleName!),
        _ProfileField(label: "Last name", value: profile.lastName),
        if (profile.email != null && profile.email!.isNotEmpty)
          _ProfileField(label: "Email", value: profile.email!),
        _ProfileField(label: "Cellphone", value: profile.cellphone),
        _ProfileField(
          label: "Status",
          value: profile.isActive ? "Active" : "Inactive",
        ),
      ],
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? "Not provided" : value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
