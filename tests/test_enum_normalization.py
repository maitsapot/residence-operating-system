import pytest
from pydantic import ValidationError

from app.schemas.common_issue import CommonIssueCreate
from app.schemas.space import SpaceCreate
from app.schemas.space_item_template import SpaceItemTemplateCreate


ZERO_UUID = "00000000-0000-0000-0000-000000000000"


def test_issue_urgency_uses_urgent_not_immediate():
    CommonIssueCreate(
        catalog_id=ZERO_UUID,
        issue_name="Condition Issue",
        default_urgency="urgent",
    )

    with pytest.raises(ValidationError):
        CommonIssueCreate(
            catalog_id=ZERO_UUID,
            issue_name="Condition Issue",
            default_urgency="immediate",
        )


def test_space_type_uses_structural_space_values():
    SpaceCreate(
        residence_id=ZERO_UUID,
        name="Room 101",
        space_type="room",
    )

    with pytest.raises(ValidationError):
        SpaceCreate(
            residence_id=ZERO_UUID,
            name="Room 101",
            space_type="ensuite",
        )


def test_template_space_type_does_not_accept_room_layout_values():
    SpaceItemTemplateCreate(
        catalog_id=ZERO_UUID,
        space_type="room",
    )

    with pytest.raises(ValidationError):
        SpaceItemTemplateCreate(
            catalog_id=ZERO_UUID,
            space_type="single",
        )
