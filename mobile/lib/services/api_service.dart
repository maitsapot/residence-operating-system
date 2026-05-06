import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/compliance_report.dart';
import '../models/common_issue.dart';
import '../models/issue.dart';
import '../models/residence.dart';
import '../models/space.dart';
import '../models/space_item.dart';
import '../models/tenancy.dart';
import '../models/tenant_summary.dart';
import '../models/user_profile.dart';
import 'api_client.dart';

const String baseUrl = "http://20.164.20.15:8000/api/v1";

class ApiService implements ApiClient {
  static final ApiService shared = ApiService();

  final http.Client _client;
  final String apiBaseUrl;

  ApiService({http.Client? client, this.apiBaseUrl = baseUrl})
    : _client = client ?? http.Client();

  @override
  Future<List<Residence>> getResidences() async {
    final res = await _client.get(Uri.parse("$apiBaseUrl/residences/"));

    if (res.statusCode == 200) {
      return _decodeList(res.body, Residence.fromJson);
    } else {
      throw Exception("Failed to load residences");
    }
  }

  @override
  Future<List<TenantSummary>> getTenants(String residenceId) async {
    final res = await _client.get(
      Uri.parse("$apiBaseUrl/tenants/by-residence/$residenceId"),
    );

    if (res.statusCode == 200) {
      return _decodeList(res.body, TenantSummary.fromJson);
    } else {
      throw Exception("Failed to load tenants");
    }
  }

  @override
  Future<List<Space>> getSpacesByResidence(String residenceId) async {
    final res = await _client.get(
      Uri.parse("$apiBaseUrl/spaces/residence/$residenceId"),
    );

    if (res.statusCode == 200) {
      return _decodeList(res.body, Space.fromJson);
    } else {
      throw Exception("Failed to load spaces");
    }
  }

  @override
  Future<List<Tenancy>> getTenancies({
    String? userId,
    String? spaceId,
    String? status,
  }) async {
    final params = <String, String>{};

    if (userId != null) params['user_id'] = userId;
    if (spaceId != null) params['space_id'] = spaceId;
    if (status != null) params['status'] = status;

    final uri = Uri.parse(
      "$apiBaseUrl/tenancies/",
    ).replace(queryParameters: params.isEmpty ? null : params);

    final res = await _client.get(uri);

    if (res.statusCode == 200) {
      return _decodeList(res.body, Tenancy.fromJson);
    } else {
      throw Exception("Failed to load tenancies");
    }
  }

  @override
  Future<List<SpaceItem>> getSpaceItemsBySpace(String spaceId) async {
    final res = await _client.get(
      Uri.parse("$apiBaseUrl/space-items/by-space/$spaceId"),
    );

    if (res.statusCode == 200) {
      return _decodeList(res.body, SpaceItem.fromJson);
    } else {
      throw Exception("Failed to load space inventory");
    }
  }

  @override
  Future<List<CommonIssue>> getCommonIssuesByItem(String itemId) async {
    final res = await _client.get(
      Uri.parse("$apiBaseUrl/common-issues/$itemId"),
    );

    if (res.statusCode == 200) {
      return _decodeList(res.body, CommonIssue.fromJson);
    } else {
      throw Exception("Failed to load item issue options");
    }
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
    final res = await _client.post(
      Uri.parse("$apiBaseUrl/issues/"),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'reported_by': reportedBy,
        'space_id': spaceId,
        'common_issue_id': commonIssueId,
        'space_item_id': spaceItemId,
        'description': description,
        'severity': severity,
        'urgency': urgency,
      }),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return Issue.fromJson(jsonDecode(res.body));
    } else {
      throw Exception("Failed to create issue");
    }
  }

  @override
  Future<ComplianceReport> getSpaceCompliance(String spaceId) async {
    final res = await _client.get(
      Uri.parse("$apiBaseUrl/spaces/$spaceId/compliance"),
    );

    if (res.statusCode == 200) {
      return ComplianceReport.fromJson(jsonDecode(res.body));
    } else {
      throw Exception("Failed to load space compliance");
    }
  }

  @override
  Future<void> generateIssues({
    required String spaceId,
    required String reportedBy,
  }) async {
    final res = await _client.post(
      Uri.parse(
        "$apiBaseUrl/spaces/$spaceId/generate-issues?reported_by=$reportedBy",
      ),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Failed to generate issues");
    }
  }

  @override
  Future<void> resolveIssues({
    required String spaceId,
    required String updatedBy,
  }) async {
    final res = await _client.post(
      Uri.parse(
        "$apiBaseUrl/spaces/$spaceId/resolve-issues?updated_by=$updatedBy",
      ),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Failed to resolve issues");
    }
  }

  @override
  Future<UserProfile> getUser(String userId) async {
    final res = await _client.get(Uri.parse("$apiBaseUrl/users/$userId"));

    if (res.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(res.body));
    } else {
      throw Exception("Failed to load user");
    }
  }

  @override
  Future<List<Issue>> getIssues() async {
    final res = await _client.get(Uri.parse("$apiBaseUrl/issues?limit=100"));

    if (res.statusCode == 200) {
      return _decodeList(res.body, Issue.fromJson);
    } else {
      throw Exception("Failed to load issues");
    }
  }

  static List<T> _decodeList<T>(
    String responseBody,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final decoded = jsonDecode(responseBody) as List<dynamic>;

    return decoded
        .map((item) => fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
