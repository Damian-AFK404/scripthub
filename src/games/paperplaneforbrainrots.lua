return function(TargetTab, data)
    local env = getgenv()
    local plr = game:GetService("Players").LocalPlayer
    local http = game:GetService("HttpService")
    local repStorage = game:GetService("ReplicatedStorage")

    env.Farming = false
    env.Strength = false

    if type(data) ~= "table" then data = {} end
    local placeIdStr = tostring(game.PlaceId)
    if not data[placeIdStr] then data[placeIdStr] = { farming = false, strength = false } end
    local setdata = data[placeIdStr]

    -- Explicitly create features section under the target tab
    TargetTab:CreateSection("Paper Plane Features")

    -- TOGGLE: Auto Farm BEST Brainrots
    TargetTab:CreateToggle({
        Name = "Auto Farm BEST Brainrots",
        CurrentValue = setdata.farming,
        Flag = "BrainrotFarmFlag",
        Callback = function(v)
            env.Farming = v
            setdata.farming = v
            pcall(function() writefile("BrainrotPolice/Config.json", http:JSONEncode(data)) end)

            if not v then return end

            task.spawn(function()
                while env.Farming do
                    -- 1. Pending-Signal an den Server senden
                    repStorage.SharedModules.Network.RequestPendingFlight:FireServer()
                    task.wait(0.15)

                    local GameCore = require(repStorage.GameCore)
                    local utilCore = require(repStorage.UtilityCore)

                    -- STATS-ZUGRIFF (Echte Werte live holen)
                    local leaderstats = plr:FindFirstChild("leaderstats") or plr:FindFirstChild("Leaderstats")
                    
                    local currentStrength = leaderstats and (leaderstats:FindFirstChild("Throw Power") or leaderstats:FindFirstChild("throw power") or leaderstats:FindFirstChild("Strength"))
                    currentStrength = currentStrength and currentStrength.Value or 50000
                    
                    local currentFloors = leaderstats and (leaderstats:FindFirstChild("Floors") or leaderstats:FindFirstChild("floors"))
                    currentFloors = currentFloors and currentFloors.Value or 500

                    -- FIX: Deine ECHTE Position live abfragen, damit sich der Landepunkt verändert
                    local myCharacter = plr.Character
                    local currentPos = Vector3.new(-488, 1465, 22) -- Nur noch als Notfall-Fallback
                    if myCharacter and myCharacter:FindFirstChild("HumanoidRootPart") then
                        currentPos = myCharacter.HumanoidRootPart.Position
                    end
                    local visualPos = currentPos + Vector3.new(0, 4, 0)

                    -- FIX: Deinen ECHTEN Plot-Index im Spiel suchen
                    local currentPlotIndex = 1 -- Standard-Startwert
                    local tycoons = game.Workspace:FindFirstChild("Tycoons") or game.Workspace:FindFirstChild("Plots") or game.Workspace:FindFirstChild("TycoonFolder")
                    if tycoons then
                        for _, tycoon in ipairs(tycoons:GetChildren()) do
                            -- Prüft, ob das Grundstück dir gehört
                            local ownerVal = tycoon:FindFirstChild("Owner") or tycoon:FindFirstChild("Player")
                            if ownerVal and (ownerVal.Value == plr or ownerVal.Value == plr.Name or tostring(ownerVal.Value) == tostring(plr.UserId)) then
                                currentPlotIndex = tycoon:GetAttribute("PlotIndex") or tycoon:GetAttribute("Index") or tonumber(tycoon.Name) or 1
                                break
                            end
                        end
                    end

                    -- Zufällige, sichere Wurfstärke generieren (0.832 - 0.985)
                    local randomIntensity = 0.832555 + (math.random(0, 150000) / 1000000)

                    -- 2. Das exakte Daten-Paket schnüren
                    local args = {
                        [1] = {
                            ["plotIndex"] = currentPlotIndex, -- Nutzt jetzt deinen echten Plot
                            ["intensity"] = randomIntensity,
                            ["serverStrength"] = currentStrength,
                            ["player"] = plr,
                            ["visualStartPos"] = visualPos,
                            ["serverFloors"] = currentFloors,
                            ["flightUID"] = utilCore.StringUtility.GenerateUID(),
                            ["startTime"] = GameCore.GetSycnedTime(),
                            ["startPos"] = currentPos, -- Nutzt deine echte Position
                            ["serverPickupTime"] = 30
                        }
                    }

                    -- 3. Den Flug ausführen
                    local success, results = pcall(function()
                        return repStorage.SharedModules.Network.RequestActiveFlight:InvokeServer(unpack(args))
                    end)

                    -- Dynamische Wartezeit basierend auf den Server-Rückgabedaten
                    if success and results and results.spawnedBrainrots and #results.spawnedBrainrots > 0 then
                        local chosenBrainrot = results.spawnedBrainrots[1]
                        for _, brainrot in ipairs(results.spawnedBrainrots) do
                            local currentWorth = brainrot.value or brainrot.multiplier or brainrot.worth or 0
                            local bestWorth = chosenBrainrot.value or chosenBrainrot.multiplier or chosenBrainrot.worth or 0
                            if currentWorth > bestWorth then chosenBrainrot = brainrot end
                        end
                        
                        local dynamicWait = tonumber(results.timeInAir) or 0.5
                        if dynamicWait > 4 then dynamicWait = 4 end
                        
                        task.wait(dynamicWait + 0.1)
                        
                        pcall(function()
                            repStorage.SharedModules.Network.ClaimFlight:InvokeServer(chosenBrainrot.uid)
                        end)
                        
                        task.wait(0.2)
                    else
                        task.wait(0.5)
                    end
                end
            end)
        end,
    })

    -- TOGGLE: Auto Farm Strength
    TargetTab:CreateToggle({
        Name = "Auto Farm Strength",
        CurrentValue = setdata.strength,
        Flag = "StrengthFarmFlag",
        Callback = function(v)
            env.Strength = v
            setdata.strength = v
            pcall(function() writefile("BrainrotPolice/Config.json", http:JSONEncode(data)) end)

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
