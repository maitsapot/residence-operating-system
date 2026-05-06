import 'package:flutter/material.dart';

import '../../../core/widgets/bottom_nav.dart';
import '../../../core/widgets/hero_menu.dart';
import '../../../core/widgets/side_panel.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../models/issue.dart';
import '../../../models/residence.dart';
import '../../../models/space_item.dart';
import '../../../models/tenant_summary.dart';
import '../../../services/api_client.dart';
import '../models/room_summary.dart';
import '../models/tenant_home_action.dart';
import '../models/tenant_issue_counts.dart';
import '../widgets/room_summary_card.dart';
import '../widgets/room_inventory_view.dart';
import '../widgets/tenant_action_list.dart';
import '../widgets/tenant_home_dashboard.dart';
import '../widgets/tenant_home_shell.dart';

class TenantHomeScreen extends StatefulWidget {
  final ApiClient apiClient;
  final TenantSummary tenant;
  final Residence residence;

  const TenantHomeScreen({
    super.key,
    required this.apiClient,
    required this.tenant,
    required this.residence,
  });

  @override
  State<TenantHomeScreen> createState() => _TenantHomeScreenState();
}

class _TenantHomeScreenState extends State<TenantHomeScreen> {
  HeroMenuType? selectedHeroMenu;
  _TenantHomeDetail? selectedDetail;

  TenantIssueCounts issueCounts = TenantIssueCounts.empty;
  RoomSummary? roomSummary;
  List<SpaceItem> roomInventory = [];
  bool loadingRoomSummary = false;
  bool loadingRoomInventory = false;
  String? roomSummaryError;
  String? roomInventoryError;

  final ScrollController _heroScrollController = ScrollController();

  bool showLeftEllipsis = false;
  bool showRightEllipsis = true;
  bool _isSnapping = false;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
    fetchIssues();

