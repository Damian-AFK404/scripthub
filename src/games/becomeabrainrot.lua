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
                    -- 1. SIGNAL VORBEREITEN: Dem Server sagen, dass wir gleich werfen
                    repStorage.SharedModules.Network.RequestPendingFlight:FireServer()
                    task.wait(0.3) -- Erhöht auf 0.3s, um Engine-Overload vor dem Wurf zu verhindern

                    if not env.Farming then break end

                    local GameCore = require(repStorage.GameCore)

                    -- STATS-ZUGRIFF
                    local leaderstats = plr:FindFirstChild("leaderstats") or plr:FindFirstChild("Leaderstats")
                    local currentStrength = leaderstats and (leaderstats:FindFirstChild("Throw Power") or leaderstats:FindFirstChild("throw power") or leaderstats:FindFirstChild("Strength"))
                    currentStrength = currentStrength and currentStrength.Value or 50000
                    
                    local currentFloors = leaderstats and (leaderstats:FindFirstChild("Floors") or leaderstats:FindFirstChild("floors"))
                    currentFloors = currentFloors and currentFloors.Value or 500

                    -- Charakter-Position bestimmen
                    local myCharacter = plr.Character
                    local currentPos = Vector3.new(-488, 1465, 22)
                    if myCharacter and myCharacter:FindFirstChild("HumanoidRootPart") then
                        currentPos = myCharacter.HumanoidRootPart.Position
                    end
                    local visualPos = currentPos + Vector3.new(0, 4, 0)

                    -- Plot-Index ermitteln
                    local currentPlotIndex = 1
                    local tycoons = game.Workspace:FindFirstChild("Tycoons") or game.Workspace:FindFirstChild("Plots")
                    if tycoons then
                        for _, tycoon in ipairs(tycoons:GetChildren()) do
                            local ownerVal = tycoon:FindFirstChild("Owner")
                            if ownerVal and (ownerVal.Value == plr or ownerVal.Value == plr.Name) then
                                currentPlotIndex = tycoon:GetAttribute("PlotIndex") or tonumber(tycoon.Name) or 1
                                break
                            end
                        end
                    end

                    -- Zufällige, extrem präzise Wurfstärke generieren (0.832 - 0.985)
                    local randomIntensity = 0.832555 + (math.random(0, 150000) / 1000000)
                    local secureFlightUID = http:GenerateGUID(false):lower()

                    -- 2. Das exakte Daten-Paket schnüren
                    local args = {
                        [1] = {
                            ["plotIndex"] = currentPlotIndex,
                            ["intensity"] = randomIntensity,
                            ["serverStrength"] = currentStrength,
                            ["player"] = plr,
                            ["visualStartPos"] = visualPos,
                            ["serverFloors"] = currentFloors,
                            ["flightUID"] = secureFlightUID,
                            ["startTime"] = GameCore.GetSycnedTime(),
                            ["startPos"] = currentPos,
                            ["serverPickupTime"] = 30
                        }
                    }

                    -- 3. WURF BEGRETEN
                    local success, results = pcall(function()
                        return repStorage.SharedModules.Network.RequestActiveFlight:InvokeServer(unpack(args))
                    end)

                    -- SCHUTZ GEGEN ZU SCHNELLES FEUERN (Punkt 1):
                    -- Wir geben dem weiten 7k-Flug jetzt statt 1.8 Sekunden volle 3.0 Sekunden Zeit!
                    task.wait(3.0)

                    if not env.Farming then break end

                    -- UID ermitteln
                    local targetUID = secureFlightUID
                    if success and results and results.spawnedBrainrots and #results.spawnedBrainrots > 0 then
                        local chosenBrainrot = results.spawnedBrainrots[1]
                        for _, brainrot in ipairs(results.spawnedBrainrots) do
                            local currentWorth = brainrot.value or brainrot.multiplier or brainrot.worth or 0
                            local bestWorth = chosenBrainrot.value or chosenBrainrot.multiplier or chosenBrainrot.worth or 0
                            if currentWorth > bestWorth then chosenBrainrot = brainrot end
                        end
                        targetUID = chosenBrainrot.uid or secureFlightUID
                    end

                    -- 4. GEGENSTAND EINRADELN
                    pcall(function()
                        repStorage.SharedModules.Network.ClaimFlight:InvokeServer(targetUID)
                    end)

                    -- Entlastungspause für das Spiel, um nicht in ein Rate-Limit zu laufen
                    task.wait(0.5)
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
