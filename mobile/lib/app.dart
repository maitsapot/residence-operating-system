import 'package:flutter/material.dart';
import 'core/logger/app_logger.dart';
import 'features/tenant/screens/tenant_profile_screen.dart';

class ROSApp extends StatelessWidget {
  const ROSApp({super.key});

  @override
  Widget build(BuildContext context) {
    logger.i("App initialized");

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const TenantProfileScreen(),
    );
  }
}