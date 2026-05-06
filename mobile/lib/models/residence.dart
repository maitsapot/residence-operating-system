class Residence {
  final String id;
  final String name;
  final String? companyId;
  final int totalRooms;
  final int totalCapacity;
  final bool isActive;

  const Residence({
    required this.id,
    required this.name,
    required this.companyId,
    required this.totalRooms,
    required this.totalCapacity,
    required this.isActive,
  });

  factory Residence.fromJson(Map<String, dynamic> json) {
    return Residence(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? 'Unnamed residence',
      companyId: json['company_id']?.toString(),
      totalRooms: _asInt(json['total_rooms']),
      totalCapacity: _asInt(json['total_capacity']),
      isActive: json['is_active'] == true,
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value?.toString() ?? '') ?? 0;
}
