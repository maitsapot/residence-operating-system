import 'package:flutter/material.dart';

import '../../../models/space_item.dart';
import '../models/room_summary.dart';

class RoomInventoryView extends StatefulWidget {
  final RoomSummary? summary;
  final List<SpaceItem> items;
  final VoidCallback onBack;
  final ValueChanged<SpaceItem> onRaiseIssue;

  const RoomInventoryView({
    super.key,
    required this.summary,
    required this.items,
    required this.onBack,
    required this.onRaiseIssue,
  });

  @override
  State<RoomInventoryView> createState() => _RoomInventoryViewState();
}

class _RoomInventoryViewState extends State<RoomInventoryView> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expandedCategories = {};
  String _selectedNodeId = 'room';

  @override
  void initState() {
    super.initState();
    _expandedCategories.addAll(_groupedItems(widget.items).keys);
    if (widget.items.isNotEmpty) {
      _selectedNodeId = 'item:${widget.items.first.id}';
    }
  }

  @override
  void didUpdateWidget(covariant RoomInventoryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _expandedCategories.addAll(_groupedItems(widget.items).keys);
      if (_selectedNodeId == 'room' && widget.items.isNotEmpty) {
        _selectedNodeId = 'item:${widget.items.first.id}';
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupedItems(widget.items);
    final selectedItem = _selectedItem();
    final selectedCategory = _selectedCategory(groups);

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const Expanded(
              child: Text(
                'My Room',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: constraints.maxWidth * 0.35,
                    child: _RoomTreePane(
                      roomName: _roomTreeName,
                      groups: groups,
                      expandedCategories: _expandedCategories,
                      selectedNodeId: _selectedNodeId,
                      searchController: _searchController,
                      onSearchChanged: (_) => setState(() {}),
                      onRoomSelected: () =>
                          setState(() => _selectedNodeId = 'room'),
                      onCategorySelected: (category) {
                        setState(() {
                          _expandedCategories.add(category);
                          _selectedNodeId = 'category:$category';
                        });
                      },
                      onCategoryToggle: (category) {
                        setState(() {
                          if (!_expandedCategories.remove(category)) {
                            _expandedCategories.add(category);
                          }
                        });
                      },
                      onItemSelected: (item) =>
                          setState(() => _selectedNodeId = 'item:${item.id}'),
                    ),
                  ),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Color(0xFFE2E8F0),
                  ),
                  Expanded(
                    child: _RoomDetailPane(
                      summary: widget.summary,
                      items: widget.items,
                      selectedItem: selectedItem,
                      selectedCategory: selectedCategory,
                      categoryItems: selectedCategory == null
                          ? const []
                          : groups[selectedCategory] ?? const [],
                      onRaiseIssue: widget.onRaiseIssue,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  String get _roomTreeName {
    final name = widget.summary?.name.trim();
    if (name == null || name.isEmpty) return 'Room My Room';
    if (name.toLowerCase().startsWith('room ')) return name;

    return 'Room $name';
  }

  SpaceItem? _selectedItem() {
    final id = _selectedNodeId.startsWith('item:')
        ? _selectedNodeId.substring(5)
        : null;
    if (id == null) return null;

    for (final item in widget.items) {
      if (item.id == id) return item;
    }

    return null;
  }

  String? _selectedCategory(Map<String, List<SpaceItem>> groups) {
    if (!_selectedNodeId.startsWith('category:')) return null;

    final category = _selectedNodeId.substring(9);
    return groups.containsKey(category) ? category : null;
  }
}

class _RoomTreePane extends StatelessWidget {
  final String roomName;
  final Map<String, List<SpaceItem>> groups;
  final Set<String> expandedCategories;
  final String selectedNodeId;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRoomSelected;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<String> onCategoryToggle;
  final ValueChanged<SpaceItem> onItemSelected;

  const _RoomTreePane({
    required this.roomName,
    required this.groups,
    required this.expandedCategories,
    required this.selectedNodeId,
    required this.searchController,
    required this.onSearchChanged,
    required this.onRoomSelected,
    required this.onCategorySelected,
    required this.onCategoryToggle,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();

    return Container(
      color: const Color(0xFFFBFCFE),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 9,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
              children: [
                _TreeRow(
                  key: const ValueKey('room-tree-root'),
                  depth: 0,
                  label: roomName,
                  icon: Icons.meeting_room_outlined,
                  selected: selectedNodeId == 'room',
                  expanded: true,
                  onTap: onRoomSelected,
                ),
                if (groups.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'No inventory items have been assigned.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  ...groups.entries.expand((entry) {
                    final category = entry.key;
                    final filteredItems = entry.value.where((item) {
                      if (query.isEmpty) return true;
                      return item.itemName.toLowerCase().contains(query) ||
                          category.toLowerCase().contains(query);
                    }).toList();
                    if (filteredItems.isEmpty) return const <Widget>[];

                    final expanded =
                        query.isNotEmpty ||
                        expandedCategories.contains(category);

                    return [
                      _TreeRow(
                        key: ValueKey('room-tree-category-$category'),
                        depth: 1,
                        label: _titleCase(category),
                        icon: _categoryIcon(category),
                        selected: selectedNodeId == 'category:$category',
                        expanded: expanded,
                        onTap: () => onCategorySelected(category),
                        onToggle: () => onCategoryToggle(category),
                      ),
                      if (expanded)
                        ...filteredItems.map(
                          (item) => _TreeRow(
                            key: ValueKey('room-tree-item-${item.id}'),
                            depth: 2,
                            label: item.itemName,
                            icon: _itemIcon(item),
                            selected: selectedNodeId == 'item:${item.id}',
                            attention: item.needsAttention,
                            onTap: () => onItemSelected(item),
                          ),
                        ),
                    ];
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TreeRow extends StatelessWidget {
  final int depth;
  final String label;
  final IconData icon;
  final bool selected;
  final bool attention;
  final bool? expanded;
  final VoidCallback onTap;
  final VoidCallback? onToggle;

  const _TreeRow({
    super.key,
    required this.depth,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.attention = false,
    this.expanded,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final color = attention
        ? const Color(0xFFDC2626)
        : selected
        ? const Color(0xFFD7192F)
        : const Color(0xFF475569);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: EdgeInsets.fromLTRB(6 + depth * 10, 8, 6, 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF1F2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFFFECACA) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              child: expanded == null
                  ? depth > 0
                        ? const _TreeBranch()
                        : const SizedBox.shrink()
                  : IconButton(
                      onPressed: onToggle ?? onTap,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      icon: Icon(
                        expanded! ? Icons.expand_more : Icons.chevron_right,
                        color: const Color(0xFF475569),
                      ),
                    ),
            ),
            const SizedBox(width: 4),
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF7F1D1D)
                      : const Color(0xFF0F172A),
                  fontSize: depth == 0 ? 13 : 12,
                  fontWeight: selected || depth < 2
                      ? FontWeight.w900
                      : FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TreeBranch extends StatelessWidget {
  const _TreeBranch();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 10,
        child: Divider(color: Color(0xFFCBD5E1), thickness: 1),
      ),
    );
  }
}

class _RoomDetailPane extends StatelessWidget {
  final RoomSummary? summary;
  final List<SpaceItem> items;
  final SpaceItem? selectedItem;
  final String? selectedCategory;
  final List<SpaceItem> categoryItems;
  final ValueChanged<SpaceItem> onRaiseIssue;

  const _RoomDetailPane({
    required this.summary,
    required this.items,
    required this.selectedItem,
    required this.selectedCategory,
    required this.categoryItems,
    required this.onRaiseIssue,
  });

  @override
  Widget build(BuildContext context) {
    final item = selectedItem;
    final category = selectedCategory;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 2, 16),
      children: [
        if (item != null)
          _ItemDetails(item: item, onRaiseIssue: onRaiseIssue)
        else if (category != null)
          _CategoryDetails(category: category, items: categoryItems)
        else
          _RoomDetails(summary: summary, items: items),
      ],
    );
  }
}

class _RoomDetails extends StatelessWidget {
  final RoomSummary? summary;
  final List<SpaceItem> items;

  const _RoomDetails({required this.summary, required this.items});

  @override
  Widget build(BuildContext context) {
    final totalQuantity = items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    final attentionCount = items.where((item) => item.needsAttention).length;
    final requiredCount = items.where((item) => item.isRequired).length;
    final categoryCount = _groupedItems(items).length;
    final healthColor = attentionCount == 0
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailHeader(
                icon: Icons.meeting_room_outlined,
                title: _roomTitle,
                subtitle:
                    '${_titleCase(summary?.roomType ?? 'room')} - ${_titleCase(summary?.standard ?? 'standard')}',
                status: attentionCount == 0 ? 'Room Healthy' : 'Attention',
                statusColor: healthColor,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _DashboardStatTile(
                      icon: Icons.category_outlined,
                      label: 'Categories',
                      value: categoryCount.toString(),
                      accent: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DashboardStatTile(
                      icon: Icons.inventory_2_outlined,
                      label: 'Items',
                      value: items.length.toString(),
                      accent: const Color(0xFF7C3AED),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _DashboardStatTile(
                      icon: Icons.format_list_numbered_rounded,
                      label: 'Quantity',
                      value: totalQuantity.toString(),
                      accent: const Color(0xFF0891B2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DashboardStatTile(
                      icon: Icons.warning_amber_rounded,
                      label: 'Attention',
                      value: attentionCount == 0
                          ? '0'
                          : attentionCount.toString(),
                      accent: healthColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Room Details',
          children: [
            _DetailMetric(
              label: 'Room Number',
              value: summary?.name ?? 'My Room',
            ),
            _DetailMetric(
              label: 'Room Type',
              value: _titleCase(summary?.roomType ?? 'room'),
            ),
            _DetailMetric(
              label: 'Standard',
              value: _titleCase(summary?.standard ?? 'standard'),
            ),
            _DetailMetric(
              label: 'Parent Categories',
              value: categoryCount.toString(),
            ),
            _DetailMetric(
              label: 'Inventory Lines',
              value: items.length.toString(),
            ),
            _DetailMetric(
              label: 'Total Quantity',
              value: totalQuantity.toString(),
            ),
            _DetailMetric(
              label: 'Required Items',
              value: requiredCount.toString(),
            ),
            _DetailMetric(
              label: 'Attention',
              value: attentionCount == 0 ? 'None' : attentionCount.toString(),
              accent: attentionCount == 0
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFDC2626),
            ),
          ],
        ),
      ],
    );
  }

  String get _roomTitle {
    final name = summary?.name.trim();
    if (name == null || name.isEmpty) return 'Room My Room';
    if (name.toLowerCase().startsWith('room ')) return name;

    return 'Room $name';
  }
}

class _CategoryDetails extends StatelessWidget {
  final String category;
  final List<SpaceItem> items;

  const _CategoryDetails({required this.category, required this.items});

  @override
  Widget build(BuildContext context) {
    final attentionCount = items.where((item) => item.needsAttention).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailHeader(
          icon: _categoryIcon(category),
          title: _titleCase(category),
          subtitle: 'Parent Category',
          status: attentionCount == 0 ? 'Good' : '$attentionCount Attention',
          statusColor: attentionCount == 0
              ? const Color(0xFF16A34A)
              : const Color(0xFFDC2626),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Category Details',
          children: [
            _DetailMetric(label: 'Items', value: items.length.toString()),
            _DetailMetric(
              label: 'Required',
              value: items.where((item) => item.isRequired).length.toString(),
            ),
            _DetailMetric(
              label: 'Total Quantity',
              value: items
                  .fold<int>(0, (sum, item) => sum + item.quantity)
                  .toString(),
            ),
            _DetailMetric(
              label: 'Attention',
              value: attentionCount == 0 ? 'None' : attentionCount.toString(),
              accent: attentionCount == 0
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFDC2626),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Items',
          children: items.map((item) => _InlineItemStatus(item: item)).toList(),
        ),
      ],
    );
  }
}

class _ItemDetails extends StatelessWidget {
  final SpaceItem item;
  final ValueChanged<SpaceItem> onRaiseIssue;

  const _ItemDetails({required this.item, required this.onRaiseIssue});

  @override
  Widget build(BuildContext context) {
    final accent = item.needsAttention
        ? const Color(0xFFDC2626)
        : const Color(0xFF16A34A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailHeader(
          icon: _itemIcon(item),
          title: item.itemName,
          subtitle: _titleCase(item.categoryName),
          status: item.needsAttention ? 'Attention' : 'Good',
          statusColor: accent,
          action: _HeaderIssueButton(onPressed: () => onRaiseIssue(item)),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Item Rating',
          children: const [_StarRatingControl()],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Item Details',
          children: [
            _DetailMetric(label: 'Type', value: item.itemName),
            _DetailMetric(
              label: 'Category',
              value: _titleCase(item.categoryName),
            ),
            _DetailMetric(
              label: 'Condition',
              value: _titleCase(item.condition),
            ),
            _DetailMetric(label: 'Status', value: _titleCase(item.status)),
            _DetailMetric(label: 'Quantity', value: item.quantity.toString()),
            _DetailMetric(
              label: 'Requirement',
              value: item.isRequired ? 'Required' : 'Optional',
            ),
          ],
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 12),
        _SectionCard(
          title: 'History',
          children: [
            _HistoryLine(
              icon: Icons.fact_check_outlined,
              label: 'Inspection',
              value: _inspectionDateLabel(item.lastInspectionAt),
              accent: accent,
            ),
            _HistoryLine(
              icon: Icons.inventory_2_outlined,
              label: 'Current status',
              value:
                  '${_titleCase(item.condition)} condition, ${_titleCase(item.status)}',
              accent: accent,
            ),
          ],
        ),
      ],
    );
  }
}

class _DashboardStatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _DashboardStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIssueButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _HeaderIssueButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.warning_amber_rounded, size: 16),
        label: const Text('Raise Issue'),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFD7192F),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _StarRatingControl extends StatefulWidget {
  const _StarRatingControl();

  @override
  State<_StarRatingControl> createState() => _StarRatingControlState();
}

class _StarRatingControlState extends State<_StarRatingControl> {
  int rating = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...List.generate(5, (index) {
          final value = index + 1;
          final selected = value <= rating;

          return IconButton(
            onPressed: () => setState(() => rating = value),
            tooltip: '$value star rating',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            icon: Icon(
              selected ? Icons.star_rounded : Icons.star_border_rounded,
              color: selected
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF94A3B8),
              size: 28,
            ),
          );
        }),
        const SizedBox(width: 8),
        Text(
          rating == 0 ? 'Not rated' : '$rating of 5',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final Widget? action;

  const _DetailHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: statusColor, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (action != null) ...[const SizedBox(height: 8), action!],
          ],
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _DetailMetric({
    required this.label,
    required this.value,
    this.accent = const Color(0xFF0F172A),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: accent,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineItemStatus extends StatelessWidget {
  final SpaceItem item;

  const _InlineItemStatus({required this.item});

  @override
  Widget build(BuildContext context) {
    final accent = item.needsAttention
        ? const Color(0xFFDC2626)
        : const Color(0xFF16A34A);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(_itemIcon(item), size: 18, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.itemName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.needsAttention ? 'Attention' : 'Good',
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _HistoryLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: accent.withValues(alpha: 0.12),
            child: Icon(icon, color: accent, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
        borderRadius: BorderRadius.circular(8),
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
        borderRadius: BorderRadius.circular(8),
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

Map<String, List<SpaceItem>> _groupedItems(List<SpaceItem> items) {
  final groups = <String, List<SpaceItem>>{};

  for (final item in items) {
    groups.putIfAbsent(item.categoryName, () => []).add(item);
  }

  return Map.fromEntries(
    groups.entries.toList()
      ..sort((a, b) => _titleCase(a.key).compareTo(_titleCase(b.key))),
  );
}

IconData _categoryIcon(String category) {
  switch (category) {
    case 'furniture':
      return Icons.chair_outlined;
    case 'electrical':
      return Icons.lightbulb_outline_rounded;
    case 'plumbing':
      return Icons.water_drop_outlined;
    case 'appliance':
      return Icons.kitchen_outlined;
    case 'hygiene':
      return Icons.cleaning_services_outlined;
    case 'security':
      return Icons.shield_outlined;
    case 'structural':
      return Icons.domain_outlined;
    default:
      return Icons.inventory_2_outlined;
  }
}

IconData _itemIcon(SpaceItem item) {
  final name = item.itemName.toLowerCase();
  if (name.contains('bed') || name.contains('mattress')) {
    return Icons.bed_outlined;
  }
  if (name.contains('chair')) return Icons.chair_alt_outlined;
  if (name.contains('desk') || name.contains('table')) {
    return Icons.table_bar_outlined;
  }
  if (name.contains('wardrobe') || name.contains('closet')) {
    return Icons.door_sliding_outlined;
  }
  if (name.contains('fridge')) return Icons.kitchen_outlined;
  if (name.contains('light')) return Icons.lightbulb_outline_rounded;
  if (name.contains('curtain')) return Icons.curtains_outlined;

  return _categoryIcon(item.categoryName);
}

String _inspectionDateLabel(DateTime? value) {
  if (value == null) return 'Not inspected yet';

  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');

  return '${local.year}-$month-$day';
}

String _titleCase(String value) {
  return value
      .split('_')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}
