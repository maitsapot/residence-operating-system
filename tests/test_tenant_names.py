from types import SimpleNamespace

from app.api.users.tenants import _tenant_full_name


def test_tenant_full_name_omits_seed_prefix():
    user = SimpleNamespace(
        first_name="Seed076",
        middle_name=None,
        last_name="Mokoena",
    )

    assert _tenant_full_name(user) == "Mokoena"


def test_tenant_full_name_falls_back_when_only_seed_parts_exist():
    user = SimpleNamespace(
        first_name="seed87",
        middle_name=None,
        last_name="",
    )

    assert _tenant_full_name(user) == "Tenant"
