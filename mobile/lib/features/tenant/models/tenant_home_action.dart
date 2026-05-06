import 'package:flutter/material.dart';

import '../../../core/widgets/hero_menu.dart';

enum TenantHomeActionDestination { roomInventory }

class TenantHomeAction {
  final String label;
  final String subtitle;
  final IconData icon;
  final TenantHomeActionDestination? destination;

  const TenantHomeAction(
    this.label,
    this.subtitle,
    this.icon, {
    this.destination,
  });
}

List<TenantHomeAction> actionsForTenantHomeMenu(HeroMenuType? selectedMenu) {
  switch (selectedMenu) {
    case HeroMenuType.accessControl:
      return const [
        TenantHomeAction('Access Code', 'View entry code', Icons.pin_outlined),
        TenantHomeAction('Visitors', 'Manage guests', Icons.badge_outlined),
        TenantHomeAction(
          'Revoke Access',
          'Remove permissions',
          Icons.block_rounded,
        ),
        TenantHomeAction('Request Access', 'Ask for entry', Icons.key_rounded),
        TenantHomeAction('Access Logs', 'View history', Icons.history_outlined),
        TenantHomeAction(
          'Permissions',
          'Manage access rules',
          Icons.lock_outline,
        ),
      ];
    case HeroMenuType.myRoom:
      return const [
        TenantHomeAction(
          'Room Details',
          'View room allocation',
          Icons.meeting_room_outlined,
        ),
        TenantHomeAction(
          'Roommates',
          'View shared room occupants',
          Icons.people_outline_rounded,
        ),
        TenantHomeAction(
          'Room Access',
          'Keys, codes, and entry notes',
          Icons.key_rounded,
        ),
        TenantHomeAction(
          'Room Inventory',
          'Furniture and assigned items',
          Icons.chair_outlined,
          destination: TenantHomeActionDestination.roomInventory,
        ),
        TenantHomeAction(
          'Condition Report',
          'Review room condition',
          Icons.health_and_safety_outlined,
        ),
        TenantHomeAction(
          'Move Request',
          'Request a room change',
          Icons.move_up_rounded,
        ),
      ];
    case HeroMenuType.myRes:
      return const [
        TenantHomeAction(
          'Inspections',
          'View inspection history',
          Icons.fact_check_outlined,
        ),
        TenantHomeAction(
          'Maintenance',
          'Submit & track requests',
          Icons.handyman_outlined,
        ),
        TenantHomeAction(
          'Reservations',
          'Manage facilities',
          Icons.event_seat_outlined,
        ),
        TenantHomeAction(
          'Issues',
          'Report & follow up',
          Icons.warning_amber_rounded,
        ),
        TenantHomeAction(
          'Facilities',
          'Shared spaces and amenities',
          Icons.apartment_outlined,
        ),
        TenantHomeAction(
          'Residence Rules',
          'House rules and notices',
          Icons.rule_folder_outlined,
        ),
      ];
    case HeroMenuType.myContacts:
      return const [
        TenantHomeAction(
          'Contacts',
          'View your contacts',
          Icons.contacts_outlined,
        ),
        TenantHomeAction(
          'Caretakers',
          'Residence caretakers',
          Icons.support_agent_outlined,
        ),
        TenantHomeAction(
          'Management',
          'Residence management',
          Icons.business_outlined,
        ),
        TenantHomeAction(
          'Security',
          'Security contacts',
          Icons.shield_outlined,
        ),
        TenantHomeAction('Emergency', 'Emergency numbers', Icons.call_outlined),
        TenantHomeAction(
          'Directory',
          'Full contact directory',
          Icons.list_alt_outlined,
        ),
      ];
    case HeroMenuType.social:
      return const [
        TenantHomeAction(
          'Chat',
          'Open conversations',
          Icons.chat_bubble_outline_rounded,
        ),
        TenantHomeAction(
          'Notifications',
          'View latest alerts',
          Icons.notifications_none_rounded,
        ),
        TenantHomeAction(
          'Events',
          'Browse events',
          Icons.calendar_month_outlined,
        ),
        TenantHomeAction('Post', 'Share an update', Icons.post_add_outlined),
        TenantHomeAction('Groups', 'Join communities', Icons.groups_outlined),
        TenantHomeAction(
          'Explore',
          'Discover activity',
          Icons.explore_outlined,
        ),
      ];
    default:
      return const [
        TenantHomeAction(
          'Inspections',
          'View inspection history',
          Icons.fact_check_outlined,
        ),
        TenantHomeAction(
          'Maintenance',
          'Submit & track requests',
          Icons.handyman_outlined,
        ),
        TenantHomeAction(
          'Reservations',
          'Manage facilities',
          Icons.event_seat_outlined,
        ),
        TenantHomeAction(
          'Issues',
          'Report & follow up',
          Icons.warning_amber_rounded,
        ),
        TenantHomeAction(
          'Facilities',
          'Shared spaces and amenities',
          Icons.apartment_outlined,
        ),
        TenantHomeAction(
          'Residence Rules',
          'House rules and notices',
          Icons.rule_folder_outlined,
        ),
      ];
  }
}
