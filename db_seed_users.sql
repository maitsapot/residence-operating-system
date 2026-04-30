BEGIN;

INSERT INTO locations (
    id, country, province, city, suburb, address_line_1, postal_code
)
VALUES
    ('12000000-0000-0000-0000-000000000001', 'South Africa', 'Gauteng', 'Johannesburg', 'Braamfontein', '101 Student Seed Street', '2001'),
    ('12000000-0000-0000-0000-000000000002', 'South Africa', 'Limpopo', 'Polokwane', 'Bendor', '102 Student Seed Street', '0699'),
    ('12000000-0000-0000-0000-000000000003', 'South Africa', 'Limpopo', 'Mankweng', 'Turfloop', '103 Student Seed Street', '0727'),
    ('12000000-0000-0000-0000-000000000004', 'South Africa', 'Gauteng', 'Pretoria', 'Hatfield', '104 Student Seed Street', '0028'),
    ('12000000-0000-0000-0000-000000000005', 'South Africa', 'Gauteng', 'Johannesburg', 'Auckland Park', '105 Student Seed Street', '2092'),
    ('12000000-0000-0000-0000-000000000006', 'South Africa', 'North West', 'Potchefstroom', 'Dassierand', '106 Student Seed Street', '2531'),
    ('12000000-0000-0000-0000-000000000007', 'South Africa', 'Gauteng', 'Johannesburg', 'Soweto', '107 Student Seed Street', '1804'),
    ('12000000-0000-0000-0000-000000000008', 'South Africa', 'Limpopo', 'Thohoyandou', 'Sibasa', '108 Student Seed Street', '0970'),
    ('12000000-0000-0000-0000-000000000009', 'South Africa', 'Gauteng', 'Pretoria', 'Sunnyside', '109 Student Seed Street', '0002'),
    ('12000000-0000-0000-0000-000000000010', 'South Africa', 'Free State', 'Bloemfontein', 'Westdene', '110 Student Seed Street', '9301'),
    ('12000000-0000-0000-0000-000000000011', 'South Africa', 'Eastern Cape', 'Gqeberha', 'Central', '111 Student Seed Street', '6001'),
    ('12000000-0000-0000-0000-000000000012', 'South Africa', 'KwaZulu-Natal', 'Durban', 'Berea', '112 Student Seed Street', '4001'),
    ('12000000-0000-0000-0000-000000000013', 'South Africa', 'Western Cape', 'Cape Town', 'Observatory', '113 Student Seed Street', '7925'),
    ('12000000-0000-0000-0000-000000000014', 'South Africa', 'Mpumalanga', 'Mbombela', 'West Acres', '114 Student Seed Street', '1201'),
    ('12000000-0000-0000-0000-000000000015', 'South Africa', 'Northern Cape', 'Kimberley', 'New Park', '115 Student Seed Street', '8301'),
    ('12000000-0000-0000-0000-000000000016', 'South Africa', 'Gauteng', 'Johannesburg', 'Melville', '116 Student Seed Street', '2092'),
    ('12000000-0000-0000-0000-000000000017', 'South Africa', 'Limpopo', 'Polokwane', 'Flora Park', '117 Student Seed Street', '0699'),
    ('12000000-0000-0000-0000-000000000018', 'South Africa', 'Gauteng', 'Pretoria', 'Arcadia', '118 Student Seed Street', '0007'),
    ('12000000-0000-0000-0000-000000000019', 'South Africa', 'North West', 'Mahikeng', 'Mmabatho', '119 Student Seed Street', '2790'),
    ('12000000-0000-0000-0000-000000000020', 'South Africa', 'Eastern Cape', 'Makhanda', 'Central', '120 Student Seed Street', '6139'),
    ('12000000-0000-0000-0000-000000000021', 'South Africa', 'KwaZulu-Natal', 'Pietermaritzburg', 'Scottsville', '121 Student Seed Street', '3201'),
    ('12000000-0000-0000-0000-000000000022', 'South Africa', 'Western Cape', 'Stellenbosch', 'Central', '122 Student Seed Street', '7600'),
    ('12000000-0000-0000-0000-000000000023', 'South Africa', 'Mpumalanga', 'Emalahleni', 'Die Heuwel', '123 Student Seed Street', '1035'),
    ('12000000-0000-0000-0000-000000000024', 'South Africa', 'Free State', 'Welkom', 'Dagbreek', '124 Student Seed Street', '9459'),
    ('12000000-0000-0000-0000-000000000025', 'South Africa', 'Gauteng', 'Johannesburg', 'Parktown', '125 Student Seed Street', '2193'),
    ('12000000-0000-0000-0000-000000000026', 'South Africa', 'Limpopo', 'Tzaneen', 'Aqua Park', '126 Student Seed Street', '0850'),
    ('12000000-0000-0000-0000-000000000027', 'South Africa', 'Gauteng', 'Pretoria', 'Brooklyn', '127 Student Seed Street', '0181'),
    ('12000000-0000-0000-0000-000000000028', 'South Africa', 'North West', 'Rustenburg', 'Boitekong', '128 Student Seed Street', '0300'),
    ('12000000-0000-0000-0000-000000000029', 'South Africa', 'Western Cape', 'Bellville', 'Oakdale', '129 Student Seed Street', '7530')
