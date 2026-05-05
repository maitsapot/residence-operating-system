import 'package:flutter/material.dart';

class TopBand extends StatelessWidget {
  final String firstName;
  final String imageAsset;

  const TopBand({super.key, required this.firstName, required this.imageAsset});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: Image.asset(
              imageAsset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),

          /// subtle overlay
          Container(color: Colors.black.withValues(alpha: 0.05)),

          /// TOP LEFT HEADER (menu + greeting)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 22, 28, 0),
            child: Align(
              alignment: Alignment.topLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  /// MENU BUTTON
                  Builder(
                    builder: (context) => IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  /// HELLO TEXT
                  Text(
                    "Hello, $firstName",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
