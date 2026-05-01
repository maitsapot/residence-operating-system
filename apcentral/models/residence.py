from odoo import models, fields


class Residence(models.Model):
    _name = 'apcentral.residence'
    _description = 'Residence'
    _rec_name = 'name'

    # -------------------------
    # Ownership / Multi-company
    # -------------------------
    company_id = fields.Many2one(
        'res.company',
        string="Company",
        required=True,
        default=lambda self: self.env.company,
        index=True
    )

    # -------------------------
    # Identity
    # -------------------------
    name = fields.Char(string="Residence Name", required=True)
    code = fields.Char(string="Code")
    motto = fields.Char(string="Motto")

    # -------------------------
    # Location
    # -------------------------
    address = fields.Text(string="Address")
    latitude = fields.Float(string="Latitude", digits=(10, 6))
    longitude = fields.Float(string="Longitude", digits=(10, 6))

    # -------------------------
    # Capacity
    # -------------------------
    total_capacity = fields.Integer(string="Total Capacity")

    # -------------------------
    # Structure
    # -------------------------
    building_type = fields.Selection([
        ('house', 'House'),
        ('apartment', 'Apartment'),
        ('residence', 'Purpose-built Residence'),
        ('other', 'Other')
    ], string="Building Type")

    # -------------------------
    # Connectivity
    # -------------------------
    wifi_type = fields.Selection([
        ('fiber', 'Fibre'),
        ('lte', 'LTE / 5G'),
        ('adsl', 'ADSL'),
        ('wireless', 'Wireless / Antenna')
    ], string="WiFi Type")

    internet_speed_mbps = fields.Integer(string="Internet Speed (Mbps)")

    # -------------------------
    # Utilities
    # -------------------------
    has_backup_power = fields.Boolean(string="Backup Power")
    has_water_backup = fields.Boolean(string="Water Backup")

    # -------------------------
    # Ownership & Operations
    # -------------------------
    owner_id = fields.Many2one(
        'res.partner',
        string="Primary Owner"
    )

    landlord_partner_ids = fields.Many2many(
        'res.partner',
        'apcentral_residence_landlord_rel',
        'residence_id',
        'partner_id',
        string="Landlords"
    )

    caretaker_partner_ids = fields.Many2many(
        'res.partner',
        'apcentral_residence_caretaker_rel',
        'residence_id',
        'partner_id',
        string="Caretakers"
    )

    # -------------------------
    # Relationships
    # -------------------------
    institution_link_ids = fields.One2many(
        'apcentral.residence.institution',
        'residence_id',
        string="Institutions Served"
    )

    nsfas_accreditation_ids = fields.One2many(
        'apcentral.nsfas.accreditation',
        'residence_id',
        string="NSFAS Accreditations"
    )

    service_ids = fields.One2many(
        'apcentral.residence.service',
        'residence_id',
        string="Service Providers"
    )

    # -------------------------
    # System
    # -------------------------
    active = fields.Boolean(default=True)