    _heroScrollController.addListener(_updateHeroOverflowIndicators);
  }

  @override
  void dispose() {
    _heroScrollController.removeListener(_updateHeroOverflowIndicators);
    _heroScrollController.dispose();
    super.dispose();
  }

  void _updateHeroOverflowIndicators() {
    final maxScroll = _heroScrollController.position.maxScrollExtent;
    final current = _heroScrollController.offset;

    setState(() {
      showLeftEllipsis = current > 2;
      showRightEllipsis = current < (maxScroll - 2);
    });
  }

  void _snapHeroMenu() {
    if (_isSnapping) return;

    _isSnapping = true;

    const double tileWidth = 74;
    const double spacing = 6;
    const double fullItemWidth = tileWidth + spacing;

    final currentOffset = _heroScrollController.offset;
    final targetIndex = (currentOffset / fullItemWidth).round();
    final targetOffset = targetIndex * fullItemWidth;

    _heroScrollController
        .animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        )
        .then((_) => _isSnapping = false);
  }

  Future<void> fetchUserProfile() async {
    try {
      await widget.apiClient.getUser(widget.tenant.id);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile unavailable')));
    }
  }

  Future<void> fetchIssues() async {
    try {
      final data = await widget.apiClient.getIssues();

      int pending = 0;
      int active = 0;
      int resolved = 0;

      for (final issue in data) {
        if (issue.status == IssueStatus.open) pending++;
        if (issue.status == IssueStatus.assigned ||
            issue.status == IssueStatus.inProgress) {
          active++;
        }
        if (issue.status == IssueStatus.resolved) resolved++;
      }

      if (!mounted) return;

      setState(() {
        issueCounts = TenantIssueCounts(
          pending: pending,
          active: active,
          resolved: resolved,
        );
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SidePanel(onRefresh: fetchUserProfile),
      body: TenantHomeShell(
        firstName: widget.tenant.firstName,
        selectedHeroMenu: selectedHeroMenu,
        onHeroMenuSelected: (menu) {
          setState(() {
            selectedHeroMenu = menu;
            selectedDetail = null;
          });

          if (menu == HeroMenuType.myRoom) {
            _loadRoomSummary();
          }
        },
        heroScrollController: _heroScrollController,
        showLeftEllipsis: showLeftEllipsis,
        showRightEllipsis: showRightEllipsis,
        onHeroMenuSnap: _snapHeroMenu,
        child: _buildTenantHomeContent(),
      ),
      bottomNavigationBar: BottomNav(
        onProfile: _openProfile,
        onHome: () {
          setState(() {
            selectedHeroMenu = null;
            selectedDetail = null;
          });
        },
        onSettings: () {},
        onEmergency: () {},
      ),
    );
  }

  Widget _buildTenantHomeContent() {
    if (selectedDetail == _TenantHomeDetail.roomInventory) {
      if (loadingRoomInventory) {
        return const Center(child: CircularProgressIndicator());
      }

      if (roomInventoryError != null) {
        return _DetailError(
          message: roomInventoryError!,
          onBack: _closeDetail,
          onRetry: _openRoomInventory,
        );
      }

      return RoomInventoryView(items: roomInventory, onBack: _closeDetail);
    }

    if (selectedHeroMenu == null) {
      return const TenantHomeDashboard();
    }

    return TenantActionList(
      actions: actionsForTenantHomeMenu(selectedHeroMenu),
      issueCounts: issueCounts,
      header: selectedHeroMenu == HeroMenuType.myRoom
          ? RoomSummaryCard(
              summary: roomSummary,
              loading: loadingRoomSummary,
              error: roomSummaryError,
              onRetry: _loadRoomSummary,
            )
          : null,
      onActionTap: _handleActionTap,
    );
  }

  void _handleActionTap(TenantHomeAction action) {
    if (action.destination == TenantHomeActionDestination.roomInventory) {
      _openRoomInventory();
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${action.label} coming soon')));
  }

  Future<void> _openRoomInventory() async {
    setState(() {
      selectedDetail = _TenantHomeDetail.roomInventory;
      loadingRoomInventory = true;
      roomInventoryError = null;
    });

    try {
      final summary = await _fetchRoomSummary();

      if (!mounted) return;

      setState(() {
        roomSummary = summary;
        roomInventory = summary.items;
        loadingRoomInventory = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        roomInventory = [];
        loadingRoomInventory = false;
        roomInventoryError = 'Room inventory unavailable';
      });
    }
  }

  Future<void> _loadRoomSummary() async {
    if (loadingRoomSummary) return;

    setState(() {
      loadingRoomSummary = true;
      roomSummaryError = null;
    });

    try {
      final summary = await _fetchRoomSummary();

      if (!mounted) return;

      setState(() {
        roomSummary = summary;
        roomInventory = summary.items;
        loadingRoomSummary = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        roomSummary = null;
        roomInventory = [];
        loadingRoomSummary = false;
        roomSummaryError = 'Room summary unavailable';
      });
    }
  }

  Future<RoomSummary> _fetchRoomSummary() async {
    final tenancies = await widget.apiClient.getTenancies(
      userId: widget.tenant.id,
      status: 'active',
    );

    if (tenancies.isEmpty) {
      throw Exception('No active room assignment found');
    }

    final activeTenancy = tenancies.first;
    final spaces = await widget.apiClient.getSpacesByResidence(
      widget.residence.id,
    );
    String? roomName;
    for (final space in spaces) {
      if (space.id == activeTenancy.spaceId) {
        roomName = space.name;
        break;
      }
    }
    final items = await widget.apiClient.getSpaceItemsBySpace(
      activeTenancy.spaceId,
    );

    return RoomSummary(name: roomName ?? 'My Room', items: items);
  }

  void _closeDetail() {
    setState(() {
      selectedDetail = null;
    });
  }

  void _openProfile() {
    Navigator.pushNamed(
      context,
      AppRoutes.tenantProfile,
      arguments: TenantProfileRouteArgs(tenant: widget.tenant),
    );
  }
}

enum _TenantHomeDetail { roomInventory }

class _DetailError extends StatelessWidget {
  final String message;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  const _DetailError({
    required this.message,
    required this.onBack,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(onPressed: onBack, child: const Text('Back')),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ],
      ),
    );
  }
}
