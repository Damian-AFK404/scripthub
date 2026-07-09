local uiModule = {}

function uiModule:Init()
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    local plr = game:GetService("Players").LocalPlayer
    local teleportService = game:GetService("TeleportService")

    -- Hauptfenster erstellen (Ohne v2, ohne Emojis)
    local Window = Rayfield:CreateWindow({
        Name = "Script Hub",
        LoadingTitle = "Loading Script Hub...",
        LoadingSubtitle = "by Nyvexz",
        ConfigurationSaving = { Enabled = false }
    })

    -- 1. TAB: GAMES (Ohne Emojis)
    local GamesTab = Window:CreateTab("Games", 4483362458)
    GamesTab:CreateSection("Klicke zum Beitreten (Script laedt automatisch neu):")
    
    local function TeleportAndAutoRun(placeId)
        if writefile then
            local bootstrapperCode = [[
-- Automatisch generiert von Script Hub
repeat task.wait() until game:IsLoaded()
loadstring(game:HttpGet("https://raw.githubusercontent.com/Damian-AFK404/scripthub/main/src/init.lua"))()
]]
            pcall(function()
                writefile("autoexec/scripthub_auto.lua", bootstrapperCode)
                writefile("scripthub_auto.lua", bootstrapperCode)
            end)
        end
        
        task.wait(0.5)

        pcall(function()
            teleportService:Teleport(placeId, plr)
        end)

        task.wait(1)
        pcall(function()
            game:GetService("GuidService")
            teleportService:TeleportToPlaceInstance(placeId, game.JobId, plr)
        end)
    end

    GamesTab:CreateButton({
        Name = "Become a Brainrot",
        Callback = function() 
            TeleportAndAutoRun(99255447043899) 
        end,
    })
    
    GamesTab:CreateButton({
        Name = "Dropper RNG",
        Callback = function() 
            TeleportAndAutoRun(110947318876182) 
        end,
    })
    
    GamesTab:CreateButton({
        Name = "Paper Plane Simulator",
        Callback = function() 
            TeleportAndAutoRun(110373292461174) 
        end,
    })

    -- 2. TAB: SCRIPTS (Ohne Emojis)
    local ScriptsTab = Window:CreateTab("Scripts", 4483362458)

    -- 3. TAB: CREDITS (Struktur basierend auf dem Foto)
    local CreditsTab = Window:CreateTab("Credits", 4483362458)
    
    CreditsTab:CreateSection("Hub Information")
    CreditsTab:CreateLabel("Hub Name: Script Hub")
    CreditsTab:CreateLabel("Version: 1.0.0")
    
    CreditsTab:CreateSection("Team")
    CreditsTab:CreateLabel("Owner: nyvexz")
    CreditsTab:CreateLabel("Developers: nyvexz, Killuatrudi")
    CreditsTab:CreateLabel("Helpers: nyvexz, Killuatrudi")

    -- Gibt das Fenster und den Tab an die init.lua zurück
    return Window, ScriptsTab
end

return uiModule
