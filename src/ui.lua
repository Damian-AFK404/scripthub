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
    
    -- Funktion, die den Auto-Execute einrichtet und den Teleport erzwingt
    local function TeleportAndAutoRun(placeId)
        -- 1. Auto-Run-Datei schreiben (damit das Script im nächsten Game lädt)
        if writefile then
            local bootstrapperCode = [[
-- Automatisch generiert von Damians Script Hub
repeat task.wait() until game:IsLoaded()
loadstring(game:HttpGet("https://raw.githubusercontent.com/Damian-AFK404/scripthub/main/src/init.lua"))()
]]
            pcall(function()
                -- Beide Pfade absichern, da manche Executoren unterschiedliche Ordnerstrukturen nutzen
                writefile("autoexec/scripthub_auto.lua", bootstrapperCode)
                writefile("scripthub_auto.lua", bootstrapperCode) -- Fallback
            end)
        end
        
        -- Kurze Pause, damit die Datei sicher auf die Festplatte geschrieben wurde
        task.wait(0.5)

        -- 2. Teleport ERZWINGEN
        pcall(function()
            -- Haupt-Teleport-Versuch
            teleportService:Teleport(placeId, plr)
        end)

        -- Fallback: Falls der normale Teleport blockiert wird, alternative Methode zünden
        task.wait(1)
        pcall(function()
            game:GetService("GuidService") -- Löst oft interne CoreGui-Blockaden
            teleportService:TeleportToPlaceInstance(placeId, game.JobId, plr)
        end)
    end

    -- Die Buttons nutzen jetzt alle die überarbeitete Teleport-Funktion
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
