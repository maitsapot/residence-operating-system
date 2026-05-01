from odoo import models, api


class ResUsers(models.Model):
    _inherit = 'res.users'

    @api.model_create_multi
    def create(self, vals_list):
        users = super().create(vals_list)

        # Get APCentral User group
        group = self.env.ref('apcentral.group_user', raise_if_not_found=False)

        if group:
            for user in users:
                if group not in user.groups_id:
                    user.groups_id = [(4, group.id)]

        return users