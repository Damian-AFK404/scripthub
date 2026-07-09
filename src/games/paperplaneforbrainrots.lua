-- Passt perfekt in deinen Script Hub (nutzt deine elements.lua)
return function(section, data)
    local elements = loadstring(game:HttpGet(getgitpath("src").."elements.lua"))()
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
    -- TOGGLE: Farm Brainrots (Wählt automatisch das BESTE Brainrot)
    ---
    elements:Toggle("Farm BEST Brainrots", section, setdata.farming, function(v)
        env.Farming = v
        if getgenv().setconfig then getgenv().setconfig("farming", v) end
        
        -- Config live speichern
        setdata.farming = v
        writefile("BrainrotPolice/Config.json", http:JSONEncode(data))

        if not v then return end

        -- task.spawn verhindert, dass dein ganzer Script Hub laggt oder einfriert
        task.spawn(function()
            while env.Farming do
                repStorage.SharedModules.Network.RequestPendingFlight:FireServer()
                task.wait(0.5)

                local vsp = Vector3.new(-347.2116394043, 89.037544250488, 25.892095565796)
                local GameCore = require(repStorage.GameCore)
                local utilCore = require(repStorage.UtilityCore)

                -- Flug starten und Ergebnisse abfragen
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
                    -- Intelligenz-Logik: Standardmäßig das erste nehmen...
                    local chosenBrainrot = results.spawnedBrainrots[1]
                    
                    -- ...und dann die Liste nach dem wertvollsten durchsuchen!
                    for _, brainrot in ipairs(results.spawnedBrainrots) do
                        local currentWorth = brainrot.value or brainrot.multiplier or brainrot.worth or 0
                        local bestWorth = chosenBrainrot.value or chosenBrainrot.multiplier or chosenBrainrot.worth or 0
                        
                        if currentWorth > bestWorth then
                            chosenBrainrot = brainrot
                        end
                    end

                    -- Warten bis der Flug vorbei ist
                    task.wait(results.timeInAir + 0.2)

                    -- Genau das beste Brainrot einsammeln
                    repStorage.SharedModules.Network.ClaimFlight:InvokeServer(chosenBrainrot.uid)
                else
                    task.wait(1) -- Fallback bei Server-Verzögerung
                end
            end
        end)
    end)

    ---
    -- TOGGLE: Farm Strength
    ---
    elements:Toggle("Auto Farm Strength", section, setdata.strength, function(v)
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
    end)
end
