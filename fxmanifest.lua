--[[ ===================================================== ]] --
--[[             MH Auto Park Script by MaDHouSe           ]] --
--[[ ===================================================== ]] --
fx_version 'cerulean'
games {'gta5'}

author 'MaDHouSe'
description 'MH Auto Park - To save vehicle at when you get out the vehicle you own.'
version '1.0.0'

shared_scripts {
    'config.lua', 
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua', 
    'server/main.lua',
    'server/update.lua',
}

lua54 'yes'
