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

    TargetTab:CreateSection("Paper Plane Features")

    -- TOGGLE: Auto Farm BEST Brainrots (Mit F9-Console Debugging!)
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
                    repStorage.SharedModules.Network.RequestPendingFlight:FireServer()
                    task.wait(0.5)

                    local GameCore = require(repStorage.GameCore)
                    local utilCore = require(repStorage.UtilityCore)

                    -- STATS LIVE ABFRAGEN
                    local leaderstats = plr:FindFirstChild("leaderstats") or plr:FindFirstChild("Leaderstats")
                    local currentStrength = leaderstats and (leaderstats:FindFirstChild("Throw Power") or leaderstats:FindFirstChild("throw power"))
                    currentStrength = currentStrength and currentStrength.Value or 10000000
                    
                    local currentFloors = leaderstats and (leaderstats:FindFirstChild("Floors") or leaderstats:FindFirstChild("floors"))
                    currentFloors = currentFloors and currentFloors.Value or 10000000

                    -- ECHTE POSITION & PLOT ABFRAGEN (Verhindert Ablehnung wegen falschem Grundstück!)
                    local char = plr.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    local currentPos = root and root.Position or Vector3.new(-347.2116394043, 85.050003051758, 25.892095565796)
                    local vsp = currentPos + Vector3.new(0, 4, 0)

                    local currentPlotIndex = 3
                    local tycoons = game.Workspace:FindFirstChild("Tycoons") or game.Workspace:FindFirstChild("Plots")
                    if tycoons then
                        for _, tycoon in ipairs(tycoons:GetChildren()) do
                            local ownerVal = tycoon:FindFirstChild("Owner") or tycoon:FindFirstChild("Player")
                            if ownerVal and (ownerVal.Value == plr or ownerVal.Value == plr.Name) then
                                currentPlotIndex = tycoon:GetAttribute("PlotIndex") or tonumber(tycoon.Name) or 3
                                break
                            end
                        end
                    end

                    print("[DEBUG] Sende Wurf an Server... Plot:", currentPlotIndex, "| Power:", currentStrength)

                    -- EXAKT DIE ORIGINALE STRUKTUR
                    local results = repStorage.SharedModules.Network.RequestActiveFlight:InvokeServer({
                        plotIndex = currentPlotIndex,
                        intensity = 1,
                        player = plr,
                        flightUID = utilCore.StringUtility.GenerateUID(),
                        serverFloors = currentFloors,
                        visualStartPos = vsp,
                        startTime = GameCore.GetSycnedTime(),
                        startPos = currentPos,
                        serverStrength = currentStrength
                    })

                    -- DEBUG-AUSGABE: Was sagt der Server wirklich?!
                    if not results then
                        warn("[DEBUG FEHLER] Der Server hat NIL geantwortet! Wurf wurde vom Server abgelehnt (falsche Daten/Anti-Cheat).")
                        task.wait(1)
                    elseif not results.spawnedBrainrots then
                        warn("[DEBUG FEHLER] Server hat geantwortet, aber die Tabelle 'spawnedBrainrots' fehlt!")
                        task.wait(1)
                    elseif #results.spawnedBrainrots == 0 then
                        warn("[DEBUG FEHLER] Server hat 0 Brainrots generiert! (Wurf evtl. zu kurz oder verbuggt)")
                        task.wait(1)
                    else
                        print("[DEBUG ERFOLG] Server hat", #results.spawnedBrainrots, "Brainrots generiert! Flugzeit:", results.timeInAir)
                        
                        local chosenBrainrot = results.spawnedBrainrots[1]
                        for _, brainrot in ipairs(results.spawnedBrainrots) do
                            local currentWorth = brainrot.value or brainrot.multiplier or brainrot.worth or 0
                            local bestWorth = chosenBrainrot.value or chosenBrainrot.multiplier or chosenBrainrot.worth or 0
                            if currentWorth > bestWorth then chosenBrainrot = brainrot end
                        end
                        
                        task.wait(results.timeInAir + 0.2)
                        print("[DEBUG] Sende Claim für Brainrot UID:", chosenBrainrot.uid)
                        repStorage.SharedModules.Network.ClaimFlight:InvokeServer(chosenBrainrot.uid)
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
