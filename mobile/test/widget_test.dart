import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ros/app.dart';
import 'package:ros/models/compliance_report.dart';
import 'package:ros/models/common_issue.dart';
import 'package:ros/models/issue.dart';
import 'package:ros/models/residence.dart';
import 'package:ros/models/space.dart';
import 'package:ros/models/space_item.dart';
import 'package:ros/models/tenancy.dart';
import 'package:ros/models/tenant_summary.dart';
import 'package:ros/models/user_profile.dart';
import 'package:ros/services/api_client.dart';

void main() {
  testWidgets('landing screen starts with residence loading state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(ROSApp(apiClient: _PendingApiClient()));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('landing screen renders residences from injected API client', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ROSApp(
        apiClient: _FakeApiClient(
          residences: [
            const Residence(
              id: 'residence-1',
              name: 'Union House',
              companyId: null,
              totalRooms: 12,
              totalCapacity: 24,
              isActive: true,
            ),
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<Residence>));
    await tester.pumpAndSettle();

    expect(find.text('Union House'), findsOneWidget);
  });

  testWidgets('selecting a residence loads tenant choices', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ROSApp(
        apiClient: _FakeApiClient(
          residences: [_unionHouse],
          tenants: [_janeTenant],
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _selectResidence(tester);
    await tester.tap(find.byType(DropdownButton<TenantSummary>));
    await tester.pumpAndSettle();

    expect(find.text('Jane Resident'), findsOneWidget);
  });

  testWidgets('proceeding after tenant selection opens tenant home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ROSApp(
        apiClient: _FakeApiClient(
          residences: [_unionHouse],
          tenants: [_janeTenant],
          userProfile: _janeProfile,
          issues: const [],
        ),
      ),
    );

    await tester.pumpAndSettle();
    await _selectResidence(tester);
    await tester.tap(find.byType(DropdownButton<TenantSummary>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jane Resident').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proceed'));
    await tester.pumpAndSettle();

    expect(find.text('Hello, Jane'), findsOneWidget);
    expect(find.text('Emergency'), findsOneWidget);
  });

  testWidgets('room inventory renders active room space items', (
    WidgetTester tester,
  ) async {
    final apiClient = _FakeApiClient(
      residences: [_unionHouse],
      tenants: [_janeTenant],
      userProfile: _janeProfile,
      tenancies: [_activeTenancy],
      spaces: [_roomSpace],
      spaceItems: _spaceItems,
      commonIssues: [_deskIssue, _mattressIssue],
    );

    await tester.pumpWidget(ROSApp(apiClient: apiClient));

    await tester.pumpAndSettle();
    await _openTenantHome(tester);
    await tester.tap(find.text('My\nRoom'));
    await tester.pumpAndSettle();
    expect(find.text('My Room'), findsOneWidget);
    expect(find.text('A12'), findsOneWidget);
    expect(find.text('Attention Required'), findsOneWidget);

    await tester.ensureVisible(find.text('Room Inventory'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.ancestor(
        of: find.text('Room Inventory'),
        matching: find.byType(InkWell),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Room Inventory'), findsOneWidget);
    expect(find.text('Desk'), findsOneWidget);
    expect(find.text('Last Inspection'), findsWidgets);
    expect(find.text('Item QR Code'), findsWidgets);
    expect(find.text('Raise Issue'), findsWidgets);
    expect(find.text('Attention'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -120));
    await tester.pumpAndSettle();
    await tester.tap(
      find.ancestor(
        of: find.text('Raise Issue').first,
        matching: find.byType(FilledButton),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(apiClient.createdIssueCount, 1);

  });
}

const _unionHouse = Residence(
  id: 'residence-1',
  name: 'Union House',
  companyId: null,
  totalRooms: 12,
  totalCapacity: 24,
  isActive: true,
);

const _janeTenant = TenantSummary(id: 'tenant-1', fullName: 'Jane Resident');

const _janeProfile = UserProfile(
  id: 'tenant-1',
  firstName: 'Jane',
  middleName: null,
  lastName: 'Resident',
  fullName: 'Jane Resident',
  email: 'jane@example.com',
  cellphone: '0712345678',
  isActive: true,
);

const _activeTenancy = Tenancy(
  id: 'tenancy-1',
  startDate: '2026-01-01',
  endDate: null,
  status: 'active',
  userId: 'tenant-1',
  spaceId: 'space-1',
);

const _roomSpace = Space(
  id: 'space-1',
  residenceId: 'residence-1',
  name: 'A12',
  spaceType: 'room',
  templateType: 'single_room',
  standard: 'nsfas',
  isRentable: true,
  capacity: 1,
  floor: 1,
  notes: null,
  isActive: true,
);

final _spaceItems = [
  SpaceItem(
    id: 'space-item-1',
    spaceId: 'space-1',
    itemId: 'item-1',
    itemName: 'Desk',
    qrCode: 'space-item-1',
    lastInspectionId: 'inspection-1',
    lastInspectionAt: DateTime(2026, 5, 1),
    lastInspectionImageUrl: null,
    quantity: 1,
    isRequired: true,
    condition: 'good',
    status: 'active',
  ),
  SpaceItem(
    id: 'space-item-2',
    spaceId: 'space-1',
    itemId: 'item-2',
    itemName: 'Mattress',
    qrCode: 'space-item-2',
    lastInspectionId: null,
    lastInspectionAt: null,
    lastInspectionImageUrl: null,
    quantity: 1,
    isRequired: true,
    condition: 'damaged',
    status: 'active',
  ),
];

const _deskIssue = CommonIssue(
  id: 'common-issue-1',
  itemId: 'item-1',
  issueName: 'Condition Issue',
  defaultSeverity: 'medium',
  defaultUrgency: 'medium',
  isOther: false,
);

const _mattressIssue = CommonIssue(
  id: 'common-issue-2',
  itemId: 'item-2',
  issueName: 'Condition Issue',
  defaultSeverity: 'medium',
  defaultUrgency: 'medium',
  isOther: false,
);

Future<void> _selectResidence(WidgetTester tester) async {
  await tester.tap(find.byType(DropdownButton<Residence>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Union House').last);
  await tester.pumpAndSettle();
}

Future<void> _openTenantHome(WidgetTester tester) async {
  await _selectResidence(tester);
  await tester.tap(find.byType(DropdownButton<TenantSummary>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Jane Resident').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Proceed'));
  await tester.pumpAndSettle();
}

class _PendingApiClient extends _FakeApiClient {
  final Completer<List<Residence>> _residences = Completer<List<Residence>>();

  @override
  Future<List<Residence>> getResidences() {
    return _residences.future;
  }
}

class _FakeApiClient implements ApiClient {
  final List<Residence> residences;
  final List<TenantSummary> tenants;
  final UserProfile? userProfile;
  final List<Issue> issues;
  final List<Tenancy> tenancies;
  final List<Space> spaces;
  final List<SpaceItem> spaceItems;
  final List<CommonIssue> commonIssues;
  int createdIssueCount = 0;

  _FakeApiClient({
    this.residences = const [],
    this.tenants = const [],
    this.userProfile,
    this.issues = const [],
    this.tenancies = const [],
    this.spaces = const [],
    this.spaceItems = const [],
    this.commonIssues = const [],
  });

  @override
  Future<List<Residence>> getResidences() async {
    return residences;
  }

  @override
  Future<List<TenantSummary>> getTenants(String residenceId) async {
    return tenants;
  }

  @override
  Future<List<Space>> getSpacesByResidence(String residenceId) async {
    return spaces.where((space) => space.residenceId == residenceId).toList();
  }

  @override
  Future<List<Tenancy>> getTenancies({
    String? userId,
    String? spaceId,
    String? status,
  }) async {
    return tenancies.where((tenancy) {
      if (userId != null && tenancy.userId != userId) return false;
      if (spaceId != null && tenancy.spaceId != spaceId) return false;
      if (status != null && tenancy.status != status) return false;

      return true;
    }).toList();
  }

  @override
  Future<List<SpaceItem>> getSpaceItemsBySpace(String spaceId) async {
    return spaceItems.where((item) => item.spaceId == spaceId).toList();
  }

  @override
  Future<List<CommonIssue>> getCommonIssuesByItem(String itemId) async {
    return commonIssues.where((issue) => issue.itemId == itemId).toList();
  }

  @override
  Future<Issue> createIssue({
    required String reportedBy,
    required String spaceId,
    required String commonIssueId,
    required String spaceItemId,
    required String description,
    String severity = 'medium',
    String urgency = 'medium',
  }) async {
    createdIssueCount++;

    return Issue(
      id: 'issue-1',
      reportedBy: reportedBy,
      assignedTo: null,
      status: IssueStatus.open,
      severity: severity,
      urgency: urgency,
      description: description,
    );
  }

  @override
  Future<ComplianceReport> getSpaceCompliance(String spaceId) {
    throw UnimplementedError();
  }

  @override
  Future<void> generateIssues({
    required String spaceId,
    required String reportedBy,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> resolveIssues({
    required String spaceId,
    required String updatedBy,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<UserProfile> getUser(String userId) async {
    final profile = userProfile;

    if (profile == null) {
      throw UnimplementedError();
    }

    return profile;
  }

  @override
  Future<List<Issue>> getIssues() async {
    return issues;
  }
}
