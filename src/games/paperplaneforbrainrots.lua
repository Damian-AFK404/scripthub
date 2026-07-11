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

    -- TOGGLE: Auto Farm BEST Brainrots (Jetzt mit Echtzeit-Werten)
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
                game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                    Text = "[SCRIPT] Echtzeit-Farm gestartet!",
                    Color = Color3.fromRGB(0, 255, 0)
                })

                while env.Farming do
                    -- 1. Pre-Flight anfordern
                    repStorage.SharedModules.Network.RequestPendingFlight:FireServer()
                    task.wait(0.3)

                    -- 2. ECHTE STATS DYNAMISCH AUSLESEN
                    local realStrength = 100 -- Sicherer Standard-Fallback
                    local realFloors = 0
                    
                    local stats = plr:FindFirstChild("leaderstats") or plr:FindFirstChild("Leaderstats")
                    if stats then
                        -- Wir suchen flexibel nach dem Power-Wert (egal ob Throw Power, Strength oder Power)
                        local strObj = stats:FindFirstChild("Throw Power") or stats:FindFirstChild("throw power") or stats:FindFirstChild("Strength") or stats:FindFirstChild("Power")
                        local floorObj = stats:FindFirstChild("Floors") or stats:FindFirstChild("floors")
                        
                        if strObj then realStrength = strObj.Value end
                        if floorObj then realFloors = floorObj.Value end
                    end

                    -- 3. ECHTE POSITION DES SPIELERS NUTZEN
                    local char = plr.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    local currentPos = root and root.Position or Vector3.new(-347.21, 85.05, 25.89)
                    local vsp = currentPos + Vector3.new(0, 4, 0) -- Flug startet leicht über dem Charakter

                    -- 4. GRUNDSTÜCK DYNAMISCH ERMITTELN
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

                    local GameCore = require(repStorage.GameCore)
                    local utilCore = require(repStorage.UtilityCore)

                    print("[FARM] Sende Wurf mit ECHTER Power: " .. tostring(realStrength) .. " von Position: " .. tostring(currentPos))

                    -- 5. DER ECHTE WURF
                    local success, results = pcall(function()
                        return repStorage.SharedModules.Network.RequestActiveFlight:InvokeServer({
                            plotIndex = currentPlotIndex,
                            intensity = 1,
                            player = plr,
                            flightUID = utilCore.StringUtility.GenerateUID(),
                            serverFloors = realFloors,
                            visualStartPos = vsp,
                            startTime = GameCore.GetSycnedTime(),
                            startPos = currentPos,
                            serverStrength = realStrength
                        })
                    end)

                    -- 6. AUSWERTUNG
                    if success and results and results.spawnedBrainrots then
                        if #results.spawnedBrainrots > 0 then
                            print("[ERFOLG] Server hat " .. tostring(#results.spawnedBrainrots) .. " Brainrots generiert! Warte auf Landung...")
                            
                            -- Bestes Brainrot heraussuchen
                            local chosenBrainrot = results.spawnedBrainrots[1]
                            for _, brainrot in ipairs(results.spawnedBrainrots) do
                                local currentWorth = brainrot.value or brainrot.multiplier or brainrot.worth or 0
                                local bestWorth = chosenBrainrot.value or chosenBrainrot.multiplier or chosenBrainrot.worth or 0
                                if currentWorth > bestWorth then chosenBrainrot = brainrot end
                            end
                            
                            -- Warten bis es landet, dann einsammeln
                            task.wait(results.timeInAir + 0.1)
                            repStorage.SharedModules.Network.ClaimFlight:InvokeServer(chosenBrainrot.uid)
                            print("[CLAIM] Brainrot erfolgreich eingesammelt!")
                        else
                            warn("[WARNUNG] Wurf erfolgreich, aber 0 Brainrots generiert. Wurfweite zu kurz?")
                        end
                    else
                        warn("[REJECTED] Server blockiert immer noch. Prüfe die Konsole auf die gesendeten Werte.")
                    end

                    task.wait(0.5) -- Kurze Pause vor dem nächsten Wurf
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
