local Store = {
    players = {}
}

local function ensureDataDir()
    local content = LoadResourceFile(GetCurrentResourceName(), Config.StorageFile)
    if content then return end
    SaveResourceFile(GetCurrentResourceName(), Config.StorageFile, json.encode({ players = {} }, { indent = true }), -1)
end

local function loadStore()
    ensureDataDir()
    local content = LoadResourceFile(GetCurrentResourceName(), Config.StorageFile)
    if not content or content == '' then
        Store = { players = {} }
        return
    end

    local ok, decoded = pcall(json.decode, content)
    if ok and decoded and type(decoded) == 'table' then
        Store = decoded
        Store.players = Store.players or {}
    else
        Store = { players = {} }
    end
end

local function saveStore()
    SaveResourceFile(GetCurrentResourceName(), Config.StorageFile, json.encode(Store, { indent = true }), -1)
end

local function getPlayerRecord(identifier)
    Store.players[identifier] = Store.players[identifier] or {
        keys = {},
        keychain = { keys = {} }
    }
    Store.players[identifier].keys = Store.players[identifier].keys or {}
    Store.players[identifier].keychain = Store.players[identifier].keychain or { keys = {} }
    Store.players[identifier].keychain.keys = Store.players[identifier].keychain.keys or {}
    return Store.players[identifier]
end

local function createKeyMetadata(plate, model)
    plate = Utils.NormalizePlate(plate)
    return {
        plate = plate,
        model = model or 'Unknown',
        serial = Utils.RandomSerial(),
        createdAt = os.time(),
        type = 'vehicle_key'
    }
end

local function playerHasKeyData(record, plate)
    plate = Utils.NormalizePlate(plate)
    for _, key in ipairs(record.keys) do
        if Utils.NormalizePlate(key.plate) == plate then
            return true
        end
    end
    for _, key in ipairs(record.keychain.keys) do
        if Utils.NormalizePlate(key.plate) == plate then
            return true
        end
    end
    return false
end

local function addKeyToPlayer(source, plate, model, addToKeychain)
    local identifier = Bridge.GetIdentifier(source)
    local record = getPlayerRecord(identifier)

    if playerHasKeyData(record, plate) then
        return false, 'Player already has key for this vehicle'
    end

    local metadata = createKeyMetadata(plate, model)

    if addToKeychain then
        record.keychain.keys[#record.keychain.keys + 1] = metadata
    else
        record.keys[#record.keys + 1] = metadata
    end

    saveStore()
    TriggerClientEvent('ls-keys:client:syncKeys', source, record)

    if not addToKeychain then
        Bridge.Inventory.AddItem(source, Config.Items.key, 1, metadata)
    end

    return true, metadata
end

local function removeKeyFromPlayer(source, plate)
    plate = Utils.NormalizePlate(plate)
    local identifier = Bridge.GetIdentifier(source)
    local record = getPlayerRecord(identifier)

    local removed = false
    for i = #record.keys, 1, -1 do
        if Utils.NormalizePlate(record.keys[i].plate) == plate then
            table.remove(record.keys, i)
            removed = true
        end
    end

    for i = #record.keychain.keys, 1, -1 do
        if Utils.NormalizePlate(record.keychain.keys[i].plate) == plate then
            table.remove(record.keychain.keys, i)
            removed = true
        end
    end

    if removed then
        saveStore()
        TriggerClientEvent('ls-keys:client:syncKeys', source, record)
    end

    return removed
end

local function hasKey(source, plate)
    local identifier = Bridge.GetIdentifier(source)
    local record = getPlayerRecord(identifier)
    return playerHasKeyData(record, plate)
end

RegisterNetEvent('ls-keys:server:requestKeys', function()
    local src = source
    local identifier = Bridge.GetIdentifier(src)
    local record = getPlayerRecord(identifier)
    TriggerClientEvent('ls-keys:client:syncKeys', src, record)
end)

RegisterNetEvent('ls-keys:server:fobAction', function(action, plate, netId)
    local src = source
    plate = Utils.NormalizePlate(plate)

    if not hasKey(src, plate) then
        TriggerClientEvent('ls-keys:client:notify', src, 'No key for this vehicle')
        return
    end

    TriggerClientEvent('ls-keys:client:performFobAction', -1, action, plate, netId, src)
end)

RegisterNetEvent('ls-keys:server:addToKeychain', function(plate, model)
    local src = source
    local ok, msg = addKeyToPlayer(src, plate, model, true)
    if ok then
        TriggerClientEvent('ls-keys:client:notify', src, ('Added %s to keychain'):format(Utils.NormalizePlate(plate)))
    else
        TriggerClientEvent('ls-keys:client:notify', src, msg or 'Failed to add key')
    end
end)

Bridge.Inventory.RegisterUsableItem(Config.Items.key, function(source, item)
    local meta = item.metadata or item.info or {}
    if not meta.plate then
        TriggerClientEvent('ls-keys:client:notify', source, 'Invalid key metadata')
        return
    end
    TriggerClientEvent('ls-keys:client:openFob', source, {
        plate = Utils.NormalizePlate(meta.plate),
        model = meta.model or 'Unknown'
    })
end)

Bridge.Inventory.RegisterUsableItem(Config.Items.keychain, function(source, item)
    local identifier = Bridge.GetIdentifier(source)
    local record = getPlayerRecord(identifier)
    TriggerClientEvent('ls-keys:client:openKeychain', source, record.keychain.keys)
end)

if Config.EnableFallbackUseCommands then
    RegisterCommand('usekey', function(source, args)
        if source <= 0 then return end
        local plate = Utils.NormalizePlate(args[1] or '')
        if plate == '' then
            TriggerClientEvent('ls-keys:client:notify', source, 'Usage: /usekey [plate]')
            return
        end
        if not hasKey(source, plate) then
            TriggerClientEvent('ls-keys:client:notify', source, 'No key for this vehicle')
            return
        end
        TriggerClientEvent('ls-keys:client:openFob', source, { plate = plate })
    end, false)

    RegisterCommand('usekeychain', function(source)
        if source <= 0 then return end
        local identifier = Bridge.GetIdentifier(source)
        local record = getPlayerRecord(identifier)
        TriggerClientEvent('ls-keys:client:openKeychain', source, record.keychain.keys)
    end, false)
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    loadStore()
end)

AddEventHandler('playerDropped', function()
    saveStore()
end)

exports('CreateVehicleKey', function(source, plate, model, addToKeychain)
    local ok, dataOrError = addKeyToPlayer(source, plate, model, addToKeychain == true)
    return {
        ok = ok,
        data = ok and dataOrError or nil,
        error = ok and nil or dataOrError
    }
end)

exports('RemoveVehicleKey', function(source, plate)
    return removeKeyFromPlayer(source, plate)
end)

exports('HasVehicleKey', function(source, plate)
    return hasKey(source, plate)
end)

exports('GiveVehiclePurchaseKeys', function(source, vehicle)
    if type(vehicle) ~= 'table' then
        return {
            ok = false,
            error = 'vehicle table required'
        }
    end

    local ok, dataOrError = addKeyToPlayer(source, vehicle.plate, vehicle.model or vehicle.name, true)
    return {
        ok = ok,
        data = ok and dataOrError or nil,
        error = ok and nil or dataOrError
    }
end)

exports('GetPlayerVehicleKeys', function(source)
    local identifier = Bridge.GetIdentifier(source)
    local record = getPlayerRecord(identifier)
    return Utils.DeepCopy(record)
end)
