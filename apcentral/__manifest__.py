{
    'name': 'AP Central',
    'summary': 'Accommodation Provider Central Portal',
    'version': '1.0',
    'depends': ['base', 'website'],
    'data': [
        # Security (order matters)
        'security/groups.xml',
        'security/ir.model.access.csv',
        'security/rules.xml',

        # Views
        'views/residence_views.xml',
        'views/register_template.xml',
    ],
    'application': True,
    'installable': True,
    'license': 'LGPL-3',
    'author': 'Nolwazi',
}