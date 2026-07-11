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

    -- TOGGLE: Auto Farm BEST Brainrots (Physische Simulation)
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
                    local char = plr.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if not root then task.wait(0.5) continue end

                    -- Speicher deine originale Position, um dich später zurückzuteleportieren
                    local originalPosition = root.CFrame

                    -- 1. ECHTEN WURF TRIGGERN
                    -- Wir rufen das originale Wurfevent des Spiels auf. Dadurch stimmt die Flugbahn, 
                    -- die Wurfstärke wird korrekt berechnet und der Server registriert den Flug als 100% echt.
                    pcall(function()
                        repStorage.SharedModules.Network.RequestPendingFlight:FireServer()
                        task.wait(0.1)
                        -- Wir feuern das originale Aktivierungsevent (Simuliert den Loslass-Klick bei maximaler Power)
                        repStorage.SharedModules.Network.RequestActiveFlight:InvokeServer({
                            ["intensity"] = 1.0, -- Erzwingt maximale Power in der Engine
                            ["player"] = plr
                        })
                    end)

                    -- Wartezeit, bis der Flieger landet und die Brainrots in der Welt erscheinen
                    task.wait(2.5)
                    if not env.Farming then break end

                    -- 2. BRAINROTS IN DER WELT FINDEN & EINSAMMELN
                    -- Wir suchen direkt im Workspace nach den gespawnten Objekten
                    local dropsFolder = game.Workspace:FindFirstChild("Drops") or game.Workspace:FindFirstChild("Brainrots") or game.Workspace
                    
                    for _, object in ipairs(dropsFolder:GetChildren()) do
                        -- Wir suchen nach Objekten, die ein ProximityPrompt besitzen
                        local prompt = object:FindFirstChildWhichIsA("ProximityPrompt", true)
                        
                        if prompt then
                            -- Punkt 3: Magnitude-Check umgehen -> Teleportation direkt zum Objekt
                            local targetPart = object:IsA("BasePart") and object or object:FindFirstChildWhichIsA("BasePart", true)
                            if targetPart then
                                root.CFrame = targetPart.CFrame + Vector3.new(0, 2, 0)
                                task.wait(0.15) -- Kurzer Stabilitätspuffer nach dem Teleport
                            end

                            -- Punkt 2 & 4: Sicherstellen, dass HoldDuration ignoriert wird und der Executor feuert
                            if fireproximityprompt then
                                -- Setzt die HoldDuration temporär auf 0, um jeglichen Zeitkonflikt zu killen
                                local oldHold = prompt.HoldDuration
                                prompt.HoldDuration = 0
                                
                                -- Executor feuert den Prompt
                                fireproximityprompt(prompt)
                                task.wait(0.1)
                                
                                prompt.HoldDuration = oldHold
                            else
                                -- Fallback für normale Interaktion, falls fireproximityprompt nicht existiert
                                prompt:InputHoldBegin()
                                task.wait(prompt.HoldDuration + 0.05)
                                prompt:InputHoldEnd()
                            end
                        end
                    end

                    -- Zurück zum eigenen Grundstück teleportieren
                    root.CFrame = originalPosition
                    task.wait(0.5) -- Entlastungspause gegen Engine-Overload
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