ON CONFLICT (id) DO UPDATE
SET
    country = EXCLUDED.country,
    province = EXCLUDED.province,
    city = EXCLUDED.city,
    suburb = EXCLUDED.suburb,
    address_line_1 = EXCLUDED.address_line_1,
    postal_code = EXCLUDED.postal_code;

INSERT INTO users (
    id, first_name, middle_name, last_name, email, cellphone, phone,
    id_number, date_of_birth, gender, race, location_id, is_active
)
VALUES
    ('40000000-0000-0000-0000-000000000001', 'Ashley', NULL, 'Mathe', 'ashley.mathe@example.com', '0821000001', NULL, NULL, '2001-04-12', 'male', 'african', '12000000-0000-0000-0000-000000000001', TRUE),
    ('40000000-0000-0000-0000-000000000002', 'Abel', NULL, 'Lebepe', 'abel.lebepe@example.com', '0821000002', NULL, NULL, '1998-09-24', 'male', 'african', '12000000-0000-0000-0000-000000000002', TRUE),
    ('40000000-0000-0000-0000-000000000003', 'Merriam', NULL, 'Lebepe', 'merriam.lebepe@example.com', '0821000003', NULL, NULL, '1999-02-18', 'female', 'african', '12000000-0000-0000-0000-000000000003', TRUE),
    ('40000000-0000-0000-0000-000000000004', 'Mololo', NULL, 'Mathe', 'mololo.mathe@example.com', '0821000004', NULL, NULL, '2000-07-05', 'male', 'african', '12000000-0000-0000-0000-000000000004', TRUE),
    ('40000000-0000-0000-0000-000000000005', 'Karabo', NULL, 'Mathe', 'karabo.mathe@example.com', '0821000005', NULL, NULL, '2002-11-30', 'female', 'african', '12000000-0000-0000-0000-000000000005', TRUE),
    ('40000000-0000-0000-0000-000000000006', 'Tebogo', NULL, 'Maitsapo', 'tebogo.maitsapo@example.com', '0821000006', NULL, NULL, '2001-01-09', 'male', 'african', '12000000-0000-0000-0000-000000000006', TRUE),
    ('40000000-0000-0000-0000-000000000007', 'Nick', NULL, 'Sebati', 'nick.sebati@example.com', '0821000007', NULL, NULL, '1997-06-14', 'male', 'african', '12000000-0000-0000-0000-000000000007', TRUE),
    ('40000000-0000-0000-0000-000000000008', 'Aluwani', NULL, 'Mphaphuli', 'aluwani.mphaphuli@example.com', '0821000008', NULL, NULL, '2003-03-26', 'female', 'african', '12000000-0000-0000-0000-000000000008', TRUE),
    ('40000000-0000-0000-0000-000000000009', 'Cindy', NULL, 'Ramawa', 'cindy.ramawa@example.com', '0821000009', NULL, NULL, '2002-08-21', 'female', 'african', '12000000-0000-0000-0000-000000000009', TRUE),
    ('40000000-0000-0000-0000-000000000010', 'Thabo', NULL, 'Mokoena', 'thabo.mokoena@example.com', '0821000010', NULL, NULL, '2001-05-03', 'male', 'african', '12000000-0000-0000-0000-000000000010', TRUE),
    ('40000000-0000-0000-0000-000000000011', 'Sibusiso', NULL, 'Dlamini', 'sibusiso.dlamini@example.com', '0821000011', NULL, NULL, '2000-10-17', 'male', 'african', '12000000-0000-0000-0000-000000000011', TRUE),
    ('40000000-0000-0000-0000-000000000012', 'Mandla', NULL, 'Nkosi', 'mandla.nkosi@example.com', '0821000012', NULL, NULL, '1999-12-02', 'male', 'african', '12000000-0000-0000-0000-000000000012', TRUE),
    ('40000000-0000-0000-0000-000000000013', 'Tshepo', NULL, 'Molefe', 'tshepo.molefe@example.com', '0821000013', NULL, NULL, '2002-04-08', 'male', 'african', '12000000-0000-0000-0000-000000000013', TRUE),
    ('40000000-0000-0000-0000-000000000014', 'Kabelo', NULL, 'Radebe', 'kabelo.radebe@example.com', '0821000014', NULL, NULL, '2001-09-11', 'male', 'african', '12000000-0000-0000-0000-000000000014', TRUE),
    ('40000000-0000-0000-0000-000000000015', 'Lethabo', NULL, 'Mahlangu', 'lethabo.mahlangu@example.com', '0821000015', NULL, NULL, '2000-01-27', 'male', 'african', '12000000-0000-0000-0000-000000000015', TRUE),
    ('40000000-0000-0000-0000-000000000016', 'Bongani', NULL, 'Khumalo', 'bongani.khumalo@example.com', '0821000016', NULL, NULL, '1998-06-19', 'male', 'african', '12000000-0000-0000-0000-000000000016', TRUE),
    ('40000000-0000-0000-0000-000000000017', 'Mpho', NULL, 'Maseko', 'mpho.maseko@example.com', '0821000017', NULL, NULL, '2003-02-23', 'male', 'african', '12000000-0000-0000-0000-000000000017', TRUE),
    ('40000000-0000-0000-0000-000000000018', 'Neo', NULL, 'Mabena', 'neo.mabena@example.com', '0821000018', NULL, NULL, '2002-07-16', 'male', 'african', '12000000-0000-0000-0000-000000000018', TRUE),
    ('40000000-0000-0000-0000-000000000019', 'Katlego', NULL, 'Molepo', 'katlego.molepo@example.com', '0821000019', NULL, NULL, '2001-11-06', 'male', 'african', '12000000-0000-0000-0000-000000000019', TRUE),
    ('40000000-0000-0000-0000-000000000020', 'Lerato', NULL, 'Ndlovu', 'lerato.ndlovu@example.com', '0821000020', NULL, NULL, '2002-03-15', 'female', 'african', '12000000-0000-0000-0000-000000000020', TRUE),
    ('40000000-0000-0000-0000-000000000021', 'Nomsa', NULL, 'Mthembu', 'nomsa.mthembu@example.com', '0821000021', NULL, NULL, '2001-08-04', 'female', 'african', '12000000-0000-0000-0000-000000000021', TRUE),
    ('40000000-0000-0000-0000-000000000022', 'Anele', NULL, 'Sithole', 'anele.sithole@example.com', '0821000022', NULL, NULL, '2000-05-28', 'female', 'african', '12000000-0000-0000-0000-000000000022', TRUE),
    ('40000000-0000-0000-0000-000000000023', 'Zanele', NULL, 'Mkhize', 'zanele.mkhize@example.com', '0821000023', NULL, NULL, '1999-09-13', 'female', 'african', '12000000-0000-0000-0000-000000000023', TRUE),
    ('40000000-0000-0000-0000-000000000024', 'Refilwe', NULL, 'Mogale', 'refilwe.mogale@example.com', '0821000024', NULL, NULL, '2003-12-20', 'female', 'african', '12000000-0000-0000-0000-000000000024', TRUE),
    ('40000000-0000-0000-0000-000000000025', 'Buhle', NULL, 'Ntuli', 'buhle.ntuli@example.com', '0821000025', NULL, NULL, '2002-06-07', 'female', 'african', '12000000-0000-0000-0000-000000000025', TRUE),
    ('40000000-0000-0000-0000-000000000026', 'Nokuthula', NULL, 'Dube', 'nokuthula.dube@example.com', '0821000026', NULL, NULL, '2001-10-29', 'female', 'african', '12000000-0000-0000-0000-000000000026', TRUE),
    ('40000000-0000-0000-0000-000000000027', 'Palesa', NULL, 'Moletsane', 'palesa.moletsane@example.com', '0821000027', NULL, NULL, '2000-02-10', 'female', 'african', '12000000-0000-0000-0000-000000000027', TRUE),
    ('40000000-0000-0000-0000-000000000028', 'Nthabiseng', NULL, 'Mokoena', 'nthabiseng.mokoena@example.com', '0821000028', NULL, NULL, '1998-07-25', 'female', 'african', '12000000-0000-0000-0000-000000000028', TRUE),
    ('40000000-0000-0000-0000-000000000029', 'Kgomotso', NULL, 'Ramaloko', 'kgomotso.ramaloko@example.com', '0821000029', NULL, NULL, '2003-04-18', 'female', 'african', '12000000-0000-0000-0000-000000000029', TRUE)
ON CONFLICT (email) DO UPDATE
SET
    first_name = EXCLUDED.first_name,
    middle_name = EXCLUDED.middle_name,
    last_name = EXCLUDED.last_name,
    cellphone = EXCLUDED.cellphone,
    phone = EXCLUDED.phone,
    id_number = EXCLUDED.id_number,
    date_of_birth = EXCLUDED.date_of_birth,
    gender = EXCLUDED.gender,
    race = EXCLUDED.race,
    location_id = EXCLUDED.location_id,
    is_active = EXCLUDED.is_active;

COMMIT;
