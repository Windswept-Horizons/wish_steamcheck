fx_version 'cerulean'
games { 'rdr3', 'gta5' } -- works on RedM and FiveM
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'wish_steamcheck'
description 'Console-only diagnostics for the Nov 2026 Cfx Steam auth change: artifact build, Steam convars, and each player\'s steam: ID vs your database.'
author 'WiSH Development | "Ad Astra Per Aspera!"'
version '1.0.3'

server_scripts {
    'config.lua',
    'server.lua',
}
-- oxmysql is OPTIONAL: only used when Config.CheckDatabase = true