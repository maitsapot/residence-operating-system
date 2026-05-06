import 'package:flutter/material.dart';

import '../../../core/widgets/action_card.dart';
import '../models/tenant_home_action.dart';
import '../models/tenant_issue_counts.dart';

class TenantActionList extends StatelessWidget {
  final List<TenantHomeAction> actions;
  final TenantIssueCounts issueCounts;
  final Widget? header;
  final ValueChanged<TenantHomeAction> onActionTap;

  const TenantActionList({
    super.key,
    required this.actions,
    required this.issueCounts,
    this.header,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ?header,
          ...actions.map(
            (action) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: ActionCard(
                label: action.label,
                subtitle: action.subtitle,
                icon: action.icon,
                pendingIssues: issueCounts.pending,
                activeIssues: issueCounts.active,
                resolvedIssues: issueCounts.resolved,
                onTap: () => onActionTap(action),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
