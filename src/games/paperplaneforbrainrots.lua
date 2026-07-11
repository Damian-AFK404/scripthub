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

            -- Sofortiges Feedback im Chat, ob der Toggle überhaupt reagiert!
            game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                Text = "[SCRIPT] Auto Farm Status geändert auf: " .. tostring(v),
                Color = Color3.fromRGB(255, 255, 0)
            })

            if not v then return end

            task.spawn(function()
                print("[START] Die Farming-Schleife läuft jetzt!")
                
                while env.Farming do
                    print("[SCHRITT 1] Sende RequestPendingFlight...")
                    repStorage.SharedModules.Network.RequestPendingFlight:FireServer()
                    task.wait(0.5)

                    -- Fallback-Werte definieren
                    local currentStrength = 10000000
                    local currentFloors = 10000000

                    print("[SCHRITT 2] Lese Stats aus...")
                    local stats = plr:FindFirstChild("leaderstats") or plr:FindFirstChild("Leaderstats")
                    if stats then
                        local strObj = stats:FindFirstChild("Throw Power") or stats:FindFirstChild("throw power") or stats:FindFirstChild("Strength")
                        local floorObj = stats:FindFirstChild("Floors") or stats:FindFirstChild("floors")
                        if strObj then currentStrength = strObj.Value end
                        if floorObj then currentFloors = floorObj.Value end
                    end

                    local GameCore = require(repStorage.GameCore)
                    local utilCore = require(repStorage.UtilityCore)
                    local vsp = Vector3.new(-347.2116394043, 89.037544250488, 25.892095565796)

                    print("[SCHRITT 3] Sende Wurf-Invoke an den Server... Power: " .. tostring(currentStrength))
                    
                    local success, results = pcall(function()
                        return repStorage.SharedModules.Network.RequestActiveFlight:InvokeServer({
                            plotIndex = 3,
                            intensity = 1,
                            player = plr,
                            flightUID = utilCore.StringUtility.GenerateUID(),
                            serverFloors = currentFloors,
                            visualStartPos = vsp,
                            startTime = GameCore.GetSycnedTime(),
                            startPos = Vector3.new(-347.2116394043, 85.050003051758, 25.892095565796),
                            serverStrength = currentStrength
                        })
                    end)

                    if not success then
                        warn("[CRITICAL ERROR] Der Invoke selbst ist komplett abgestürzt! Grund:", results)
                        task.wait(1)
                    elseif not results then
                        warn("[SERVER REJECT] Der Server hat NIL geantwortet. Wurf blockiert.")
                        task.wait(1)
                    elseif not results.spawnedBrainrots or #results.spawnedBrainrots == 0 then
                        warn("[SERVER ZERO] Server hat geantwortet, aber 0 Brainrots generiert.")
                        task.wait(1)
                    else
                        print("[ERFOLG] " .. tostring(#results.spawnedBrainrots) .. " Brainrots gefunden! Warte auf Landung: " .. tostring(results.timeInAir) .. "s")
                        
                        local chosenBrainrot = results.spawnedBrainrots[1]
                        for _, brainrot in ipairs(results.spawnedBrainrots) do
                            local currentWorth = brainrot.value or brainrot.multiplier or brainrot.worth or 0
                            local bestWorth = chosenBrainrot.value or chosenBrainrot.multiplier or chosenBrainrot.worth or 0
                            if currentWorth > bestWorth then chosenBrainrot = brainrot end
                        end
                        
                        task.wait(results.timeInAir + 0.2)
                        print("[CLAIM] Sende Claim für UID: " .. tostring(chosenBrainrot.uid))
                        repStorage.SharedModules.Network.ClaimFlight:InvokeServer(chosenBrainrot.uid)
                    end
                    
                    task.wait(0.5) -- Kleiner Puffer zwischen den Durchgängen
                end
                print("[STOP] Die Farming-Schleife wurde beendet.")
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
