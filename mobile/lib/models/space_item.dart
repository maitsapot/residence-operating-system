class SpaceItem {
  final String id;
  final String spaceId;
  final String itemId;
  final String itemName;
  final String categoryName;
  final String qrCode;
  final String? lastInspectionId;
  final DateTime? lastInspectionAt;
  final String? lastInspectionImageUrl;
  final int quantity;
  final bool isRequired;
  final String condition;
  final String status;

  const SpaceItem({
    required this.id,
    required this.spaceId,
    required this.itemId,
    required this.itemName,
    this.categoryName = 'other',
    required this.qrCode,
    required this.lastInspectionId,
    required this.lastInspectionAt,
    required this.lastInspectionImageUrl,
    required this.quantity,
    required this.isRequired,
    required this.condition,
    required this.status,
  });

  factory SpaceItem.fromJson(Map<String, dynamic> json) {
    return SpaceItem(
      id: json['id'].toString(),
      spaceId: json['space_id'].toString(),
      itemId: json['item_id'].toString(),
      itemName: json['item_name']?.toString() ?? 'Unnamed item',
      categoryName: json['category_name']?.toString() ?? 'other',
      qrCode: json['qr_code']?.toString() ?? json['id'].toString(),
      lastInspectionId: json['last_inspection_id']?.toString(),
      lastInspectionAt: _asDateTime(json['last_inspection_at']),
      lastInspectionImageUrl: json['last_inspection_image_url']?.toString(),
      quantity: _asInt(json['quantity']),
      isRequired: json['is_required'] != false,
      condition: json['condition']?.toString() ?? 'unknown',
      status: json['status']?.toString() ?? 'unknown',
    );
  }

  bool get needsAttention {
    return condition != 'good' || status != 'active';
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _asDateTime(Object? value) {
  if (value == null) return null;

  return DateTime.tryParse(value.toString());
}
