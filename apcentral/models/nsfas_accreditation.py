from odoo import models, fields


class NsfasAccreditation(models.Model):
    _name = 'apcentral.nsfas.accreditation'
    _description = 'NSFAS Accreditation'

    residence_id = fields.Many2one(
        'apcentral.residence',
        string="Residence",
        required=True,
        ondelete='cascade',
        index=True
    )

    company_id = fields.Many2one(
        'res.company',
        related='residence_id.company_id',
        store=True,
        readonly=True
    )

    accreditation_number = fields.Char(string="Accreditation Number")
    start_date = fields.Date(string="Start Date")
    end_date = fields.Date(string="End Date")

    notes = fields.Text(string="Notes")