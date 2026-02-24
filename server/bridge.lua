Bridge = {}

local function hasExport(resource, exportName)
    return GetResourceState(resource) == 'started' and exports[resource] and exports[resource][exportName]
end

Bridge.Inventory = {
    type = 'fallback'
}

-- ox_inventory bridge (recommended)
if hasExport('ox_inventory', 'RegisterUsableItem') then
    Bridge.Inventory.type = 'ox_inventory'

    function Bridge.Inventory.RegisterUsableItem(name, cb)
        exports.ox_inventory:RegisterUsableItem(name, function(source, item)
            cb(source, item)
        end)
    end

    function Bridge.Inventory.AddItem(source, name, amount, metadata)
        return exports.ox_inventory:AddItem(source, name, amount or 1, metadata or {})
    end

    function Bridge.Inventory.RemoveItem(source, name, amount, metadata)
        return exports.ox_inventory:RemoveItem(source, name, amount or 1, metadata)
    end

    function Bridge.Inventory.GetItems(source, name)
        local inv = exports.ox_inventory:GetInventoryItems(source)
        local out = {}
        if not inv then return out end
        for _, item in pairs(inv) do
            if item and item.name == name then
                out[#out + 1] = item
            end
        end
        return out
    end

-- qb-inventory minimal bridge
elseif hasExport('qb-inventory', 'AddItem') then
    Bridge.Inventory.type = 'qb-inventory'

    function Bridge.Inventory.RegisterUsableItem(name, cb)
        if GetResourceState('qb-core') == 'started' then
            local QBCore = exports['qb-core']:GetCoreObject()
            QBCore.Functions.CreateUseableItem(name, function(source, item)
                cb(source, item)
            end)
        end
    end

    function Bridge.Inventory.AddItem(source, name, amount, metadata)
        return exports['qb-inventory']:AddItem(source, name, amount or 1, false, metadata or {})
    end

    function Bridge.Inventory.RemoveItem(source, name, amount, metadata)
        return exports['qb-inventory']:RemoveItem(source, name, amount or 1, false, metadata)
    end

    function Bridge.Inventory.GetItems(source, name)
        local items = exports['qb-inventory']:GetItemsByName(source, name) or {}
        return items
    end

else
    function Bridge.Inventory.RegisterUsableItem(name, cb)
        -- fallback command handled in server/main.lua
    end

    function Bridge.Inventory.AddItem(source, name, amount, metadata)
        return false
    end

    function Bridge.Inventory.RemoveItem(source, name, amount, metadata)
        return false
    end

    function Bridge.Inventory.GetItems(source, name)
        return {}
    end
end

function Bridge.GetIdentifier(source)
    local ids = GetPlayerIdentifiers(source)
    for _, id in ipairs(ids) do
        if id:find('license:') == 1 then
            return id
        end
    end
    return ids[1] or ('src:' .. tostring(source))
end
