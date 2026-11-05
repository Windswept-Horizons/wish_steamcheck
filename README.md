# wish_steamcheck

Console-only diagnostics for the **Cfx.re Steam authentication update (Nov 4, 2026)** on **RedM and FiveM** servers.

Built by **WiSH Development** for Windswept Horizons. *Ad Astra Per Aspera!* 🐺

## Who this is for

This is a tool for **server owners and developers** who are already comfortable with:
- editing `server.cfg` and adding `ensure` lines to their resources config
- updating FXServer artifacts and keeping a rollback copy
- using the server console or txAdmin Live Console
- running a PowerShell (or bash) command from a folder
- reading basic Lua config files

If those are new to you, ask your server's developer, your framework's community, or an AI assistant to walk you through them first.

**Support:** provided **as-is**, free, with **no support of any kind**: no setup help, no troubleshooting, no bug reports. Server setup and framework questions belong in your framework's own Discord.

**Tested baseline:** RedM + VORP Core on Windows, FXServer artifact **38004**, txAdmin 8.1.2, on **Nov 4, 2026** (after the Cfx Steam switch), with no errors. FiveM is supported by the manifest but has not been tested by the author.

## Why this exists

On Nov 4, 2026, Cfx moved Steam verification to the player's linked Cfx account:

- `steam_webApiKey` is **deprecated**.
- Servers that rely on Steam IDs must run **FXServer artifact 38004 or newer**.
- Servers that require Steam should set `set sv_enforceSteamAuth true`.

Many frameworks (VORP Core included) save every account under the player's `steam:` identifier. If that ID is missing or different, the player lands on a **blank account** and thinks their characters are gone. Their data is still there, just under the old ID.

This resource shows you that problem **in the console, before players report it.**

## Players can't connect? Check these first

| Symptom | Likely cause | Fix |
|---|---|---|
| Nobody gets a Steam ID, or players are refused/kicked by the framework | Artifact older than 38004 | Update FXServer to 38004+ (current *recommended* is safest) |
| Players join with no `steam:` ID and get a blank/new account | `sv_enforceSteamAuth` not set | Add `set sv_enforceSteamAuth true` to server.cfg |
| "Steam authentication required" prompt | Normal! New Cfx flow | Player clicks **Accept** → **Link Account** in the browser window |
| "Connection failed" right after "Auth Successful" | Normal! RedM/FiveM needs a restart to pick up the link | Player closes the game completely and reopens it |
| A regular player's characters are "gone" | They linked a **different** Steam account (roommate, sibling, alt) | Player unlinks it in game settings, links their main account, restarts |
| Server boots but some resources skip startup or features vanish | A resource still requires `steam_webApiKey` | Run the scan below; keep the key line until those resources are updated |

A step-by-step player guide with screenshots: https://www.wish-rp.com/get-started/redm-connection-guide/redm-steam-login-guide

## What it does

| When | What it prints |
|---|---|
| Server boot | A red warning if the artifact is below 38004 |
| Every connection | `connect: Name -> steam:1100001...`, or a red warning if no Steam ID arrived |
| Console command `wish_steamcheck` | Artifact build (pass/fail), `sv_enforceSteamAuth`, `steam_webApiKey`, and each online player's Steam ID with their saved character count |

It is console-only (players cannot run the command) and **read-only**: it never changes your database.

## Install

1. **Back up your database**, and keep your old artifacts folder for rollback.
2. Update FXServer to **artifact 38004 or newer**.
3. Drop the `wish_steamcheck` folder into `resources`.
4. Add `ensure wish_steamcheck` **after** `ensure oxmysql`.
5. Apply the `server.cfg` block from `server-cfg.txt`.
6. Restart, join, and run `wish_steamcheck` in the server console or the txAdmin Live Console.

Test on a dev/test server first if you have one.

## Configuration (`config.lua`)

| Setting | Default | Notes |
|---|---|---|
| `MinArtifact` | `38004` | Build Cfx requires |
| `CommandName` | `'wish_steamcheck'` | Console command name |
| `LogConnections` | `true` | One line per connection |
| `CheckDatabase` | `true` | Needs oxmysql; set `false` to skip |
| `DbTable` / `DbColumn` | `'characters'` / `'identifier'` | VORP defaults. Point at whatever table/column stores your `steam:` IDs |

## Reading the output

```
[wish_steamcheck] Artifact: FXServer-master SERVER v1.0.0.38004 win32
[wish_steamcheck] OK build 38004 >= 38004
[wish_steamcheck] sv_enforceSteamAuth = true OK
[wish_steamcheck] steam_webApiKey     = SET (deprecated, harmless)
[wish_steamcheck] Players online: 1
[wish_steamcheck] [1] Coyote -> steam:11000013f56281d | 5 character(s)
```

- **`N character(s)`**: the ID matches saved data. ✅
- **`no characters`** for a known regular: they most likely linked a **different Steam account**.
- **`NO steam: identifier`**: Steam didn't come through. Check the artifact build and `sv_enforceSteamAuth`.

## Find resources that depend on the Steam key or Steam IDs

Before removing `steam_webApiKey`, find out what still uses it. Run in **PowerShell** from your server's `resources` folder:

**1. Resources that check `steam_webApiKey` or call the Steam Web API (most important):**

```powershell
Get-ChildItem -Recurse -Include *.lua,*.js | Select-String "steam_webApiKey|api.steampowered" | Select-Object Path, LineNumber, Line
```

Anything listed here may skip startup, hide features, or print warnings once the key is gone. Keep the key until each one is updated.

**2. Resources that read Steam IDs (good to know, usually fine):**

```powershell
Get-ChildItem -Recurse -Include *.lua,*.js | Select-String "GetPlayerIdentifierByType\(.*steam|['""]steam:" | Select-Object Path, LineNumber, Line
```

These rely on players having a `steam:` ID. With artifact 38004+ and `sv_enforceSteamAuth true` they keep working, and `wish_steamcheck` confirms it live.

**Linux:**

```bash
grep -rnE "steam_webApiKey|api\.steampowered" --include=*.lua --include=*.js .
grep -rnE "GetPlayerIdentifierByType\(.*steam|[\"']steam:" --include=*.lua --include=*.js .
```

## VORP Core note ⚠️

Older VORP Core versions (before **Nov 4, 2026**) stop `server/init.lua` early if `steam_webApiKey` is blank:

```lua
local steamwebapikey = GetConvar("steam_webApiKey", "") == ""
if steamwebapikey then
    return print("Steam Web API Key is not set, please set it in your server.cfg")
end
```

Logins still load, but the startup banner, version checker and **database auto-updater** silently stop. VORP removed this check on Nov 4, 2026. **Either update vorp_core, or keep the key line** until you do.

## Removal

Once things have settled (a week or two), remove `ensure wish_steamcheck`. Nothing depends on it.

## Player's Guide

Feel free to share [this guide](https://www.wish-rp.com/get-started/redm-connection-guide/redm-steam-login-guide) I wrote for my community. It has step by step instructions, including a small troubleshooting section.

## License

MIT (see `LICENSE`). Use it, share it, improve it. 🐺
