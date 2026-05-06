# Mobile QA Fixtures

## Room Inventory Verification

Use this fixture to verify the tenant room inventory flow in the mobile/web app.

### App Selection

- Residence: `Amelia Residence`
- Tenant: `Naledi Mphahlele`

### Entity IDs

- Residence ID: `60000000-0000-0000-0000-000000000001`
- Tenant/User ID: `07159784-a457-8146-051f-af5f072ab09c`
- Room/Space: `AE-003`
- Space ID: `81fe243e-46b3-9abc-abf3-17631ac16748`
- Tenancy status: `active`

### Navigation Path

1. Open the mobile app.
2. Select `Amelia Residence`.
3. Select tenant `Naledi Mphahlele`.
4. Tap `Proceed`.
5. Tap hero menu `My Room`.
6. Tap `Room Inventory`.

### Expected Summary

- Space item lines: `22`
- Attention items: `7`
- Required items: `22`
- Total quantity: `23`

### Expected Attention Items

| Item | Condition | Status |
| --- | --- | --- |
| Chair | poor | active |
| Curtain | fair | active |
| Door | fair | active |
| Food Rack | poor | active |
| Mattress | fair | active |
| Shower | poor | damaged |
| Toilet | fair | active |

### Expected Healthy Items

- Basin
- Bed Base
- BookShelf
- Ceiling
- Curtain Rail
- Door Lock
- Floor
- Geyser
- Light Fitting
- Plug Point
- Study Table
- Tap
- Wardrobe
- Waste Bin
- Window
