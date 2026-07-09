return function(TargetTab, data)
    local Players           = game:GetService("Players")
    local Workspace         = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local http              = game:GetService("HttpService")

    local LocalPlayer = Players.LocalPlayer

    -- Configuration Setup
    local env = getgenv()
    env.AutoSummon = false

    if type(data) ~= "table" then data = {} end
    local placeIdStr = tostring(game.PlaceId)
    if not data[placeIdStr] then data[placeIdStr] = { autoSummon = false } end
    local setdata = data[placeIdStr]

    -- Configurations
    local CONFIG = {
        SummonCooldown = 1,
        EndPos         = Vector3.new(46, 6, -1835),
    }

    -- Notification Helper
    local function ScriptHubNotify(title, text)
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "[Script Hub] " .. title,
            Text = text,
            Duration = 2
        })
    end

    -- Teleport Function
    local function teleportTo(pos, label)
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(pos)
            ScriptHubNotify("Teleport", "Successfully teleported to: " .. label)
        else
            ScriptHubNotify("Error", "Character not found!")
        end
    end

    -- Summon Function Execution
    local function fireSummon()
        local ok = pcall(function()
            local endLocation = Workspace.Locations:FindFirstChild("End")
            if endLocation then
                local args = { [1] = endLocation, n = 1 }
                ReplicatedStorage.Events.SummonBrainrots:FireServer(unpack(args, 1, args.n or #args))
            end
        end)
        if not ok then
            ScriptHubNotify("Error", "Summon remote call failed.")
        end
    end

    -- Create UI Section
    TargetTab:CreateSection("Brainrot Features")

    -- TOGGLE: Auto Summon (Replaces the N hotkey loop)
    TargetTab:CreateToggle({
        Name = "Auto Summon Brainrots (1s CD)",
        CurrentValue = setdata.autoSummon,
        Flag = "AutoSummonBrainrotsFlag",
        Callback = function(v)
            env.AutoSummon = v
            setdata.autoSummon = v
            pcall(function() writefile("BrainrotPolice/Config.json", http:JSONEncode(data)) end)

            if not v then return end

            task.spawn(function()
                while env.AutoSummon do
                    fireSummon()
                    task.wait(CONFIG.SummonCooldown)
                end
            end)
        end,
    })

    -- BUTTON: Teleport to End (Replaces the V hotkey)
    TargetTab:CreateButton({
        Name = "Teleport to Finish Line",
        Callback = function()
            teleportTo(CONFIG.EndPos, "Finish Line")
        end,
    })

    ScriptHubNotify("Loaded", "Become a Brainrot functions loaded successfully!")
end
