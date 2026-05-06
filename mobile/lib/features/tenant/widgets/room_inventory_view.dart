import 'package:flutter/material.dart';

import '../../../models/space_item.dart';

class RoomInventoryView extends StatelessWidget {
  final List<SpaceItem> items;
  final VoidCallback onBack;

  const RoomInventoryView({
    super.key,
    required this.items,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final totalQuantity = items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    final attentionCount = items.where((item) => item.needsAttention).length;
    final requiredCount = items.where((item) => item.isRequired).length;

    return ListView(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const Expanded(
              child: Text(
                'Room Inventory',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _InventorySummary(
          totalItems: items.length,
          totalQuantity: totalQuantity,
          requiredCount: requiredCount,
          attentionCount: attentionCount,
        ),
        const SizedBox(height: 14),
        if (items.isEmpty)
          const Center(child: Text('No inventory items have been assigned.'))
        else
          ...items.map((item) => _InventoryItemTile(item: item)),
      ],
    );
  }
}

class _InventorySummary extends StatelessWidget {
  final int totalItems;
  final int totalQuantity;
  final int requiredCount;
  final int attentionCount;

  const _InventorySummary({
    required this.totalItems,
    required this.totalQuantity,
    required this.requiredCount,
    required this.attentionCount,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SummaryPill(label: 'Lines', value: totalItems.toString()),
        _SummaryPill(label: 'Quantity', value: totalQuantity.toString()),
        _SummaryPill(label: 'Required', value: requiredCount.toString()),
        _SummaryPill(
          label: 'Attention',
          value: attentionCount.toString(),
          accent: attentionCount > 0
              ? const Color(0xFFDC2626)
              : const Color(0xFF16A34A),
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _SummaryPill({
    required this.label,
    required this.value,
    this.accent = const Color(0xFF4F46E5),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryItemTile extends StatelessWidget {
  final SpaceItem item;

  const _InventoryItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final accent = item.needsAttention
        ? const Color(0xFFDC2626)
        : const Color(0xFF16A34A);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.inventory_2_outlined, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_label(item.condition)} condition • ${_label(item.status)}',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'x${item.quantity}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.isRequired ? 'Required' : 'Optional',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _label(String value) {
    return value
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }
}
