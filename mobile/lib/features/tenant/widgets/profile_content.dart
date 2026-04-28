import 'package:flutter/material.dart';

/// Dynamic content based on selected tab
Widget buildPanel3(String selectedTab) {
  print("⚪ Rendering Panel 3 for: $selectedTab");

  switch (selectedTab) {
    case "Profile":
      return const Center(child: Text("Profile details here"));
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