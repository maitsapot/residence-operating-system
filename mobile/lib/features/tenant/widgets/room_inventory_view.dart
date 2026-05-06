import 'package:flutter/material.dart';

import '../../../models/space_item.dart';

class RoomInventoryView extends StatelessWidget {
  final List<SpaceItem> items;
  final VoidCallback onBack;
  final ValueChanged<SpaceItem> onRaiseIssue;

  const RoomInventoryView({
    super.key,
    required this.items,
    required this.onBack,
    required this.onRaiseIssue,
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
          ...items.map(
            (item) =>
                _InventoryItemTile(item: item, onRaiseIssue: onRaiseIssue),
          ),
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
  final ValueChanged<SpaceItem> onRaiseIssue;

  const _InventoryItemTile({required this.item, required this.onRaiseIssue});

  @override
  Widget build(BuildContext context) {
    final accent = item.needsAttention
        ? const Color(0xFFDC2626)
        : const Color(0xFF16A34A);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InspectionImage(imageUrl: item.lastInspectionImageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Inventory Item',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.itemName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _StatusLine(item: item, accent: accent),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _QuantityBadge(item: item),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoPanel(
                  icon: Icons.event_available_rounded,
                  label: 'Last Inspection',
                  value: _inspectionDateLabel(item.lastInspectionAt),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _QrPanel(qrCode: item.qrCode)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => onRaiseIssue(item),
              icon: const Icon(Icons.report_problem_rounded, size: 18),
              label: const Text('Raise Issue'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD7192F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _inspectionDateLabel(DateTime? value) {
    if (value == null) return 'Not inspected yet';

    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');

    return '${local.year}-$month-$day';
  }
}

class _InspectionImage extends StatelessWidget {
  final String? imageUrl;

  const _InspectionImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;

    if (url == null || url.isEmpty) {
      return Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Icon(
          Icons.photo_camera_back_outlined,
          color: Color(0xFF64748B),
          size: 25,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        url,
        width: 58,
        height: 58,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: 58,
          height: 58,
          color: const Color(0xFFF1F5F9),
          child: const Icon(
            Icons.broken_image_outlined,
            color: Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  final SpaceItem item;
  final Color accent;

  const _StatusLine({required this.item, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        _MiniPill(
          label: '${_label(item.condition)} condition',
          color: accent,
          icon: Icons.health_and_safety_outlined,
        ),
        _MiniPill(
          label: _label(item.status),
          color: accent,
          icon: Icons.inventory_2_outlined,
        ),
      ],
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

class _MiniPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _MiniPill({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityBadge extends StatelessWidget {
  final SpaceItem item;

  const _QuantityBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(
            'x${item.quantity}',
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.isRequired ? 'Req' : 'Opt',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoPanel({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF475569), size: 16),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _QrPanel extends StatelessWidget {
  final String qrCode;

  const _QrPanel({required this.qrCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          _QrGlyph(value: qrCode),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Item QR Code',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _shortCode(qrCode),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _shortCode(String value) {
    if (value.length <= 10) return value;

    return value.substring(value.length - 10).toUpperCase();
  }
}

class _QrGlyph extends StatelessWidget {
  final String value;

  const _QrGlyph({required this.value});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size.square(38),
      painter: _QrGlyphPainter(value),
    );
  }
}

class _QrGlyphPainter extends CustomPainter {
  final String value;

  const _QrGlyphPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = Colors.white;
    final foreground = Paint()..color = const Color(0xFF0F172A);
    final border = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final radius = Radius.circular(size.width * 0.12);
    final rect = Offset.zero & size;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), background);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), border);

    const cells = 7;
    final cell = size.width / cells;
    final seed = value.codeUnits.fold<int>(0, (sum, code) => sum + code);

    for (var y = 0; y < cells; y++) {
      for (var x = 0; x < cells; x++) {
        final finder = (x < 2 && y < 2) || (x > 4 && y < 2) || (x < 2 && y > 4);
        final filled = finder || ((seed + x * 7 + y * 11) % 3 == 0);

        if (!filled) continue;

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              x * cell + cell * 0.18,
              y * cell + cell * 0.18,
              cell * 0.64,
              cell * 0.64,
            ),
            Radius.circular(cell * 0.12),
          ),
          foreground,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrGlyphPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
