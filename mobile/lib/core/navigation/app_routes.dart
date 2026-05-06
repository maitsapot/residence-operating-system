import 'package:flutter/material.dart';

import '../../features/residence/screens/landing_screen.dart';
import '../../features/tenant/screens/tenant_home_screen.dart';
import '../../features/tenant/screens/tenant_profile_screen.dart';
import '../../models/residence.dart';
import '../../models/tenant_summary.dart';
import '../../services/api_client.dart';

class AppRoutes {
  static const landing = '/';
  static const tenantHome = '/tenant/home';
  static const tenantProfile = '/tenant/profile';
}

class TenantHomeRouteArgs {
  final TenantSummary tenant;
  final Residence residence;

  const TenantHomeRouteArgs({required this.tenant, required this.residence});
}

class TenantProfileRouteArgs {
  final TenantSummary tenant;

  const TenantProfileRouteArgs({required this.tenant});
}

class AppRouter {
  final ApiClient apiClient;

  const AppRouter({required this.apiClient});

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.landing:
        return _page(settings, LandingScreen(apiClient: apiClient));
      case AppRoutes.tenantHome:
        final args = settings.arguments as TenantHomeRouteArgs;

        return _page(
          settings,
          TenantHomeScreen(
            apiClient: apiClient,
            tenant: args.tenant,
            residence: args.residence,
          ),
        );
      case AppRoutes.tenantProfile:
        final args = settings.arguments as TenantProfileRouteArgs;

        return _page(
          settings,
          TenantProfileScreen(apiClient: apiClient, tenant: args.tenant),
        );
      default:
        return _page(settings, LandingScreen(apiClient: apiClient));
    }
  }

  MaterialPageRoute<dynamic> _page(RouteSettings settings, Widget child) {
    return MaterialPageRoute(settings: settings, builder: (_) => child);
  }
}
