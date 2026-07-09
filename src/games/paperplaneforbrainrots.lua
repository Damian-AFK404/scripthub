return function(TargetTab, data)
    local env = getgenv()
    local plr = game:GetService("Players").LocalPlayer
    local http = game:GetService("HttpService")
    local repStorage = game:GetService("ReplicatedStorage")

    env.Farming = false
    env.Strength = false

    -- Config absichern
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

            if not v then return end

            task.spawn(function()
                while env.Farming do
                    repStorage.SharedModules.Network.RequestPendingFlight:FireServer()
                    task.wait(0.5)

                    local vsp = Vector3.new(-347.2116394043, 89.037544250488, 25.892095565796)
                    local GameCore = require(repStorage.GameCore)
                    local utilCore = require(repStorage.UtilityCore)

                    local results = repStorage.SharedModules.Network.RequestActiveFlight:InvokeServer({
                        plotIndex = 3,
                        intensity = 1,
                        player = plr,
                        flightUID = utilCore.StringUtility.GenerateUID(),
                        serverFloors = 10000000,
                        visualStartPos = vsp,
                        startTime = GameCore.GetSycnedTime(),
                        startPos = Vector3.new(-347.2116394043, 85.050003051758, 25.892095565796),
                        serverStrength = 10000000
                    })

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

    -- TOGGLE: Farm Strength
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
