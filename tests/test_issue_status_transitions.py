from types import SimpleNamespace

from app.api.issues.issues import validate_status_transition


def test_issue_status_transition_happy_path():
    issue = SimpleNamespace(status="open")

    assert validate_status_transition(issue, "assigned")

    issue.status = "assigned"
    assert validate_status_transition(issue, "in_progress")

    issue.status = "in_progress"
    assert validate_status_transition(issue, "resolved")

    issue.status = "resolved"
    assert validate_status_transition(issue, "closed")


def test_issue_status_transition_rejects_invalid_jump():
    issue = SimpleNamespace(status="open")

    assert not validate_status_transition(issue, "resolved")
    assert not validate_status_transition(issue, "closed")


def test_issue_status_transition_allows_rejection_from_any_state():
    for status in ["open", "assigned", "in_progress", "resolved", "closed"]:
        issue = SimpleNamespace(status=status)
        assert validate_status_transition(issue, "rejected")
