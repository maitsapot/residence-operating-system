from odoo import models, fields


class Institution(models.Model):
    _name = 'apcentral.institution'
    _description = 'Institution'
    _rec_name = 'name'

    # -------------------------
    # Identity
    # -------------------------
    name = fields.Char(string="Institution Name", required=True)
    code = fields.Char(string="Code")

    # -------------------------
    # Classification
    # -------------------------
    institution_type = fields.Selection([
        ('university', 'University'),
        ('tvet', 'TVET College'),
        ('private', 'Private College'),
        ('other', 'Other')
    ], string="Type")

    # -------------------------
    # Location
    # -------------------------
    address = fields.Text(string="Address")
    city = fields.Char(string="City")

    latitude = fields.Float(string="Latitude", digits=(10, 6))
    longitude = fields.Float(string="Longitude", digits=(10, 6))

    # -------------------------
    # System
    # -------------------------
    active = fields.Boolean(default=True)