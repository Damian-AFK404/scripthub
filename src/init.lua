local http = game:GetService("HttpService")

-- 1. GitHub Configuration please speed i need this
local GITHUB_USER = "Damian-AFK404"
local GITHUB_REPO = "scripthub"
local BASE_URL = "https://raw.githubusercontent.com/" .. GITHUB_USER .. "/" .. GITHUB_REPO .. "/main/"

getgenv().getgitpath = function(subfolder)
    if subfolder then
        return BASE_URL .. subfolder .. "/"
    end
    return BASE_URL
end

-- 2. Smart load ui.lua
local uiScript = nil
local pathsToTry = {
    BASE_URL .. "ui.lua",
    BASE_URL .. "src/ui.lua"
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
    error("Script Hub Error: ui.lua could not be found on GitHub!")
end

local ui = loadstring(uiScript)()
local Window, FunctionsTab = ui:Init()

-- 3. Configuration Setup
local data = {}
pcall(function()
    if isfile("BrainrotPolice/Config.json") then
        data = http:JSONDecode(readfile("BrainrotPolice/Config.json"))
    end
end)

-- 4. Game Script direkt laden und sofort ausführen
local placeIdStr = tostring(game.PlaceId)

-- Erstelle zur Sicherheit direkt eine Sektion, damit der Tab NIEMALS leer ist
FunctionsTab:CreateSection("Game: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name)

local listSuccess, gamesListText = pcall(function() 
    return game:HttpGet(BASE_URL .. "src/gameslist.json")
end)

if listSuccess then
    local gamesList = http:JSONDecode(gamesListText)
    local scriptFile = gamesList[placeIdStr]

    if scriptFile then
        local gameScriptUrl = BASE_URL .. "games/" .. scriptFile
        local gameScriptSuccess, gameScriptContent = pcall(function()
            return game:HttpGet(gameScriptUrl)
        end)

        if gameScriptSuccess and gameScriptContent then
            -- Code säubern, falls unsichtbare Zeichen von GitHub drin sind
            gameScriptContent = gameScriptContent:gsub("\r", "")
            
            local runScript, err = loadstring(gameScriptContent)
            if runScript then
                -- Ausführen und Elemente in den Tab pushen
                local successRun, runErr = pcall(function()
                    local scriptResult = runScript()
                    if type(scriptResult) == "function" then
                        scriptResult(FunctionsTab, data)
                    else
                        runScript(FunctionsTab, data)
                    end
                end)
                
                if not successRun then
                    FunctionsTab:CreateLabel("Runtime Error: " .. tostring(runErr))
                end
            else
                FunctionsTab:CreateLabel("Syntax Error: " .. tostring(err))
            end
        else
            FunctionsTab:CreateLabel("Could not download: " .. scriptFile)
        end
    else
        FunctionsTab:CreateLabel("No script assigned for ID: " .. placeIdStr)
    end
else
    FunctionsTab:CreateLabel("Failed to load gameslist.json")
end
