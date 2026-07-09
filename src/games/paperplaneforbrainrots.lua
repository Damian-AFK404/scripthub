-- Modernisierte UI & Auto-Best-Brainrot Script
return function(section_not_used, data)
    -- Rayfield UI Library laden (Moderne und saubere Oberfläche)
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    
    local env = getgenv()
    local plr = game:GetService("Players").LocalPlayer
    local http = game:GetService("HttpService")
    local repStorage = game:GetService("ReplicatedStorage")

    env.Farming = false
    env.Strength = false

    -- Speicher-Konfiguration laden/erstellen
    local setdata = data[tostring(game.PlaceId)] or {}
    setdata.farming = setdata.farming or false
    setdata.strength = setdata.strength or false
    data[tostring(game.PlaceId)] = setdata
    writefile("BrainrotPolice/Config.json", http:JSONEncode(data))

    -- UI Fenster erstellen
    local Window = Rayfield:CreateWindow({
        Name = "Brainrot Police Hub 🚀",
        LoadingTitle = "Lade Brainrot Cheats...",
        LoadingSubtitle = "by AI Assistant",
        ConfigurationSaving = {
            Enabled = false
        }
    })

    -- Tab für die Funktionen erstellen
    local MainTab = Window:CreateTab("Main Features", 4483362458) -- Standard Icon ID

    ---
    -- FUNKTION: Farm Brainrots (Optimiert auf das BESTE Brainrot)
    ---
    MainTab:CreateToggle({
        Name = "Farm BEST Brainrots",
        CurrentValue = setdata.farming,
        Flag = "FarmBrainrotFlag",
        Callback = function(v)
            env.Farming = v
            if getgenv().setconfig then getgenv().setconfig("farming", v) end
            
            -- Konfiguration live speichern
            setdata.farming = v
            writefile("BrainrotPolice/Config.json", http:JSONEncode(data))

            if not v then return end

            -- Asynchroner Loop, damit die UI nicht einfriert
            task.spawn(function()
                while env.Farming do
                    -- Flug anfordern
                    repStorage.SharedModules.Network.RequestPendingFlight:FireServer()
                    task.wait(0.5)

                    local vsp = Vector3.new(-347.2116394043, 89.037544250488, 25.892095565796)
                    local GameCore = require(repStorage.GameCore)
                    local utilCore = require(repStorage.UtilityCore)

                    -- Flug starten
                    local results = repStorage.SharedModules.Network.RequestActiveFlight:InvokeServer({
                        plotIndex = 3,
                        intensity = 1,
                        player = plr,
                        flightUID = utilCore.StringUtility.GenerateUID(),
                        serverFloors = 10000000,
                        visualStartPos = vsp,
                        startTime = GameCore.GetSycnedTime(),
                        startPos = Vector3.new(-347.2116394043, 85.050003051758, 25.892095565796),
                        serverStrength = 10000000
                    })

                    if results and results.spawnedBrainrots and #results.spawnedBrainrots > 0 then
                        -- LOGIK: Finde das beste Brainrot (höchster Wert/Multiplikator)
                        local chosenBrainrot = results.spawnedBrainrots[1]
                        
                        for _, brainrot in ipairs(results.spawnedBrainrots) do
                            -- Falls das Spiel 'value', 'multiplier' oder 'reward' nutzt, hier vergleichen.
                            -- Wir nutzen standardmäßig 'value' oder gehen nach der ID (höhere IDs sind oft besser).
                            local currentWorth = brainrot.value or brainrot.multiplier or brainrot.worth or 0
                            local bestWorth = chosenBrainrot.value or chosenBrainrot.multiplier or chosenBrainrot.worth or 0
                            
                            if currentWorth > bestWorth then
                                chosenBrainrot = brainrot
                            end
                        end

                        -- Warten bis der Flug vorbei ist
                        task.wait(results.timeInAir + 0.2)

                        -- Das beste ausgewählte Brainrot einsammeln
                        repStorage.SharedModules.Network.ClaimFlight:InvokeServer(chosenBrainrot.uid)
                    else
                        task.wait(1) -- Fallback, falls der Server nicht antwortet
                    end
                end
            end)
        end,
    })

    ---
    -- FUNKTION: Farm Strength
    ---
    MainTab:CreateToggle({
        Name = "Auto Farm Strength",
        CurrentValue = setdata.strength,
        Flag = "FarmStrengthFlag",
        Callback = function(v)
            env.Strength = v
            if getgenv().setconfig then getgenv().setconfig("strength", v) end
            
            setdata.strength = v
            writefile("BrainrotPolice/Config.json", http:JSONEncode(data))

            if not v then return end

            task.spawn(function()
                while env.Strength do
                    local net = repStorage.SharedModules.Network
                    net.RequestStrength:InvokeServer()
                    net.RequestDoubleStrength:InvokeServer()
                    task.wait(0.1)
                end
            end)
        end,
    })
end
