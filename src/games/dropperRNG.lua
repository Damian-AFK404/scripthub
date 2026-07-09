return function(TargetTab, data)
    local Players           = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local VirtualUser       = game:GetService("VirtualUser")
    local http              = game:GetService("HttpService")

    local lplayer = Players.LocalPlayer

    -- Environment Setup for Rayfield Loops
    local env = getgenv()
    env.AutoBall = false
    env.AutoMoney = false
    env.AutoEquip = false
    env.AutoRebirth = false

    if type(data) ~= "table" then data = {} end
    local placeIdStr = tostring(game.PlaceId)
    if not data[placeIdStr] then 
        data[placeIdStr] = { autoBall = false, autoMoney = false, autoEquip = false, autoRebirth = false } 
    end
    local setdata = data[placeIdStr]

    local ignoredBalls = {}
    local isRunning = true
    local isCollectingMoney = false
    local afkConnection = nil
    local myBase = nil
    local ballFarmStartTime = nil

    -- === ANTI-AFK ENGINE ===
    local function sendAntiAfkSignal()
        pcall(function()
            VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(0.5)
            VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end)
    end

    afkConnection = lplayer.Idled:Connect(function()
        sendAntiAfkSignal()
    end)

    -- === BASE & COLLECTOR DETECTION SYSTEM ===
    local function findMyBase()
        local possibleFolders = {"Bases", "Tycoons", "Plots", "PlayerBases", "Workspace"}
        
        for _, folderName in ipairs(possibleFolders) do
            local folder = workspace:FindFirstChild(folderName) or workspace
            for _, base in ipairs(folder:GetChildren()) do
                local nameLower = string.lower(base.Name)
                
                local ownerVal = base:FindFirstChild("Owner") or base:FindFirstChild("Player") or base:FindFirstChild("OwnerName") or base:FindFirstChild("UserId")
                if ownerVal then
                    if ownerVal.Value == lplayer or ownerVal.Value == lplayer.Name or tostring(ownerVal.Value) == lplayer.Name or tostring(ownerVal.Value) == tostring(lplayer.UserId) then
                        return base
                    end
                end
                
                if nameLower:find(string.lower(lplayer.Name)) then
                    return base
                end
            end
        end

        local char = lplayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local closestBase = nil
            local shortestDist = math.huge
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj.Name == "Collector" or obj.Name == "MainCollector" then
                    local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
                    if part then
                        local dist = (hrp.Position - part.Position).Magnitude
                        if dist < shortestDist then
                            shortestDist = dist
                            closestBase = obj.Parent
                        end
                    end
                end
            end
            if closestBase then return closestBase end
        end
        return nil
    end

    myBase = findMyBase()

    -- === UNDETECTED TELEPORT SYSTEM ===
    local function safeTeleport(pos)
        local char = lplayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            pcall(function()
                hrp.Velocity = Vector3.new(0, 0, 0)
                hrp.RotVelocity = Vector3.new(0, 0, 0)
                if char:FindFirstChild("UpperTorso") then char.UpperTorso.Velocity = Vector3.new(0, 0, 0) end
                if char:FindFirstChild("LowerTorso") then char.LowerTorso.Velocity = Vector3.new(0, 0, 0) end
            end)
            hrp.CFrame = CFrame.new(pos)
        end
    end

    -- === REMOTE ENGINE UTILITY ===
    local function fireRemote(remoteName)
        local remoteFolder = ReplicatedStorage:FindFirstChild("DropperRNGRemotes") or game:FindFirstChild("DropperRNGRemotes", true)
        if remoteFolder then
            local remote = remoteFolder:FindFirstChild(remoteName)
            if remote then
                if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
                    pcall(function() remote:FireServer() end)
                    return true
                elseif remote:IsA("RemoteFunction") then
                    pcall(function() remote:InvokeServer() end)
                    return true
                end
            end
        end
        return false
    end

    -- === BALL DETECTOR ENGINE ===
    local function searchBalls(folder, currentDepth)
        if currentDepth > 4 then return nil, math.huge end
        local char = lplayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil, math.huge end

        local nearest, shortest = nil, math.huge
        local children = folder:GetChildren()

        for i = 1, #children do
            local v = children[i]
            if v:IsA("BasePart") and not ignoredBalls[v] then
                local name = string.lower(v.Name)
                if name:find("ball") or name:find("soccer") or name:find("foot") or name:find("sphere") or name:find("pickup") then
                    local dist = (hrp.Position - v.Position).Magnitude
                    if dist < shortest then shortest = dist; nearest = v end
                end
            elseif v:IsA("Folder") or v:IsA("Model") then
                local subNearest, subShortest = searchBalls(v, currentDepth + 1)
                if subNearest and subShortest < shortest then shortest = subShortest; nearest = subNearest end
            end
        end
        return nearest, shortest
    end

    local function getMoneyCollector()
        if not myBase then myBase = findMyBase() end
        if myBase then
            local runtime = myBase:FindFirstChild("Runtime")
            local builds = runtime and runtime:FindFirstChild("Builds")
            if builds then
                for _, build in ipairs(builds:GetChildren()) do
                    local collector = build:FindFirstChild("Collector")
                    if collector then
                        local mainCollector = collector:FindFirstChild("MainCollector")
                        if mainCollector and mainCollector:IsA("BasePart") then
                            return mainCollector
                        end
                    end
                end
            end
            local collectorDeep = myBase:FindFirstChild("MainCollector", true) or myBase:FindFirstChild("Collector", true)
            if collectorDeep and collectorDeep:IsA("BasePart") then
                return collectorDeep
            end
        end

        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name == "MainCollector" or obj.Name == "Collector" then
                if obj:IsA("BasePart") then
                    local char = lplayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp and (hrp.Position - obj.Position).Magnitude < 250 then
                        return obj
                    end
                end
            end
        end
        return nil
    end

    -- === CREATE RAYFIELD INTERFACE ===
    TargetTab:CreateSection("Dropper RNG Features")

    -- TOGGLE: Auto Collect Balls
    TargetTab:CreateToggle({
        Name = "Auto Collect Balls",
        CurrentValue = setdata.autoBall,
        Flag = "AutoBallFlag",
        Callback = function(v)
            env.AutoBall = v
            setdata.autoBall = v
            pcall(function() writefile("BrainrotPolice/Config.json", http:JSONEncode(data)) end)

            if not v then return end
            ballFarmStartTime = os.time()
            ignoredBalls = {}

            task.spawn(function()
                while env.AutoBall and isRunning do
                    if not isCollectingMoney then
                        if ballFarmStartTime and (os.time() - ballFarmStartTime) >= 600 then
                            ignoredBalls = {}
                            ballFarmStartTime = os.time()
                        end

                        local target, _ = searchBalls(workspace, 1)
                        if target then
                            ignoredBalls[target] = true
                            safeTeleport(target.Position + Vector3.new(0, 3, 0))
                            task.wait(0.5)
                        else
                            ignoredBalls = {}
                            task.wait(0.2)
                        end
                    else
                        task.wait(0.5)
                    end
                end
            end)
        end,
    })

    -- TOGGLE: Auto Collect Money
    TargetTab:CreateToggle({
        Name = "Auto Collect Money",
        CurrentValue = setdata.autoMoney,
        Flag = "AutoMoneyFlag",
        Callback = function(v)
            env.AutoMoney = v
            setdata.autoMoney = v
            pcall(function() writefile("BrainrotPolice/Config.json", http:JSONEncode(data)) end)

            if not v then return end

            task.spawn(function()
                while env.AutoMoney and isRunning do
                    fireRemote("RequestCollectCash")
                    fireRemote("CollectCash")
                    fireRemote("CollectMoney")
                    fireRemote("ClaimCash")

                    local collectorPart = getMoneyCollector()
                    if collectorPart then
                        isCollectingMoney = true
                        safeTeleport(collectorPart.Position + Vector3.new(0, 1.5, 0))
                        task.wait(0.6)
                        isCollectingMoney = false
                    end
                    task.wait(6.0)
                end
            end)
        end,
    })

    -- TOGGLE: Auto Equip Best
    TargetTab:CreateToggle({
        Name = "Auto Equip Best Droppers",
        CurrentValue = setdata.autoEquip,
        Flag = "AutoEquipFlag",
        Callback = function(v)
            env.AutoEquip = v
            setdata.autoEquip = v
            pcall(function() writefile("BrainrotPolice/Config.json", http:JSONEncode(data)) end)

            if not v then return end

            task.spawn(function()
                while env.AutoEquip and isRunning do
                    fireRemote("RequestReplaceBestDroppers")
                    task.wait(5)
                end
            end)
        end,
    })

    -- TOGGLE: Auto Rebirth
    TargetTab:CreateToggle({
        Name = "Auto Rebirth",
        CurrentValue = setdata.autoRebirth,
        Flag = "AutoRebirthFlag",
        Callback = function(v)
            env.AutoRebirth = v
            setdata.autoRebirth = v
            pcall(function() writefile("BrainrotPolice/Config.json", http:JSONEncode(data)) end)

            if not v then return end

            task.spawn(function()
                while env.AutoRebirth and isRunning do
                    fireRemote("RequestRebirth")
                    task.wait(3)
                end
            end)
        end,
    })

    -- Clean up connections if another game loads
    game:GetService("Players").LocalPlayer.CharacterRemoving:Connect(function()
        isRunning = false
        if afkConnection then afkConnection:Disconnect() end
    end)
end
