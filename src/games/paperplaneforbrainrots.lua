-- hi
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
                    task.wait(0.2) -- Etwas mehr Zeit für den Server zum Registrieren

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

                    -- Zufällige Wurfstärke generieren (0.832 - 0.985)
                    local randomIntensity = 0.832555 + (math.random(0, 150000) / 1000000)

                    -- FIX: Wir generieren eine echte System-GUID und erzwingen Kleinbuchstaben
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
                            ["flightUID"] = secureFlightUID, -- Die echte GUID hier rein
                            ["startTime"] = GameCore.GetSycnedTime(),
                            ["startPos"] = currentPos,
                            ["serverPickupTime"] = 30
                        }
                    }

                    -- 3. Den Flug ausführen
                    local success, results = pcall(function()
                        return repStorage.SharedModules.Network.RequestActiveFlight:InvokeServer(unpack(args))
                    end)

                    -- Belohnung abholen
                    if success and results and results.spawnedBrainrots and #results.spawnedBrainrots > 0 then
                        local chosenBrainrot = results.spawnedBrainrots[1]
                        for _, brainrot in ipairs(results.spawnedBrainrots) do
                            local currentWorth = brainrot.value or brainrot.multiplier or brainrot.worth or 0
                            local bestWorth = chosenBrainrot.value or chosenBrainrot.multiplier or chosenBrainrot.worth or 0
                            if currentWorth > bestWorth then chosenBrainrot = brainrot end
                        end
                        
                        -- Wartezeit basierend auf dem Server-Rückgabewert
                        local dynamicWait = tonumber(results.timeInAir) or 1
                        if dynamicWait > 4 then dynamicWait = 4 end
                        task.wait(dynamicWait + 0.2) -- Puffer hinzugefügt, damit der Flieger sicher gelandet ist
                        
                        -- FIX: Wenn das Spiel die UID des gefangenen Objekts will, nutzen wir chosenBrainrot.uid.
                        -- Falls das fehlschlägt, senden wir als Backup unsere generierte secureFlightUID.
                        local claimUID = chosenBrainrot.uid or secureFlightUID
                        
                        pcall(function()
                            repStorage.SharedModules.Network.ClaimFlight:InvokeServer(claimUID)
                        end)
                        
                        task.wait(0.3) -- Cooldown für Stabilität
                    else
                        task.wait(1) -- Längere Pause, falls der Wurf komplett fehlgeschlagen ist
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
