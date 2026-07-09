local http = game:GetService("HttpService")

-- 1. GitHub Configuration
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
local Window, ScriptsTab = ui:Init()

-- 3. Configuration Setup
local data = {}
pcall(function()
    if isfile("BrainrotPolice/Config.json") then
        data = http:JSONDecode(readfile("BrainrotPolice/Config.json"))
    end
end)

-- 4. Detect and execute the game module
local placeIdStr = tostring(game.PlaceId)
local listSuccess, gamesListText = pcall(function() 
    return game:HttpGet(BASE_URL .. "gameslist.json") 
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
            local runScript, err = loadstring(gameScriptContent)
            if runScript then
                -- This executes your game file and passes the Rayfield Tab directly into it!
                local successRun, runErr = pcall(function()
                    runScript()(ScriptsTab, data)
                end)
                if not successRun then
                    warn("Script Hub: Error running game script: " .. tostring(runErr))
                end
            else
                warn("Script Hub: Syntax error in game script: " .. tostring(err))
            end
        else
            warn("Script Hub: Failed to fetch game script from " .. gameScriptUrl)
        end
    end
end
