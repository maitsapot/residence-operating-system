import 'package:flutter/material.dart';

/// Panel 2 builder (action navigation)
Widget buildPanel2(Function(String) onSelect) {
  print("🟠 Building Panel 2 (navigation)");

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _icon("Profile", Icons.person, onSelect),
      _icon("Spaces", Icons.home, onSelect),
      _icon("Items", Icons.chair, onSelect),
      _icon("Issues", Icons.warning, onSelect),
    ],
  );
}

/// Helper method for icons
Widget _icon(String label, IconData icon, Function(String) onSelect) {
  return GestureDetector(
    onTap: () {
      print("👉 Clicked: $label");
      onSelect(label);
    },
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.white))
      ],
    ),
  );
}