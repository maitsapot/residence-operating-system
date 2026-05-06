class TenantSummary {
  final String id;
  final String fullName;

  const TenantSummary({required this.id, required this.fullName});

  factory TenantSummary.fromJson(Map<String, dynamic> json) {
    return TenantSummary(
      id: json['id'].toString(),
      fullName: json['full_name']?.toString() ?? 'Unnamed tenant',
    );
  }

  String get firstName {
    return fullName.trim().split(RegExp(r'\s+')).first;
  }
}
