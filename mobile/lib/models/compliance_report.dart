class ComplianceReport {
  final String spaceId;
  final String templateType;
  final String standard;
  final List<ComplianceItem> missingItems;
  final List<ComplianceItem> extraItems;
  final List<ComplianceItem> badItems;
  final ComplianceScore score;

  const ComplianceReport({
    required this.spaceId,
    required this.templateType,
    required this.standard,
    required this.missingItems,
    required this.extraItems,
    required this.badItems,
    required this.score,
  });

  factory ComplianceReport.fromJson(Map<String, dynamic> json) {
    return ComplianceReport(
      spaceId: json['space_id'].toString(),
      templateType: json['template_type']?.toString() ?? '',
      standard: json['standard']?.toString() ?? '',
      missingItems: _decodeItems(json['missing_items']),
      extraItems: _decodeItems(json['extra_items']),
      badItems: _decodeItems(json['bad_items']),
      score: ComplianceScore.fromJson(json['score'] as Map<String, dynamic>),
    );
  }
}

class ComplianceItem {
  final String? spaceItemId;
  final String itemId;
  final String itemName;
  final String? condition;
  final String? status;
  final int? quantity;
  final int? requiredQuantity;

  const ComplianceItem({
    required this.spaceItemId,
    required this.itemId,
    required this.itemName,
    required this.condition,
    required this.status,
    required this.quantity,
    required this.requiredQuantity,
  });

  factory ComplianceItem.fromJson(Map<String, dynamic> json) {
    return ComplianceItem(
      spaceItemId: json['space_item_id']?.toString(),
      itemId: json['item_id'].toString(),
      itemName: json['item_name']?.toString() ?? 'Unnamed item',
      condition: json['condition']?.toString(),
      status: json['status']?.toString(),
      quantity: _asNullableInt(json['quantity']),
      requiredQuantity: _asNullableInt(json['required_quantity']),
    );
  }
}

class ComplianceScore {
  final int totalRequired;
  final int compliantItems;
  final int missingItems;
  final int badItems;
  final int extraItems;
  final double compliancePercentage;

  const ComplianceScore({
    required this.totalRequired,
    required this.compliantItems,
    required this.missingItems,
    required this.badItems,
    required this.extraItems,
    required this.compliancePercentage,
  });

  factory ComplianceScore.fromJson(Map<String, dynamic> json) {
    return ComplianceScore(
      totalRequired: _asInt(json['total_required']),
      compliantItems: _asInt(json['compliant_items']),
      missingItems: _asInt(json['missing_items']),
      badItems: _asInt(json['bad_items']),
      extraItems: _asInt(json['extra_items']),
      compliancePercentage: _asDouble(json['compliance_percentage']),
    );
  }
}

List<ComplianceItem> _decodeItems(Object? value) {
  final items = value as List<dynamic>? ?? [];

  return items
      .map((item) => ComplianceItem.fromJson(item as Map<String, dynamic>))
      .toList();
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

double _asDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();

  return double.tryParse(value?.toString() ?? '') ?? 0;
}
