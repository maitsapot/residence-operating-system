BEGIN;

INSERT INTO locations (
    id, country, province, city, suburb, address_line_1, postal_code
)
VALUES
    ('11000000-0000-0000-0000-000000000001', 'South Africa', 'Gauteng', 'Johannesburg', 'Braamfontein', '45 De Korte Street', '2001'),
    ('11000000-0000-0000-0000-000000000002', 'South Africa', 'Gauteng', 'Johannesburg', 'Rosebank', '30 Baker Street', '2196'),
    ('11000000-0000-0000-0000-000000000003', 'South Africa', 'Limpopo', 'Polokwane', 'Bendor', '12 Thabo Mbeki Street', '0699'),
    ('11000000-0000-0000-0000-000000000004', 'South Africa', 'Gauteng', 'Pretoria', 'Hatfield', '1267 Pretorius Street', '0028'),
    ('11000000-0000-0000-0000-000000000005', 'South Africa', 'KwaZulu-Natal', 'Durban', 'Berea', '18 Musgrave Road', '4001'),
    ('11000000-0000-0000-0000-000000000006', 'South Africa', 'Western Cape', 'Cape Town', 'Observatory', '9 Main Road', '7925'),
    ('11000000-0000-0000-0000-000000000007', 'South Africa', 'Free State', 'Bloemfontein', 'Westdene', '22 President Brand Street', '9301'),
    ('11000000-0000-0000-0000-000000000008', 'South Africa', 'Eastern Cape', 'Gqeberha', 'Central', '15 Govan Mbeki Avenue', '6001'),
    ('11000000-0000-0000-0000-000000000009', 'South Africa', 'Mpumalanga', 'Mbombela', 'West Acres', '7 Samora Machel Drive', '1201'),
    ('11000000-0000-0000-0000-000000000010', 'South Africa', 'North West', 'Potchefstroom', 'Dassierand', '4 Steve Biko Avenue', '2531'),
    ('11000000-0000-0000-0000-000000000011', 'South Africa', 'Gauteng', 'Johannesburg', 'Midrand', '52 New Road', '1685'),
    ('11000000-0000-0000-0000-000000000012', 'South Africa', 'Limpopo', 'Polokwane', 'Flora Park', '19 Suid Street', '0699'),
    ('11000000-0000-0000-0000-000000000013', 'South Africa', 'Gauteng', 'Pretoria', 'Sunnyside', '88 Jorissen Street', '0002'),
    ('11000000-0000-0000-0000-000000000014', 'South Africa', 'Gauteng', 'Johannesburg', 'Marshalltown', '24 Commissioner Street', '2001')
ON CONFLICT (id) DO UPDATE
SET
    country = EXCLUDED.country,
    province = EXCLUDED.province,
    city = EXCLUDED.city,
    suburb = EXCLUDED.suburb,
    address_line_1 = EXCLUDED.address_line_1,
    postal_code = EXCLUDED.postal_code;

INSERT INTO companies (
    id, name, registration_number, location_id, is_active
)
VALUES
    ('30000000-0000-0000-0000-000000000001', 'Nolwazi Property Management', '2026/000001/07', '11000000-0000-0000-0000-000000000001', TRUE),
    ('30000000-0000-0000-0000-000000000002', 'Ubuntu Student Housing', '2026/000002/07', '11000000-0000-0000-0000-000000000002', TRUE),
    ('30000000-0000-0000-0000-000000000003', 'Turfloop Residence Services', '2026/000003/07', '11000000-0000-0000-0000-000000000003', TRUE),
    ('30000000-0000-0000-0000-000000000004', 'Hatfield Accommodation Group', '2026/000004/07', '11000000-0000-0000-0000-000000000004', TRUE),
    ('30000000-0000-0000-0000-000000000005', 'Berea Facilities Management', '2026/000005/07', '11000000-0000-0000-0000-000000000005', TRUE),
    ('30000000-0000-0000-0000-000000000006', 'Cape Student Living', '2026/000006/07', '11000000-0000-0000-0000-000000000006', TRUE),
    ('30000000-0000-0000-0000-000000000007', 'Mangaung Residence Operators', '2026/000007/07', '11000000-0000-0000-0000-000000000007', TRUE),
    ('30000000-0000-0000-0000-000000000008', 'Bay Campus Housing', '2026/000008/07', '11000000-0000-0000-0000-000000000008', TRUE),
    ('30000000-0000-0000-0000-000000000009', 'Lowveld Student Accommodation', '2026/000009/07', '11000000-0000-0000-0000-000000000009', TRUE),
    ('30000000-0000-0000-0000-000000000010', 'North West Residence Partners', '2026/000010/07', '11000000-0000-0000-0000-000000000010', TRUE),
    ('30000000-0000-0000-0000-000000000011', 'Amelia Property Group', '2026/000011/07', '11000000-0000-0000-0000-000000000011', TRUE),
    ('30000000-0000-0000-0000-000000000012', 'Dimbedzi Bakwena', '2026/000012/07', '11000000-0000-0000-0000-000000000012', TRUE),
    ('30000000-0000-0000-0000-000000000013', 'Ebenizer', '2026/000013/07', '11000000-0000-0000-0000-000000000013', TRUE),
    ('30000000-0000-0000-0000-000000000014', 'Meshalu Projects', '2026/000014/07', '11000000-0000-0000-0000-000000000014', TRUE)
ON CONFLICT (registration_number) DO UPDATE
SET
    name = EXCLUDED.name,
    location_id = EXCLUDED.location_id,
    is_active = EXCLUDED.is_active;

COMMIT;
