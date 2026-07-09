local uiModule = {}

function uiModule:Init()
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    local plr = game:GetService("Players").LocalPlayer

    -- Hauptfenster erstellen
    local Window = Rayfield:CreateWindow({
        Name = "Script Hub v2 🌐",
        LoadingTitle = "Lade Script Hub...",
        LoadingSubtitle = "by Damian",
        ConfigurationSaving = { Enabled = false }
    })

    -- 1. TAB: GAMES (Teleport-Liste)
    local GamesTab = Window:CreateTab("Games 🎮", 4483362458)
    GamesTab:CreateSection("Klicke zum Beitreten:")
    
    GamesTab:CreateButton({
        Name = "Become a Brainrot",
        Callback = function() game:GetService("TeleportService"):Teleport(99255447043899, plr) end,
    })
    GamesTab:CreateButton({
        Name = "Dropper RNG",
        Callback = function() game:GetService("TeleportService"):Teleport(110947318876182, plr) end,
    })
    GamesTab:CreateButton({
        Name = "Paper Plane Simulator",
        Callback = function() game:GetService("TeleportService"):Teleport(110373292461174, plr) end,
    })

    -- 2. TAB: SCRIPTS (Hier landen die Cheats für das jeweilige Spiel)
    local ScriptsTab = Window:CreateTab("Scripts ⚡", 4483362458)

    -- 3. TAB: CREDITS
    local CreditsTab = Window:CreateTab("Credits 👤", 4483362458)
    CreditsTab:CreateSection("Hub Eigentümer: Damian")
    CreditsTab:CreateLabel("Danke fürs Nutzen von Script Hub!")

    -- Gibt das Fenster und den Tab an die init.lua zurück
    return Window, ScriptsTab
end

return uiModule
