from odoo import models, fields


class ResidenceService(models.Model):
    _name = 'apcentral.residence.service'
    _description = 'Residence Service'

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

    provider_id = fields.Many2one(
        'apcentral.service.provider',
        string="Service Provider",
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
    # Contract Details
    # -------------------------
    contract_start = fields.Date(string="Contract Start")
    contract_end = fields.Date(string="Contract End")

    # -------------------------
    # Notes
    # -------------------------
    notes = fields.Text(string="Notes")