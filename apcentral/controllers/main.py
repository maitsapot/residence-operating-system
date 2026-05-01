from odoo import http
from odoo.http import request


class APCentralController(http.Controller):

    @http.route(['/register', '/apcentral/register'], type='http', auth='public', website=True)
    def register_page(self, **kwargs):
        return request.render('apcentral.register_template')

    @http.route('/apcentral/register/submit', type='http', auth='public', methods=['POST'], website=True)
    def register_submit(self, **post):

        name = post.get('name')
        email = post.get('email')
        password = post.get('password')

        # Create partner (company)
        partner = request.env['res.partner'].sudo().create({
            'name': name,
            'email': email,
            'company_type': 'company'
        })

        # Create company
        company = request.env['res.company'].sudo().create({
            'name': name,
            'partner_id': partner.id
        })

        # Create user
        user = request.env['res.users'].sudo().create({
            'name': name,
            'login': email,
            'email': email,
            'password': password,
            'company_id': company.id,
            'company_ids': [(6, 0, [company.id])]
        })

        # Assign APCentral group
        group = request.env.ref('apcentral.group_user')
        user.groups_id = [(4, group.id)]

        # Auto login
        request.session.authenticate(request.db, email, password)

        return request.redirect('/web')