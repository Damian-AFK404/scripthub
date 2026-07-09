local http = game:GetService("HttpService")

-- 1. Definiere den GitHub-Pfad absolut sauber (OHNE riskante Verkettungen)
-- ERSETZE 'DEIN_GITHUB_NAME' und 'DEIN_REPO' mit deinen echten GitHub-Daten!
local GITHUB_USER = "Damian-AFK404"
local GITHUB_REPO = "DEIN_REPO"
local BASE_URL = "https://raw.githubusercontent.com/" .. GITHUB_USER .. "/" .. GITHUB_REPO .. "/main/"

getgenv().getgitpath = function(subfolder)
    if subfolder then
        return BASE_URL .. subfolder .. "/"
    end
    return BASE_URL
end

-- 2. Lade das Hauptmenü (ui.lua) direkt über die saubere URL
local uiSuccess, uiScript = pcall(function()
    return game:HttpGet(BASE_URL .. "ui.lua")
end)

if not uiSuccess then
    error("Script Hub Fehler: ui.lua konnte nicht von GitHub geladen werden! (Pfad prüfen)")
end

local ui = loadstring(uiScript)()
local Window, ScriptsTab = ui:Init()

-- 3. Config-Daten für die Spiele laden
local data = {}
pcall(function()
    if isfile("BrainrotPolice/Config.json") then
        data = http:JSONDecode(readfile("BrainrotPolice/Config.json"))
    end
end)

-- 4. Spiel automatisch erkennen und aus der gameslist.json laden
local placeIdStr = tostring(game.PlaceId)
local listSuccess, gamesListText = pcall(function() 
    return game:HttpGet(BASE_URL .. "gameslist.json") 
end)

if listSuccess then
    local gamesList = http:JSONDecode(gamesListText)
    local scriptFile = gamesList[placeIdStr]

    if scriptFile then
        -- Lädt das spezifische Skript aus dem games/ Ordner
        local gameScriptSuccess, gameScript = pcall(function()
            return loadstring(game:HttpGet(BASE_URL .. "games/" .. scriptFile))()
        end)

        if gameScriptSuccess and type(gameScript) == "function" then
            -- Übergibt den ScriptsTab an das Spiel-Skript
            gameScript(ScriptsTab, data)
        else
            warn("Spiel-Skript '" .. tostring(scriptFile) .. "' konnte nicht geladen werden.")
        end
    end
else
    warn("gameslist.json konnte nicht von GitHub geladen werden.")
end
