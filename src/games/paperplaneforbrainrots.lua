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
                    -- 1. Zuerst zwingend das Pending-Signal an den Server senden
                    repStorage.SharedModules.Network.RequestPendingFlight:FireServer()
                    task.wait(0.2) -- Kurze Pause, damit der Server das Signal registriert

                    -- Cores für Berechnungen holen
                    local GameCore = require(repStorage.GameCore)
                    local utilCore = require(repStorage.UtilityCore)

                    -- DYNAMISCHE WERTE: Holt deine echten Daten live aus dem Spiel, statt feste Zahlen zu nutzen
                    local myCharacter = plr.Character
                    local currentPos = myCharacter and myCharacter:GetAttribute("PivotLocation") or Vector3.new(-488, 1465, 22)
                    local visualPos = currentPos + Vector3.new(-5, 4, 0) -- Leicht versetzt für die Optik

                    -- Versuche die echten Leaderstats/Upgrades für Stärke und Stockwerke auszulesen
                    local leaderstats = plr:FindFirstChild("leaderstats")
                    local currentStrength = leaderstats and leaderstats:FindFirstChild("Strength") and leaderstats.Strength.Value or 3224
                    local currentFloors = leaderstats and leaderstats:FindFirstChild("Floors") and leaderstats.Floors.Value or 121

                    -- Findet deinen Plot-Index (Grundstücksnummer) dynamisch heraus
                    local currentPlotIndex = 7
                    local tycoons = game.Workspace:FindFirstChild("Tycoons") -- Falls das Spiel so aufgebaut ist
                    if tycoons then
                        for _, tycoon in ipairs(tycoons:GetChildren()) do
                            if tycoon:FindFirstChild("Owner") and tycoon.Owner.Value == plr then
                                currentPlotIndex = tycoon:GetAttribute("PlotIndex") or 7
                                break
                            end
                        end
                    end

                    -- ZUFALLS-LOGIK: Generiert Werte im Bereich deiner gewünschten ~0.82 bis knapp unter 1.0
                    local randomIntensity = 0.82 + (math.random(0, 160000) / 1000000)

                    -- 2. Das Argumenten-Paket exakt wie im SimpleSpy verschachteln
                    local args = {
                        [1] = {
                            ["plotIndex"] = currentPlotIndex,
                            ["intensity"] = randomIntensity,
                            ["serverStrength"] = currentStrength,
                            ["player"] = plr,
                            ["visualStartPos"] = visualPos,
                            ["serverFloors"] = currentFloors,
                            ["flightUID"] = utilCore.StringUtility.GenerateUID(),
                            ["startTime"] = GameCore.GetSycnedTime(),
                            ["startPos"] = currentPos,
                            ["serverPickupTime"] = 30
                        }
                    }

                    -- 3. Den präzisen Flug an den Server übermitteln
                    local results = repStorage.SharedModules.Network.RequestActiveFlight:InvokeServer(unpack(args))

                    if results and results.spawnedBrainrots and #results.spawnedBrainrots > 0 then
                        local chosenBrainrot = results.spawnedBrainrots[1]
                        for _, brainrot in ipairs(results.spawnedBrainrots) do
                            local currentWorth = brainrot.value or brainrot.multiplier or brainrot.worth or 0
                            local bestWorth = chosenBrainrot.value or chosenBrainrot.multiplier or chosenBrainrot.worth or 0
                            if currentWorth > bestWorth then chosenBrainrot = brainrot end
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
