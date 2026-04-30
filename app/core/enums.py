from typing import Literal, TypeAlias


SpaceType: TypeAlias = Literal["room", "bathroom", "kitchen", "common", "other"]
TemplateType: TypeAlias = str
Standard: TypeAlias = str

Condition: TypeAlias = Literal["good", "fair", "poor", "damaged"]

SpaceItemStatus: TypeAlias = Literal["active", "removed", "missing", "damaged"]
ItemStatus: TypeAlias = Literal["active", "removed", "replaced"]

InspectionType: TypeAlias = Literal["routine", "checkin", "checkout", "audit"]
InspectionStatus: TypeAlias = Literal["draft", "completed"]

IssueStatus: TypeAlias = Literal[
    "open",
    "assigned",
    "in_progress",
    "resolved",
    "closed",
    "rejected",
]
IssueSeverity: TypeAlias = Literal["low", "medium", "high", "critical"]
IssueUrgency: TypeAlias = Literal["low", "medium", "high", "urgent"]

TenancyStatus: TypeAlias = Literal["active", "terminated", "completed"]
CategoryName: TypeAlias = Literal[
    "furniture",
    "structural",
    "electrical",
    "plumbing",
    "appliance",
    "hygiene",
    "security",
    "other",
]

InstitutionType: TypeAlias = Literal["university", "tvet", "private_college"]
