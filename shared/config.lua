Config = {}

-- Item names (change to match your inventory)
Config.Items = {
    key = 'vehicle_key',
    keychain = 'keychain'
}

-- Commands / controls
Config.Commands = {
    openFob = 'keyfob'
}

Config.Keybind = {
    description = 'Open Key Fob',
    defaultMapper = 'keyboard',
    defaultKey = 'F10'
}

-- Vehicle search ranges
Config.Ranges = {
    fobVehicleSearch = 80.0,
    lockAction = 80.0,
    trunkAction = 12.0,
    remoteStart = 60.0,
    alarm = 80.0
}

-- If true, enables simple fallback chat command item usage when no inventory bridge exists
Config.EnableFallbackUseCommands = true

-- Persistence file
Config.StorageFile = 'data/keys.json'
