BEGIN;

INSERT INTO services (id, name, description, is_active)
VALUES
    (
        '70000000-0000-0000-0000-000000000001',
        'Cleaning',
        'Shared-space cleaning, room turnover cleaning, hygiene checks, and cleaning schedules.',
        TRUE
    ),
    (
        '70000000-0000-0000-0000-000000000002',
        'WiFi',
        'Internet availability, uptime, router issues, bandwidth complaints, and provider performance.',
        TRUE
    ),
    (
        '70000000-0000-0000-0000-000000000003',
        'Security',
        'Guarding, cameras, visitor logs, safety incidents, and general residence safety operations.',
        TRUE
    ),
    (
        '70000000-0000-0000-0000-000000000004',
        'Maintenance',
        'General repairs for plumbing, electrical, furniture, appliances, doors, windows, and structure.',
        TRUE
    ),
    (
        '70000000-0000-0000-0000-000000000005',
        'Laundry',
        'Laundry room access, washing machine availability, machine faults, and related service quality.',
        TRUE
    ),
    (
        '70000000-0000-0000-0000-000000000006',
        'Waste Management',
        'Refuse collection, bin availability, recycling, illegal dumping, and hygiene risks.',
        TRUE
    ),
    (
        '70000000-0000-0000-0000-000000000007',
        'Pest Control',
        'Scheduled fumigation, pest complaints, and health or safety follow-up.',
        TRUE
    ),
    (
        '70000000-0000-0000-0000-000000000008',
        'Fire Safety',
        'Extinguishers, alarms, evacuation signage, fire inspections, and fire compliance support.',
        TRUE
    ),
    (
        '70000000-0000-0000-0000-000000000009',
        'Water Supply',
        'Water interruptions, tank supply, pressure problems, leaks, and water service quality.',
        TRUE
    ),
    (
        '70000000-0000-0000-0000-000000000010',
        'Backup Power',
        'Load-shedding backup, generators, inverters, battery systems, and backup power reliability.',
        TRUE
    ),
    (
        '70000000-0000-0000-0000-000000000011',
        'Access Control',
        'Keys, tags, biometric access, gate remotes, room access records, and entry control faults.',
        TRUE
    )
ON CONFLICT (name) DO UPDATE
SET
    description = EXCLUDED.description,
    is_active = EXCLUDED.is_active,
    archived_at = NULL,
    updated_at = NOW();

COMMIT;
