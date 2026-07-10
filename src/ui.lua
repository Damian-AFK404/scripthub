local uiModule = {}

function uiModule:Init()
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    local plr = game:GetService("Players").LocalPlayer
    local teleportService = game:GetService("TeleportService")
    local http = game:GetService("HttpService")

    -- GitHub Configuration 22
    local GITHUB_USER = "Damian-AFK404"
    local GITHUB_REPO = "scripthub"
    local BASE_URL = "https://raw.githubusercontent.com/" .. GITHUB_USER .. "/" .. GITHUB_REPO .. "/main/"

    -- Main Window configuration
    local Window = Rayfield:CreateWindow({
        Name = "Script Hub",
        LoadingTitle = "Loading Script Hub...",
        LoadingSubtitle = "by nyvexz",
        ConfigurationSaving = { Enabled = false }
    })

    -- 1. TAB: GAMES
    local GamesTab = Window:CreateTab("Games", 4483362458)
    GamesTab:CreateSection("Click to join (Script will auto-reload):")
    
    local function TeleportAndAutoRun(placeId)
        local numericId = tonumber(placeId)
        if not numericId then return end

        -- 1. Sichert, dass das Skript im nächsten Spiel geladen wird
        local bootstrapperCode = [[
            repeat task.wait() until game:IsLoaded()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Damian-AFK404/scripthub/main/src/init.lua"))()
        ]]

        if queue_on_teleport then
            pcall(function() queue_on_teleport(bootstrapperCode) end)
        elseif syn and syn.queue_on_teleport then
            pcall(function() syn.queue_on_teleport(bootstrapperCode) end)
        elseif fluxus and fluxus.queue_on_teleport then
            pcall(function() fluxus.queue_on_teleport(bootstrapperCode) end)
        end

        if writefile then
            pcall(function()
                writefile("autoexec/scripthub_auto.lua", bootstrapperCode)
                writefile("scripthub_auto.lua", bootstrapperCode)
            end)
        end
        
        task.wait(0.2)

        -- 2. SERVER HOPPER ENGINE: Sucht einen offenen Server über die Roblox API um Error 773 zu umgehen
        task.spawn(function()
            local HttpService = game:GetService("HttpService")
            local url = "https://games.roblox.com/v1/games/" .. tostring(numericId) .. "/servers/Public?sortOrder=Asc&limit=100"
            local success, result = pcall(function() return game:HttpGet(url) end)
            
            if success and result then
                local data = HttpService:JSONDecode(result)
                if data and data.data then
                    -- Gehe die Server-Liste durch und finde einen freien Server
                    for _, server in ipairs(data.data) do
                        if server.playing < server.maxPlayers and server.id ~= game.JobId then
                            pcall(function()
                                teleportService:TeleportToPlaceInstance(numericId, server.id, plr)
                            end)
                            return
                        end
                    end
                end
            end
            
            -- Backup: Falls kein Server gefunden wurde oder HTTP fehlschlägt
            pcall(function()
                teleportService:Teleport(numericId, plr)
            end)
        end)
    end

    -- Dynamisches Laden der Buttons aus der src/gameslist.json
    local listSuccess, gamesListText = pcall(function() 
        return game:HttpGet(BASE_URL .. "src/gameslist.json") 
    end)

    if listSuccess then
        local successDecode, gamesList = pcall(function()
            return http:JSONDecode(gamesListText)
        end)

        if successDecode and type(gamesList) == "table" then
            for placeIdStr, scriptFileName in pairs(gamesList) do
                local displayName = scriptFileName:gsub("%.lua$", ""):gsub("^%l", string.upper)
                
                GamesTab:CreateButton({
                    Name = displayName,
                    Callback = function() 
                        TeleportAndAutoRun(placeIdStr) 
                    end,
                })
            end
        else
            GamesTab:CreateLabel("Error: gameslist.json formatting is invalid.")
        end
    else
        GamesTab:CreateLabel("Error: Could not load games list from GitHub.")
    end

    -- 2. TAB: FUNCTIONS
    local FunctionsTab = Window:CreateTab("Functions", 4483362458)

    -- 3. TAB: CREDITS
    local CreditsTab = Window:CreateTab("Credits", 4483362458)
    
    CreditsTab:CreateSection("Hub Information")
    CreditsTab:CreateLabel("hubName: Script Hub")
    CreditsTab:CreateLabel("version: 1.0.0")
    
    CreditsTab:CreateSection("Team")
    CreditsTab:CreateLabel("owner: nyvexz")
    CreditsTab:CreateLabel("developers: [nyvexz, Vaehz(unoffical hehe)]")
    CreditsTab:CreateLabel("helpers: [nyvexz, Killuatrudi]")

    return Window, FunctionsTab
end

return uiModule
