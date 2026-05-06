class Tenancy {
  final String id;
  final String startDate;
  final String? endDate;
  final String status;
  final String userId;
  final String spaceId;

  const Tenancy({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.userId,
    required this.spaceId,
  });

  factory Tenancy.fromJson(Map<String, dynamic> json) {
    return Tenancy(
      id: json['id'].toString(),
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString(),
      status: json['status']?.toString() ?? '',
      userId: json['user_id'].toString(),
      spaceId: json['space_id'].toString(),
    );
  }
}
