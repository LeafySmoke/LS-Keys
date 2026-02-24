fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'ls_keys'
author 'LS Keys'
description 'Framework-agnostic vehicle key system with key fob UI and keychain support'
version '1.0.0'

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js'
}

shared_scripts {
    'shared/config.lua',
    'shared/utils.lua'
}

server_scripts {
    'server/bridge.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}
