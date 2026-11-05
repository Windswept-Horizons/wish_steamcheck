Config = {}

-- Minimum FXServer build Cfx requires for the new Steam auth flow.
Config.MinArtifact   = 38004

-- Console command name.
Config.CommandName   = 'wish_steamcheck'

-- Print one line per player connection (name -> steam ID, or a red warning).
Config.LogConnections = true

-- Count saved characters per Steam ID (needs oxmysql).
-- VORP:        table 'characters', column 'identifier'  (default)
-- RSG / other: point these at whatever table/column stores the steam: identifier,
--              or set CheckDatabase = false to skip the DB lookup entirely.
Config.CheckDatabase = true
Config.DbTable       = 'characters'
Config.DbColumn      = 'identifier'
