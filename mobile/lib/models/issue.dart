enum IssueStatus {
  open('open'),
  assigned('assigned'),
  inProgress('in_progress'),
  resolved('resolved'),
  closed('closed'),
  rejected('rejected'),
  unknown('unknown');

  final String value;

  const IssueStatus(this.value);

  static IssueStatus fromJson(Object? value) {
    final normalized = value?.toString();

    return IssueStatus.values.firstWhere(
      (status) => status.value == normalized,
      orElse: () => IssueStatus.unknown,
    );
  }
}

class Issue {
  final String id;
  final String reportedBy;
  final String? assignedTo;
  final IssueStatus status;
  final String severity;
  final String urgency;
  final String? description;

  const Issue({
    required this.id,
    required this.reportedBy,
    required this.assignedTo,
    required this.status,
    required this.severity,
    required this.urgency,
    required this.description,
  });

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      id: json['id'].toString(),
      reportedBy: json['reported_by'].toString(),
      assignedTo: json['assigned_to']?.toString(),
      status: IssueStatus.fromJson(json['status']),
      severity: json['severity']?.toString() ?? 'medium',
      urgency: json['urgency']?.toString() ?? 'medium',
      description: json['description']?.toString(),
    );
  }
}
