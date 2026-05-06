class CommonIssue {
  final String id;
  final String itemId;
  final String issueName;
  final String defaultSeverity;
  final String defaultUrgency;
  final bool isOther;

  const CommonIssue({
    required this.id,
    required this.itemId,
    required this.issueName,
    required this.defaultSeverity,
    required this.defaultUrgency,
    required this.isOther,
  });

  factory CommonIssue.fromJson(Map<String, dynamic> json) {
    return CommonIssue(
      id: json['id'].toString(),
      itemId: json['item_id'].toString(),
      issueName: json['issue_name']?.toString() ?? 'Item issue',
      defaultSeverity: json['default_severity']?.toString() ?? 'medium',
      defaultUrgency: json['default_urgency']?.toString() ?? 'medium',
      isOther: json['is_other'] == true,
    );
  }
}
