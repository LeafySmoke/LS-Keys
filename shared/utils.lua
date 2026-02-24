Utils = {}

function Utils.NormalizePlate(plate)
    if not plate then return '' end
    plate = string.upper((plate:gsub('^%s*(.-)%s*$', '%1')))
    plate = plate:gsub('%s+', '')
    return plate
end

function Utils.RandomSerial()
    local chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
    local serial = ''
    for i = 1, 10 do
        local idx = math.random(1, #chars)
        serial = serial .. chars:sub(idx, idx)
    end
    return serial
end

function Utils.DeepCopy(tbl)
    if type(tbl) ~= 'table' then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = Utils.DeepCopy(v)
    end
    return copy
end
