local uiModule = {}

function uiModule:Init()
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    local plr = game:GetService("Players").LocalPlayer
    local teleportService = game:GetService("TeleportService")

    -- Hauptfenster erstellen
    local Window = Rayfield:CreateWindow({
        Name = "Script Hub v2 🌐",
        LoadingTitle = "Lade Script Hub...",
        LoadingSubtitle = "by Damian",
        ConfigurationSaving = { Enabled = false }
    })

    -- 1. TAB: GAMES (Teleport-Liste mit Auto-Reload)
    local GamesTab = Window:CreateTab("Games 🎮", 4483362458)
    GamesTab:CreateSection("Klicke zum Beitreten (Script lädt automatisch neu):")
    
    -- Funktion, die den Auto-Execute einrichtet und teleportiert
    local function TeleportAndAutoRun(placeId)
        -- Prüfen, ob der Executor die writefile-Funktion unterstützt
        if writefile then
            -- Der Code, der beim Autostart ausgeführt werden soll (deine init.lua)
            -- Nutzt deinen korrekten GitHub-Pfad
            local bootstrapperCode = [[
-- Automatisch generiert von Damians Script Hub
loadstring(game:HttpGet("https://raw.githubusercontent.com/Damian-AFK404/scripthub/main/src/init.lua"))()
]]
            
            -- Schreibt das Skript in den autoexec-Ordner deines Executors
            -- (Funktioniert bei den meisten gängigen Executoren direkt über diesen Pfad)
            pcall(function()
                writefile("autoexec/scripthub_auto.lua", bootstrapperCode)
            end)
        end
        
        -- Jetzt den Teleport durchführen
        teleportService:Teleport(placeId, plr)
    end

    -- Die Buttons nutzen jetzt alle die neue Teleport-Funktion
    GamesTab:CreateButton({
        Name = "Become a Brainrot 🧠",
        Callback = function() 
            TeleportAndAutoRun(99255447043899) 
        end,
    })
    
    GamesTab:CreateButton({
        Name = "Dropper RNG 💧",
        Callback = function() 
            TeleportAndAutoRun(110947318876182) 
        end,
    })
    
    GamesTab:CreateButton({
        Name = "Paper Plane Simulator ✈️",
        Callback = function() 
            TeleportAndAutoRun(110373292461174) 
        end,
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
