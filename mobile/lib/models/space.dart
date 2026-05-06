class Space {
  final String id;
  final String residenceId;
  final String name;
  final String spaceType;
  final String templateType;
  final String standard;
  final bool isRentable;
  final int capacity;
  final int? floor;
  final String? notes;
  final bool isActive;

  const Space({
    required this.id,
    required this.residenceId,
    required this.name,
    required this.spaceType,
    required this.templateType,
    required this.standard,
    required this.isRentable,
    required this.capacity,
    required this.floor,
    required this.notes,
    required this.isActive,
  });

  factory Space.fromJson(Map<String, dynamic> json) {
    return Space(
      id: json['id'].toString(),
      residenceId: json['residence_id'].toString(),
      name: json['name']?.toString() ?? 'Unnamed space',
      spaceType: json['space_type']?.toString() ?? '',
      templateType: json['template_type']?.toString() ?? '',
      standard: json['standard']?.toString() ?? '',
      isRentable: json['is_rentable'] == true,
      capacity: _asInt(json['capacity']),
      floor: _asNullableInt(json['floor']),
      notes: json['notes']?.toString(),
      isActive: json['is_active'] != false,
    );
  }

  bool get isRoom {
    return spaceType == 'room';
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _asNullableInt(Object? value) {
  if (value == null) return null;

  return _asInt(value);
}
