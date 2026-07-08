-- Script Hub Configuration
local githubUser = "Damian-AFK404"
local githubRepo = "eee"
local branch = "main"

-- Generate Base URLs
local rawUrl = "https://raw.githubusercontent.com/" .. githubUser .. "/" .. githubRepo .. "/" .. branch .. "/src/"
local jsonUrl = rawUrl .. "gameslist.json"

local HttpService = game:GetService("HttpService")
local currentPlaceId = tostring(game.PlaceId)

print("[Script Hub] Initializing game detection...")

-- 1. Fetch gameslist.json from GitHub
local success, jsonRaw = pcall(function()
    return game:HttpGet(jsonUrl)
end)

if not success or not jsonRaw then
    return warn("[Script Hub Error] Failed to load gameslist.json. Please check your repository configuration.")
end

-- 2. Decode the JSON data into a Lua table
local gamesList
local decodeSuccess, decodeError = pcall(function()
    gamesList = HttpService:JSONDecode(jsonRaw)
end)

if not decodeSuccess then
    return warn("[Script Hub Error] Failed to read JSON structure: " .. tostring(decodeError))
end

-- 3. Check if the current game exists in your list
if gamesList[currentPlaceId] then
    local fileName = gamesList[currentPlaceId]
    local scriptUrl = rawUrl .. "games/" .. fileName
    
    print("[Script Hub] Game detected: " .. fileName .. "! Loading specific script...")
    
    -- 4. Load and run the specific game script from the 'games' folder
    local runSuccess, errorMessage = pcall(function()
        loadstring(game:HttpGet(scriptUrl))()
    end)
    
    if not runSuccess then
        warn("[Script Hub Error] Failed to execute the game script: " .. tostring(errorMessage))
    end
else
    warn("[Script Hub] This game is currently not supported. (Place ID: " .. currentPlaceId .. ")")
end