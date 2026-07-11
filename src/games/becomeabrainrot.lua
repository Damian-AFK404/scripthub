-- hi
return function(TargetTab, data)
    local env = getgenv()
    local plr = game:GetService("Players").LocalPlayer
    local http = game:GetService("HttpService")
    local repStorage = game:GetService("ReplicatedStorage")
    local vim = game:GetService("VirtualInputManager") -- Simuliert echte Klicks

    env.Farming = false
    env.Strength = false

    if type(data) ~= "table" then data = {} end
    local placeIdStr = tostring(game.PlaceId)
    if not data[placeIdStr] then data[placeIdStr] = { farming = false, strength = false } end
    local setdata = data[placeIdStr]

    TargetTab:CreateSection("Paper Plane Features")

    -- TOGGLE: Auto Farm BEST Brainrots (Echte Klick-Simulation)
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

                    -- 1. KLICK: Startet das Minigame
                    -- Simuliert einen Linksklick in der Mitte des Bildschirms
                    vim:SendMouseButtonEvent(500, 500, 0, true, game, 1)
                    task.wait(0.05)
                    vim:SendMouseButtonEvent(500, 500, 0, false, game, 1)

                    -- TIMING-PUFFER: Wie lange braucht die Nadel bis zum perfekten Bereich?
                    -- Falls er zu früh/spät wirft, kannst du die 0.4 hier leicht anpassen (z.B. 0.35 oder 0.5)
                    task.wait(0.4) 

                    if not env.Farming then break end

                    -- 2. KLICK: Bestätigt den Wurf im perfekten Bereich
                    vim:SendMouseButtonEvent(500, 500, 0, true, game, 1)
                    task.wait(0.05)
                    vim:SendMouseButtonEvent(500, 500, 0, false, game, 1)

                    -- WARTEZEIT FÜR DEN FLUG & AUTOMATISCHES SAMMELN
                    -- Da das Spiel den Wurf jetzt als komplett echt ansieht, sollte es dich 
                    -- automatisch belohnen, sobald der Flieger landet. Wir warten einfach,
                    -- bis der Flug vorbei ist.
                    task.wait(4.5) 
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
