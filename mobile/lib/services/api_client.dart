import '../models/compliance_report.dart';
import '../models/issue.dart';
import '../models/residence.dart';
import '../models/space.dart';
import '../models/space_item.dart';
import '../models/tenancy.dart';
import '../models/tenant_summary.dart';
import '../models/user_profile.dart';

abstract class ApiClient {
  Future<List<Residence>> getResidences();

  Future<List<TenantSummary>> getTenants(String residenceId);

  Future<List<Space>> getSpacesByResidence(String residenceId);

  Future<List<Tenancy>> getTenancies({
    String? userId,
    String? spaceId,
    String? status,
  });

  Future<List<SpaceItem>> getSpaceItemsBySpace(String spaceId);

  Future<ComplianceReport> getSpaceCompliance(String spaceId);

  Future<void> generateIssues({
    required String spaceId,
    required String reportedBy,
  });

  Future<void> resolveIssues({
    required String spaceId,
    required String updatedBy,
  });

  Future<UserProfile> getUser(String userId);

  Future<List<Issue>> getIssues();
}
