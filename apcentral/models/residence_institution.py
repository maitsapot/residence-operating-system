from odoo import models, fields


class ResidenceInstitution(models.Model):
    _name = 'apcentral.residence.institution'
    _description = 'Residence Institution Relationship'

    # -------------------------
    # Relationships
    # -------------------------
    residence_id = fields.Many2one(
        'apcentral.residence',
        string="Residence",
        required=True,
        ondelete='cascade',
        index=True
    )

    institution_id = fields.Many2one(
        'apcentral.institution',
        string="Institution",
        required=True,
        index=True
    )

    # -------------------------
    # Multi-company (inherited)
    # -------------------------
    company_id = fields.Many2one(
        'res.company',
        string="Company",
        related='residence_id.company_id',
        store=True,
        index=True,
        readonly=True
    )

    # -------------------------
    # Logistics
    # -------------------------
    distance_km = fields.Float(string="Distance (km)")
    travel_time_minutes = fields.Integer(string="Travel Time (Minutes)")

    # -------------------------
    # Business Logic
    # -------------------------
    is_primary = fields.Boolean(string="Primary Institution")
    notes = fields.Text(string="Notes")