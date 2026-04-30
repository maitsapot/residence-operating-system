BEGIN;

INSERT INTO locations (
    id, country, province, city, suburb, address_line_1, postal_code, latitude, longitude
)
VALUES
    ('10000000-0000-0000-0000-000000000101', 'South Africa', 'Gauteng', 'Johannesburg', 'Auckland Park', 'Corner Kingsway and University Road', NULL, -26.1819167, 27.9983056),
    ('10000000-0000-0000-0000-000000000102', 'South Africa', 'Gauteng', 'Johannesburg', 'Auckland Park', 'Bunting Road', NULL, -26.1904167, 28.0193056),
    ('10000000-0000-0000-0000-000000000103', 'South Africa', 'Gauteng', 'Johannesburg', 'Doornfontein', 'Cnr Siemert & Beit Streets', NULL, -26.1923889, 28.0580278),
    ('10000000-0000-0000-0000-000000000104', 'South Africa', 'Gauteng', 'Johannesburg', 'Soweto', 'Old Potch Road', NULL, -26.2595278, 27.9239722),
    ('10000000-0000-0000-0000-000000000201', 'South Africa', 'Gauteng', 'Johannesburg', 'Parktown', '5 Ubla Avenue Off Princess Wales Terrace', '2193', NULL, NULL),
    ('10000000-0000-0000-0000-000000000202', 'South Africa', 'Gauteng', 'Johannesburg', 'Alexandra', 'Cnr Canning & Ninth Road', NULL, NULL, NULL),
    ('10000000-0000-0000-0000-000000000203', 'South Africa', 'Gauteng', 'Johannesburg', 'Doornfontein', '25 Currey Street', NULL, NULL, NULL),
    ('10000000-0000-0000-0000-000000000204', 'South Africa', 'Gauteng', 'Johannesburg', 'Langlaagte', '5 De Vos Street', NULL, NULL, NULL),
    ('10000000-0000-0000-0000-000000000205', 'South Africa', 'Gauteng', 'Johannesburg', 'Riverlea', '39 Ashburton Street', NULL, NULL, NULL),
    ('10000000-0000-0000-0000-000000000206', 'South Africa', 'Gauteng', 'Johannesburg', 'Braamfontein', '123 Juta Street', NULL, NULL, NULL),
    ('10000000-0000-0000-0000-000000000207', 'South Africa', 'Gauteng', 'Johannesburg', 'Troyeville', '46 Pretoria Street', NULL, NULL, NULL),
    ('10000000-0000-0000-0000-000000000301', 'South Africa', 'Gauteng', 'Johannesburg', 'Braamfontein', '23 Jorissen Street', NULL, NULL, NULL),
    ('10000000-0000-0000-0000-000000000400', 'South Africa', 'Limpopo', 'Mankweng', 'Turfloop', 'Turfloop Campus', NULL, NULL, NULL)
ON CONFLICT (id) DO UPDATE
SET
    country = EXCLUDED.country,
    province = EXCLUDED.province,
    city = EXCLUDED.city,
    suburb = EXCLUDED.suburb,
    address_line_1 = EXCLUDED.address_line_1,
    postal_code = EXCLUDED.postal_code,
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude;

INSERT INTO institutions (
    id, name, code, institution_type, parent_id, location_id, is_active
)
VALUES
    ('20000000-0000-0000-0000-000000000100', 'University of Johannesburg', 'UJ', 'university', NULL, '10000000-0000-0000-0000-000000000101', TRUE),
    ('20000000-0000-0000-0000-000000000101', 'University of Johannesburg - Auckland Park Kingsway Campus', 'UJ-APK', 'university', '20000000-0000-0000-0000-000000000100', '10000000-0000-0000-0000-000000000101', TRUE),
    ('20000000-0000-0000-0000-000000000102', 'University of Johannesburg - Auckland Park Bunting Road Campus', 'UJ-APB', 'university', '20000000-0000-0000-0000-000000000100', '10000000-0000-0000-0000-000000000102', TRUE),
    ('20000000-0000-0000-0000-000000000103', 'University of Johannesburg - Doornfontein Campus', 'UJ-DFC', 'university', '20000000-0000-0000-0000-000000000100', '10000000-0000-0000-0000-000000000103', TRUE),
    ('20000000-0000-0000-0000-000000000104', 'University of Johannesburg - Soweto Campus', 'UJ-SWC', 'university', '20000000-0000-0000-0000-000000000100', '10000000-0000-0000-0000-000000000104', TRUE),
    ('20000000-0000-0000-0000-000000000200', 'Central Johannesburg TVET College', 'CJC', 'tvet', NULL, '10000000-0000-0000-0000-000000000201', TRUE),
    ('20000000-0000-0000-0000-000000000201', 'Central Johannesburg TVET College - Parktown Campus', 'CJC-PARKTOWN', 'tvet', '20000000-0000-0000-0000-000000000200', '10000000-0000-0000-0000-000000000201', TRUE),
    ('20000000-0000-0000-0000-000000000202', 'Central Johannesburg TVET College - Alexandra Campus', 'CJC-ALEXANDRA', 'tvet', '20000000-0000-0000-0000-000000000200', '10000000-0000-0000-0000-000000000202', TRUE),
    ('20000000-0000-0000-0000-000000000203', 'Central Johannesburg TVET College - Ellis Park Campus', 'CJC-ELLIS', 'tvet', '20000000-0000-0000-0000-000000000200', '10000000-0000-0000-0000-000000000203', TRUE),
    ('20000000-0000-0000-0000-000000000204', 'Central Johannesburg TVET College - Langlaagte Campus', 'CJC-LANGLAAGTE', 'tvet', '20000000-0000-0000-0000-000000000200', '10000000-0000-0000-0000-000000000204', TRUE),
    ('20000000-0000-0000-0000-000000000205', 'Central Johannesburg TVET College - Riverlea Campus', 'CJC-RIVERLEA', 'tvet', '20000000-0000-0000-0000-000000000200', '10000000-0000-0000-0000-000000000205', TRUE),
    ('20000000-0000-0000-0000-000000000206', 'Central Johannesburg TVET College - Smit Street Campus', 'CJC-SMIT', 'tvet', '20000000-0000-0000-0000-000000000200', '10000000-0000-0000-0000-000000000206', TRUE),
    ('20000000-0000-0000-0000-000000000207', 'Central Johannesburg TVET College - Troyeville Campus', 'CJC-TROYEVILLE', 'tvet', '20000000-0000-0000-0000-000000000200', '10000000-0000-0000-0000-000000000207', TRUE),
    ('20000000-0000-0000-0000-000000000300', 'Rosebank College', 'RC', 'private_college', NULL, '10000000-0000-0000-0000-000000000301', TRUE),
    ('20000000-0000-0000-0000-000000000301', 'Rosebank College - Braamfontein Campus', 'RC-BRAAMFONTEIN', 'private_college', '20000000-0000-0000-0000-000000000300', '10000000-0000-0000-0000-000000000301', TRUE),
    ('20000000-0000-0000-0000-000000000400', 'University of Limpopo', 'UL', 'university', NULL, '10000000-0000-0000-0000-000000000400', TRUE)
ON CONFLICT (name) DO UPDATE
SET
    code = EXCLUDED.code,
    institution_type = EXCLUDED.institution_type,
    parent_id = EXCLUDED.parent_id,
    location_id = EXCLUDED.location_id,
    is_active = EXCLUDED.is_active;

COMMIT;
