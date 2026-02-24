# LS-Keys (FiveM)

Framework-agnostic vehicle key module designed to plug into any framework, garage script, or dealership script.

## Features

- Vehicle keys with metadata (plate, model, serial, timestamp)
- Realistic key fob NUI (lock/unlock, remote start, alarm, trunk)
- Usable key item support
- Keychain item support (multiple vehicle keys in one item flow)
- Export API for garage/dealership integrations
- Optional inventory bridges:
  - `ox_inventory`
  - `qb-inventory` (+ `qb-core` usable item registration)
- Fallback commands if no inventory bridge is active

## Installation

1. Put the resource in your server resources folder as `ls_keys`.
2. Ensure it in server.cfg:

   `ensure ls_keys`

3. Create matching inventory items in your inventory script:

- `vehicle_key`
- `keychain`

4. Start server.

## Commands (fallback)

When no inventory bridge is found (or if enabled), these are available:

- `/keyfob` - open fob for nearby vehicle
- `/usekey [plate]` - open fob directly for a plate
- `/usekeychain` - open keychain selector

## Exports

### `CreateVehicleKey(source, plate, model, addToKeychain)`
Create and assign a vehicle key.

### `RemoveVehicleKey(source, plate)`
Remove key access for a plate.

### `HasVehicleKey(source, plate)`
Returns whether player has key (single key or keychain).

### `GiveVehiclePurchaseKeys(source, vehicle)`
Convenience for dealership scripts.

Vehicle table example:

```lua
{
  plate = 'ABC123',
  model = 'Sultan RS'
}
```

### `GetPlayerVehicleKeys(source)`
Returns key data for player.

## Example integrations

Dealership purchase:

```lua
local result = exports['ls_keys']:GiveVehiclePurchaseKeys(source, {
  plate = vehiclePlate,
  model = vehicleLabel
})

if not result.ok then
  print(result.error)
end
```

Garage vehicle retrieval:

```lua
if not exports['ls_keys']:HasVehicleKey(source, plate) then
  exports['ls_keys']:CreateVehicleKey(source, plate, model, true)
end
```

## Notes

- Key data is persisted in `data/keys.json`.
- You can rename items in `shared/config.lua`.
- For `ox_inventory`, metadata is attached directly to key item.
