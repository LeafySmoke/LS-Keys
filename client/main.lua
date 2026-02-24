local PlayerKeys = {
    keys = {},
    keychain = { keys = {} }
}

local uiOpen = false

local function notify(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, false)
end

RegisterNetEvent('ls-keys:client:notify', function(msg)
    notify(msg)
end)

local function normalizePlate(plate)
    if not plate then return '' end
    plate = string.upper((plate:gsub('^%s*(.-)%s*$', '%1')))
    plate = plate:gsub('%s+', '')
    return plate
end

local function getVehicleByNetOrPlate(netId, plate)
    if netId and netId > 0 then
        local veh = NetToVeh(netId)
        if DoesEntityExist(veh) then return veh end
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicles = GetGamePool('CVehicle')
    local nearest, nearestDist = 0, Config.Ranges.fobVehicleSearch

    for _, veh in ipairs(vehicles) do
        if DoesEntityExist(veh) then
            local p = normalizePlate(GetVehicleNumberPlateText(veh))
            if p == normalizePlate(plate) then
                local dist = #(coords - GetEntityCoords(veh))
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = veh
                end
            end
        end
    end

    return nearest
end

local function flashLights(veh)
    SetVehicleLights(veh, 2)
    Wait(120)
    SetVehicleLights(veh, 0)
    Wait(120)
    SetVehicleLights(veh, 2)
    Wait(120)
    SetVehicleLights(veh, 0)
end

local function lockToggle(veh)
    local state = GetVehicleDoorLockStatus(veh)
    if state == 1 or state == 0 then
        SetVehicleDoorsLocked(veh, 2)
        PlayVehicleDoorCloseSound(veh, 1)
        notify('Vehicle locked')
    else
        SetVehicleDoorsLocked(veh, 1)
        PlayVehicleDoorOpenSound(veh, 0)
        notify('Vehicle unlocked')
    end
    flashLights(veh)
end

local function remoteStart(veh)
    local running = GetIsVehicleEngineRunning(veh)
    SetVehicleEngineOn(veh, not running, true, true)
    if running then
        notify('Engine off')
    else
        notify('Engine started')
    end
    flashLights(veh)
end

local function toggleAlarm(veh)
    StartVehicleAlarm(veh)
    SetVehicleAlarm(veh, true)
    notify('Alarm triggered')
    flashLights(veh)
end

local function toggleTrunk(veh)
    if GetVehicleDoorAngleRatio(veh, 5) > 0.1 then
        SetVehicleDoorShut(veh, 5, false)
        notify('Trunk closed')
    else
        SetVehicleDoorOpen(veh, 5, false, false)
        notify('Trunk opened')
    end
end

RegisterNetEvent('ls-keys:client:performFobAction', function(action, plate, netId, initiator)
    local myServerId = GetPlayerServerId(PlayerId())
    if initiator ~= myServerId then
        return
    end

    local veh = getVehicleByNetOrPlate(netId, plate)
    if veh == 0 then
        notify('Vehicle not found nearby')
        return
    end

    if action == 'lock' then
        lockToggle(veh)
    elseif action == 'remote_start' then
        remoteStart(veh)
    elseif action == 'alarm' then
        toggleAlarm(veh)
    elseif action == 'trunk' then
        toggleTrunk(veh)
    end
end)

local function openFob(payload)
    uiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        payload = payload
    })
end

local function closeFob()
    uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterNUICallback('close', function(_, cb)
    closeFob()
    cb({ ok = true })
end)

RegisterNUICallback('doAction', function(data, cb)
    if not data or not data.action or not data.plate then
        cb({ ok = false })
        return
    end

    local veh = getVehicleByNetOrPlate(0, data.plate)
    local netId = 0
    if veh ~= 0 then
        netId = VehToNet(veh)
    end

    TriggerServerEvent('ls-keys:server:fobAction', data.action, data.plate, netId)
    cb({ ok = true })
end)

RegisterNetEvent('ls-keys:client:openFob', function(keyData)
    openFob(keyData)
end)

RegisterNetEvent('ls-keys:client:openKeychain', function(keys)
    openFob({
        keychain = true,
        keys = keys
    })
end)

RegisterNetEvent('ls-keys:client:syncKeys', function(record)
    PlayerKeys = record or PlayerKeys
end)

CreateThread(function()
    TriggerServerEvent('ls-keys:server:requestKeys')

    RegisterCommand(Config.Commands.openFob, function()
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh == 0 then
            local coords = GetEntityCoords(ped)
            veh = GetClosestVehicle(coords.x, coords.y, coords.z, 6.0, 0, 70)
        end

        if veh == 0 then
            notify('No nearby vehicle')
            return
        end

        local plate = normalizePlate(GetVehicleNumberPlateText(veh))
        openFob({ plate = plate })
    end, false)

    RegisterKeyMapping(Config.Commands.openFob, Config.Keybind.description, Config.Keybind.defaultMapper, Config.Keybind.defaultKey)
end)
