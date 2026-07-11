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

    -- Bereich im UI erstellen
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
                    -- 1. Das Signal senden, dass ein Wurf vorbereitet wird
                    repStorage.SharedModules.Network.RequestPendingFlight:FireServer()
                    task.wait(0.15)

                    local GameCore = require(repStorage.GameCore)
                    local utilCore = require(repStorage.UtilityCore)

                    -- ZWISCHENSCHRITT: Echte Stats sauber auslesen
                    local leaderstats = plr:FindFirstChild("leaderstats") or plr:FindFirstChild("Leaderstats")
                    
                    -- Holt exakt "Throw Power" (von deinem Screenshot)
                    local currentStrength = leaderstats and (leaderstats:FindFirstChild("Throw Power") or leaderstats:FindFirstChild("throw power"))
                    currentStrength = currentStrength and currentStrength.Value or 3224
                    
                    -- Holt exakt "Floors" (von deinem Screenshot)
                    local currentFloors = leaderstats and (leaderstats:FindFirstChild("Floors") or leaderstats:FindFirstChild("floors"))
                    currentFloors = currentFloors and currentFloors.Value or 121

                    -- Position und Plot-Index ermitteln
                    local myCharacter = plr.Character
                    local currentPos = myCharacter and myCharacter:GetAttribute("PivotLocation") or Vector3.new(-488, 1465, 22)
                    if myCharacter and myCharacter:FindFirstChild("HumanoidRootPart") then
                        currentPos = myCharacter.HumanoidRootPart.Position
                    end
                    local visualPos = currentPos + Vector3.new(0, 4, 0)

                    local currentPlotIndex = 7
                    local tycoons = game.Workspace:FindFirstChild("Tycoons") or game.Workspace:FindFirstChild("Plots")
                    if tycoons then
                        for _, tycoon in ipairs(tycoons:GetChildren()) do
                            local ownerVal = tycoon:FindFirstChild("Owner") or tycoon:FindFirstChild("Player")
                            if ownerVal and (ownerVal.Value == plr or ownerVal.Value == plr.Name) then
                                currentPlotIndex = tycoon:GetAttribute("PlotIndex") or tycoon:GetAttribute("Index") or tonumber(tycoon.Name) or 7
                                break
                            end
                        end
                    end

                    -- Deine Wurf-Intensität (8.325553) perfekt eingebaut
                    local randomIntensity = 0.832555 + (math.random(0, 10000) / 1000000)

                    -- 2. Das Argumenten-Paket packen (Alte Logik-Struktur)
                    local args = {
                        [1] = {
                            ["plotIndex"] = currentPlotIndex,
                            ["intensity"] = randomIntensity,
                            ["serverStrength"] = currentStrength, -- Jetzt mit Throw Power gefüttert!
                            ["player"] = plr,
                            ["visualStartPos"] = visualPos,
                            ["serverFloors"] = currentFloors,    -- Jetzt mit Floors gefüttert!
                            ["flightUID"] = utilCore.StringUtility.GenerateUID(),
                            ["startTime"] = GameCore.GetSycnedTime(),
                            ["startPos"] = currentPos,
                            ["serverPickupTime"] = 30
                        }
                    }

                    -- 3. Wurf ausführen und auf die Server-Antwort warten (Alte Logik)
                    local results = repStorage.SharedModules.Network.RequestActiveFlight:InvokeServer(unpack(args))

                    -- 4. ALTE LOGIK ZUM SAMMELN: Direkt aus den empfangenen Serverdaten lesen
                    if results and results.spawnedBrainrots and #results.spawnedBrainrots > 0 then
                        local chosenBrainrot = results.spawnedBrainrots[1]
                        for _, brainrot in ipairs(results.spawnedBrainrots) do
                            local currentWorth = brainrot.value or brainrot.multiplier or brainrot.worth or 0
                            local bestWorth = chosenBrainrot.value or chosenBrainrot.multiplier or chosenBrainrot.worth or 0
                            if currentWorth > bestWorth then chosenBrainrot = brainrot end
                        end
                        
                        -- Exakt die vom Server berechnete Flugzeit abwarten, damit die Landung synchron ist
                        local waitTime = tonumber(results.timeInAir) or 1
                        task.wait(waitTime + 0.1)
                        
                        -- Das gefundene Brainrot über seine echte Server-UID einlösen
                        repStorage.SharedModules.Network.ClaimFlight:InvokeServer(chosenBrainrot.uid)
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
