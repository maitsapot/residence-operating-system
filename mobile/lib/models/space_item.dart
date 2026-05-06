class SpaceItem {
  final String id;
  final String spaceId;
  final String itemId;
  final String itemName;
  final int quantity;
  final bool isRequired;
  final String condition;
  final String status;

  const SpaceItem({
    required this.id,
    required this.spaceId,
    required this.itemId,
    required this.itemName,
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
