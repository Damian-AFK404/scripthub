local http = game:GetService("HttpService")

-- 1. GitHub Basis-Einstellungen
local GITHUB_USER = "Damian-AFK404"
local GITHUB_REPO = "scripthub"
local BASE_URL = "https://raw.githubusercontent.com/" .. GITHUB_USER .. "/" .. GITHUB_REPO .. "/main/"

getgenv().getgitpath = function(subfolder)
    if subfolder then
        return BASE_URL .. subfolder .. "/"
    end
    return BASE_URL
end

-- 2. INTELLIGENTES LADEN DER ui.lua (Sucht im Hauptordner UND im src-Ordner) 1
local uiScript = nil
local pathsToTry = {
    BASE_URL .. "ui.lua",         -- Pfad 1: Hauptverzeichnis
    BASE_URL .. "src/ui.lua"       -- Pfad 2: src-Unterordner
}

for _, path in ipairs(pathsToTry) do
    local success, content = pcall(function()
        return game:HttpGet(path)
    end)
    if success and content and not content:find("404: Not Found") then
        uiScript = content
        break
    end
end

if not uiScript then
    error("Script Hub Fehler: ui.lua konnte nirgendwo auf GitHub gefunden werden! (Prüfe den Dateinamen)")
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
        local gameScriptSuccess, gameScript = pcall(function()
            return loadstring(game:HttpGet(BASE_URL .. "games/" .. scriptFile))()
        end)

        if gameScriptSuccess and type(gameScript) == "function" then
            gameScript(ScriptsTab, data)
        else
            warn("Spiel-Skript '" .. tostring(scriptFile) .. "' konnte nicht geladen werden.")
        end
    end
end
