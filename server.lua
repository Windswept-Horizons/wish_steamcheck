-- wish_steamcheck | console-only diagnostics for the Cfx Steam auth update (Nov 4, 2026)
-- WHY: Many frameworks (VORP included) store every account by its steam: identifier.
-- If that ID is missing or different after the update, the player gets a blank account
-- ("my characters are gone!"). This lets you spot it in the console before players report it.

local TAG = '^3[wish_steamcheck]^7 '
local function line(msg) print(TAG .. msg) end

local function artifactBuild()
    -- 'version' convar looks like: FXServer-master SERVER v1.0.0.38004 win32
    local v = GetConvar('version', 'unknown')
    return v, tonumber(v:match('v%d+%.%d+%.%d+%.(%d+)'))
end

local function dbReady()
    if not Config.CheckDatabase then return false, 'disabled in config' end
    if GetResourceState('oxmysql') ~= 'started' then return false, 'oxmysql not started' end
    -- table/column come from config and are pasted into SQL, so allow only plain names
    if not (Config.DbTable:match('^[%w_]+$') and Config.DbColumn:match('^[%w_]+$')) then
        return false, 'invalid DbTable/DbColumn name'
    end
    return true
end

local function countRows(steam, cb)
    local q = ('SELECT COUNT(*) FROM `%s` WHERE `%s` = ?'):format(Config.DbTable, Config.DbColumn)
    exports.oxmysql:scalar(q, { steam }, cb)
end

RegisterCommand(Config.CommandName, function(src)
    if src ~= 0 then return end -- server console / txAdmin live console only

    local v, build = artifactBuild()
    line(('Artifact: %s'):format(v))
    if build and build >= Config.MinArtifact then
        line(('^2OK^7 build %d >= %d'):format(build, Config.MinArtifact))
    else
        line(('^1UPDATE NEEDED^7 build %s < %d'):format(tostring(build), Config.MinArtifact))
    end

    local enforce = GetConvar('sv_enforceSteamAuth', 'unset')
    line(('sv_enforceSteamAuth = %s %s'):format(enforce, enforce == 'true' and '^2OK^7' or '^1(expected true)^7'))
    local key = GetConvar('steam_webApiKey', '')
    line(('steam_webApiKey     = %s'):format((key ~= '' and key ~= 'none') and 'SET (deprecated, harmless)' or 'not set'))

    local useDb, why = dbReady()
    if not useDb then line(('Database check skipped: %s'):format(why)) end

    local players = GetPlayers()
    line(('Players online: %d'):format(#players))
    for _, pid in ipairs(players) do
        local name = GetPlayerName(pid) or '?'
        local steam = GetPlayerIdentifierByType(pid, 'steam')
        if not steam then
            line(('^1[%s] %s -> NO steam: identifier^7'):format(pid, name))
        elseif not useDb then
            line(('[%s] %s -> %s'):format(pid, name, steam))
        else
            countRows(steam, function(n)
                local status = (n and n > 0) and ('^2%d character(s)^7'):format(n)
                    or '^3no characters (new player OR wrong Steam account linked)^7'
                line(('[%s] %s -> %s | %s'):format(pid, name, steam, status))
            end)
        end
    end
end, true)

if Config.LogConnections then
    AddEventHandler('playerConnecting', function(name)
        local steam = GetPlayerIdentifierByType(source, 'steam')
        if steam then
            line(('connect: %s -> %s'):format(name, steam))
        else
            line(('^1connect: %s -> NO steam: identifier (Steam-keyed frameworks will refuse or make a blank account)^7'):format(name))
        end
    end)
end

CreateThread(function()
    Wait(2000)
    local _, build = artifactBuild()
    if not build or build < Config.MinArtifact then
        line(('^1Artifact %s is below %d - Steam IDs may stop arriving after the Cfx update.^7'):format(tostring(build), Config.MinArtifact))
    end
    line(('Loaded v1.0.3. Run ^5%s^7 in console to audit online players.'):format(Config.CommandName))
end)
