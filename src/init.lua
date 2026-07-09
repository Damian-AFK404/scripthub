local http = game:GetService("HttpService")

-- 1. GitHub Configuration done
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

-- 4. Detect and execute the game module
local placeIdStr = tostring(game.PlaceId)
local listSuccess, gamesListText = pcall(function() 
    return game:HttpGet(BASE_URL .. "src/gameslist.json") -- Verweist auf den src/ Ordner
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
                -- FIX: Sichere Ausführung. Wir prüfen beide Varianten, wie das Skript die Parameter erwartet
                local successRun, runErr = pcall(function()
                    local scriptResult = runScript()
                    if type(scriptResult) == "function" then
                        scriptResult(FunctionsTab, data)
                    elseif type(runScript) == "function" then
                        runScript(FunctionsTab, data)
                    end
                end)
                if not successRun then
                    warn("Script Hub: Error running game script: " .. tostring(runErr))
                    FunctionsTab:CreateSection("Error running script: " .. tostring(runErr))
                end
            else
                warn("Script Hub: Syntax error in game script: " .. tostring(err))
                FunctionsTab:CreateSection("Syntax error in game script!")
            end
        else
            warn("Script Hub: Failed to fetch game script from " .. gameScriptUrl)
            FunctionsTab:CreateSection("Could not fetch game script from GitHub.")
        end
    else
        -- Nachricht, wenn das aktuelle Spiel nicht in deiner gameslist.json steht
        FunctionsTab:CreateSection("No script assigned for PlaceId: " .. placeIdStr)
    end
else
    FunctionsTab:CreateSection("Could not load gameslist.json")
end
