from odoo import models, fields


class ServiceProvider(models.Model):
    _name = 'apcentral.service.provider'
    _description = 'Service Provider'
    _rec_name = 'name'

    # -------------------------
    # Identity
    # -------------------------
    name = fields.Char(string="Service Provider Name", required=True)

    # -------------------------
    # Classification
    # -------------------------
    service_type = fields.Selection([
        ('plumbing', 'Plumbing'),
        ('electrical', 'Electrical'),
        ('fumigation', 'Fumigation'),
        ('cleaning', 'Cleaning'),
        ('security', 'Security'),
        ('internet', 'Internet'),
        ('other', 'Other')
    ], string="Service Type", required=True)

    # -------------------------
    # Contact Details
    # -------------------------
    contact_person = fields.Char(string="Contact Person")
    phone = fields.Char(string="Phone")
    email = fields.Char(string="Email")

    # -------------------------
    # System
    # -------------------------
    active = fields.Boolean(default=True)