local http = game:GetService("HttpService")

-- 1. Definiere den Pfad zu deinem Repository (HIER ANPASSEN!)
getgenv().getgitpath = function(subfolder)
    return "https://raw.githubusercontent.com/DEIN_GITHUB_NAME/DEIN_REPO/main/" .. (subfolder or "")
end

-- 2. Lade das Hauptmenü (ui.lua)
local ui = loadstring(game:HttpGet(getgitpath() .. "ui.lua"))()
local Window, ScriptsTab = ui:Init()

-- 3. Config-Daten für die Spiele laden
local data = {}
pcall(function()
    if isfile("BrainrotPolice/Config.json") then
        data = http:JSONDecode(readfile("BrainrotPolice/Config.json"))
    end
end)

-- 4. Spiel automatisch erkennen und laden
local placeIdStr = tostring(game.PlaceId)
local success, gamesListText = pcall(function() 
    return game:HttpGet(getgitpath() .. "gameslist.json") 
end)

if success then
    local gamesList = http:JSONDecode(gamesListText)
    local scriptFile = gamesList[placeIdStr]

    if scriptFile then
        -- Lädt das spezifische Skript aus dem games/ Ordner
        local gameScriptSuccess, gameScript = pcall(function()
            return loadstring(game:HttpGet(getgitpath() .. "games/" .. scriptFile))()
        end)

        if gameScriptSuccess and type(gameScript) == "function" then
            -- Übergibt den ScriptsTab an das Spiel-Skript
            gameScript(ScriptsTab, data)
        end
    end
end
