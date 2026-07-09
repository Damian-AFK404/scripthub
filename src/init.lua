local http = game:GetService("HttpService")

-- 1. Correct GitHub paths for your repository hi
local GITHUB_USER = "Damian-AFK404"
local GITHUB_REPO = "scripthub"
local BASE_URL = "https://raw.githubusercontent.com/" .. GITHUB_USER .. "/" .. GITHUB_REPO .. "/main/"

getgenv().getgitpath = function(subfolder)
    if subfolder then
        return BASE_URL .. subfolder .. "/"
    end
    return BASE_URL
end

-- 2. Intelligent loading of ui.lua (Checks root and src folder)
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
local Window, ScriptsTab = ui:Init()

-- 3. Load configuration data
local data = {}
pcall(function()
    if isfile("BrainrotPolice/Config.json") then
        data = http:JSONDecode(readfile("BrainrotPolice/Config.json"))
    end
end)

-- 4. Auto-detect game and load the script from the games/ folder
local placeIdStr = tostring(game.PlaceId)
local listSuccess, gamesListText = pcall(function() 
    return game:HttpGet(BASE_URL .. "gameslist.json") 
end)

if listSuccess then
    local gamesList = http:JSONDecode(gamesListText)
    local scriptFile = gamesList[placeIdStr]

    if scriptFile then
        -- FIX: Added BASE_URL .. "games/" to correctly reach the games folder
        local gameScriptSuccess, gameScript = pcall(function()
            return loadstring(game:HttpGet(BASE_URL .. "games/" .. scriptFile))()
        end)

        if gameScriptSuccess and type(gameScript) == "function" then
            -- Pass the ScriptsTab to the game script so it can build the toggles
            gameScript(ScriptsTab, data)
        else
            warn("Script Hub: Failed to load game script '" .. tostring(scriptFile) .. "'. Check file name or path.")
        end
    end
end
