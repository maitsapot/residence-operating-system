import '../../../models/space_item.dart';

class RoomSummary {
  final String name;
  final List<SpaceItem> items;

  const RoomSummary({required this.name, required this.items});

  int get totalLines {
    return items.length;
  }

  int get totalQuantity {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  int get goodLines {
    return items.where((item) => item.condition == 'good').length;
  }

  int get complyingLines {
    return items
        .where((item) => item.condition == 'good' && item.status == 'active')
        .length;
  }

  int get attentionLines {
    return items.where((item) => item.needsAttention).length;
  }

  int get goodPercentage {
    return _percentage(goodLines, totalLines);
  }

  int get compliancePercentage {
    return _percentage(complyingLines, totalLines);
  }

  int _percentage(int value, int total) {
    if (total == 0) return 100;

    return ((value / total) * 100).round();
  }
}
