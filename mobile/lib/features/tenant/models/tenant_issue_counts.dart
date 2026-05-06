class TenantIssueCounts {
  final int pending;
  final int active;
  final int resolved;

  const TenantIssueCounts({
    required this.pending,
    required this.active,
    required this.resolved,
  });

  static const empty = TenantIssueCounts(pending: 0, active: 0, resolved: 0);
}
