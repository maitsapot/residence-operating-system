import 'package:flutter/material.dart';

import 'core/navigation/app_routes.dart';
import 'services/api_client.dart';
import 'services/api_service.dart';

class ROSApp extends StatelessWidget {
  final ApiClient? apiClient;

  const ROSApp({super.key, this.apiClient});

  @override
  Widget build(BuildContext context) {
    final client = apiClient ?? ApiService.shared;
    final router = AppRouter(apiClient: client);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.landing,
      onGenerateRoute: router.onGenerateRoute,
    );
  }
}

@Deprecated('Use ROSApp instead.')
class MyApp extends ROSApp {
  const MyApp({super.key, super.apiClient});
}
