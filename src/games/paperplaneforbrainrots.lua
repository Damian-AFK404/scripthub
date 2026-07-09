-- Diese Funktion wird von deinem Haupt-Script-Hub aufgerufen
return function(HubWindow, data)
    -- Falls kein HubWindow übergeben wurde, erstellen wir zur Sicherheit ein eigenes
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    local Window = HubWindow or Rayfield:CreateWindow({
        Name = "Brainrot Police Sub-Menu 🚀",
        LoadingTitle = "Lade Spiel-Modul...",
        LoadingSubtitle = "by AI Assistant",
        ConfigurationSaving = { Enabled = false }
    })

    -- Erstellt einen eigenen Tab im Haupt-Fenster deines Hubs
    local MainTab = Window:CreateTab("Paper Plane (Brainrot)", 4483362458)

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

    ---
    -- FUNKTION: Farm Brainrots (Das beste Element)
    ---
    MainTab:CreateToggle({
        Name = "Farm BEST Brainrots",
        CurrentValue = setdata.farming,
        Flag = "FarmBrainrotFlag",
        Callback = function(v)
            env.Farming = v
            if getgenv().setconfig then getgenv().setconfig("farming", v) end
            
            setdata.farming = v
            writefile("BrainrotPolice/Config.json", http:JSONEncode(data))

            if not v then return end

            task.spawn(function()
                while env.Farming do
                    repStorage.SharedModules.Network.RequestPendingFlight:FireServer()
                    task.wait(0.5)

                    local vsp = Vector3.new(-347.2116394043, 89.037544250488, 25.892095565796)
                    local GameCore = require(repStorage.GameCore)
                    local utilCore = require(repStorage.UtilityCore)

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
                        local chosenBrainrot = results.spawnedBrainrots[1]
                        
                        -- Sucht das wertvollste Brainrot aus der Liste
                        for _, brainrot in ipairs(results.spawnedBrainrots) do
                            local currentWorth = brainrot.value or brainrot.multiplier or brainrot.worth or 0
                            local bestWorth = chosenBrainrot.value or chosenBrainrot.multiplier or chosenBrainrot.worth or 0
                            
                            if currentWorth > bestWorth then
                                chosenBrainrot = brainrot
                            end
                        end

                        task.wait(results.timeInAir + 0.2)
                        repStorage.SharedModules.Network.ClaimFlight:InvokeServer(chosenBrainrot.uid)
                    else
                        task.wait(1)
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
