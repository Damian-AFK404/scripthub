-- === SCRIPT HUB V11.0 (BASE RE-ENGINEERED EDITION) ===
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local lplayer = Players.LocalPlayer

local Settings = {
    AutoBall = false,
    AutoMoney = false,
    AutoEquip = false,
    AutoRebirth = false
}

local ignoredBalls = {}
local isRunning = true
local uiVisible = true
local isCollectingMoney = false
local chatConnection = nil
local inputConnection = nil
local afkConnection = nil

local myBase = nil
local ballFarmStartTime = nil

-- === ANTI-AFK ENGINE (PREVENTIVE 10-MIN LOOP + EVENT) ===
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

task.spawn(function()
    while isRunning do
        task.wait(600)
        if isRunning then
            sendAntiAfkSignal()
        end
    end
end)

-- === AGGRESSIVE BASE & COLLECTOR DETECTION SYSTEM ===
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

-- === UI ROOT ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ScriptHubDelta"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = lplayer:WaitForChild("PlayerGui") end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 310, 0, 380)
MainFrame.Position = UDim2.new(0.5, -155, 0.4, -190)
MainFrame.BackgroundColor3 = Color3.fromRGB(11, 11, 16)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 2
MainStroke.Color = Color3.fromRGB(0, 240, 255)
MainStroke.Parent = MainFrame

local MobileToggleButton = Instance.new("TextButton")
MobileToggleButton.Size = UDim2.new(0, 50, 0, 50)
MobileToggleButton.Position = UDim2.new(1, -65, 0, 15)
MobileToggleButton.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
MobileToggleButton.Text = "HUB"
MobileToggleButton.TextColor3 = Color3.fromRGB(0, 240, 255)
MobileToggleButton.Font = Enum.Font.GothamBold
MobileToggleButton.TextSize = 12
MobileToggleButton.Parent = ScreenGui

local MobileCorner = Instance.new("UICorner")
MobileCorner.CornerRadius = UDim.new(1, 0)
MobileCorner.Parent = MobileToggleButton

local MobileStroke = Instance.new("UIStroke")
MobileStroke.Thickness = 1.5
MobileStroke.Color = Color3.fromRGB(255, 0, 130)
MobileStroke.Parent = MobileToggleButton

MobileToggleButton.MouseButton1Click:Connect(function()
    uiVisible = not uiVisible
    MainFrame.Visible = uiVisible
end)

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = Color3.fromRGB(16, 16, 26)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 14)
HeaderCorner.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "SCRIPT HUB (FAST MODE)"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -24, 1, -65)
Content.Position = UDim2.new(0, 12, 0, 60)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.Parent = Content

local function AddPremiumToggle(headline, description, stateKey, iconText)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 56)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    Frame.Parent = Content

    local FrameCorner = Instance.new("UICorner")
    FrameCorner.CornerRadius = UDim.new(0, 10)
    FrameCorner.Parent = Frame

    local Icon = Instance.new("TextLabel")
    Icon.Size = UDim2.new(0, 30, 0, 30)
    Icon.Position = UDim2.new(0, 10, 0.5, -15)
    Icon.BackgroundTransparency = 1
    Icon.Text = iconText
    Icon.TextSize = 16
    Icon.Parent = Frame

    local TextLabel = Instance.new("TextLabel")
    TextLabel.Size = UDim2.new(1, -110, 0, 20)
    TextLabel.Position = UDim2.new(0, 45, 0, 8)
    TextLabel.BackgroundTransparency = 1
    TextLabel.Text = headline
    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel.Font = Enum.Font.GothamBold
    TextLabel.TextSize = 12
    TextLabel.TextXAlignment = Enum.TextXAlignment.Left
    TextLabel.Parent = Frame

    local SubLabel = Instance.new("TextLabel")
    SubLabel.Size = UDim2.new(1, -110, 0, 16)
    SubLabel.Position = UDim2.new(0, 45, 0, 26)
    SubLabel.BackgroundTransparency = 1
    SubLabel.Text = description
    SubLabel.TextColor3 = Color3.fromRGB(140, 140, 160)
    SubLabel.Font = Enum.Font.Gotham
    SubLabel.TextSize = 9
    SubLabel.TextXAlignment = Enum.TextXAlignment.Left
    SubLabel.Parent = Frame

    local Switch = Instance.new("TextButton")
    Switch.Size = UDim2.new(0, 44, 0, 22)
    Switch.Position = UDim2.new(1, -54, 0.5, -11)
    Switch.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    Switch.Text = ""
    Switch.Parent = Frame

    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = Switch

    local Slider = Instance.new("Frame")
    Slider.Size = UDim2.new(0, 16, 0, 16)
    Slider.Position = UDim2.new(0, 3, 0.5, -8)
    Slider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Slider.Parent = Switch

    local SliderCorner = Instance.new("UICorner")
    SliderCorner.CornerRadius = UDim.new(1, 0)
    SliderCorner.Parent = Slider

    local function updateVisual()
        local active = Settings[stateKey]
        Switch.BackgroundColor3 = active and Color3.fromRGB(0, 240, 255) or Color3.fromRGB(30, 30, 45)
        Slider.Position = active and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    end

    Switch.MouseButton1Click:Connect(function()
        Settings[stateKey] = not Settings[stateKey]
        updateVisual()
        
        if stateKey == "AutoBall" then
            ignoredBalls = {}
            ballFarmStartTime = Settings.AutoBall and os.time() or nil
        end
    end)
end

AddPremiumToggle("Auto Collect Balls", "Fast Ball-Farm Engine", "AutoBall", "⚽")
AddPremiumToggle("Auto Collect Money", "Sicheres Geld-Sammelsystem", "AutoMoney", "💸")
AddPremiumToggle("Auto Equip Best", "Nutzt direkt das Equip Remote-Event", "AutoEquip", "⚡")
AddPremiumToggle("Auto Rebirth", "Nutzt direkt das Rebirth Remote-Event", "AutoRebirth", "🔄")

inputConnection = UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.RightShift then
        uiVisible = not uiVisible
        MainFrame.Visible = uiVisible
    end
end)

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

-- === BALL ENGINE ===
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

task.spawn(function()
    while isRunning do
        if Settings.AutoBall and not isCollectingMoney then
            if ballFarmStartTime and (os.time() - ballFarmStartTime) >= 600 then
                ignoredBalls = {}
                ballFarmStartTime = os.time()
            end

            local target, _ = searchBalls(workspace, 1)
            if target then
                ignoredBalls[target] = true
                safeTeleport(target.Position + Vector3.new(0, 3, 0))
                task.wait(0.5) -- Wieder auf 0.5 Sekunden Cooldown gesetzt für schnelles Farmen
            else
                ignoredBalls = {}
                task.wait(0.2)
            end
        else
            task.wait(0.5)
        end
    end
end)

-- === GLOBAL COLLECTOR SCANNER ===
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

task.spawn(function()
    while isRunning do
        if Settings.AutoMoney then
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
        end
        task.wait(6.0)
    end
end)

-- === EQUIP BEST ===
task.spawn(function()
    while isRunning do
        if Settings.AutoEquip then
            fireRemote("RequestReplaceBestDroppers")
        end
        task.wait(5)
    end
end)

-- === AUTO REBIRTH ===
task.spawn(function()
    while isRunning do
        if Settings.AutoRebirth then
            fireRemote("RequestRebirth")
        end
        task.wait(3)
    end
end)

-- === UNLOAD SYSTEM ===
local function unloadScript()
    isRunning = false
    if chatConnection then chatConnection:Disconnect() end
    if inputConnection then inputConnection:Disconnect() end
    if afkConnection then afkConnection:Disconnect() end
    pcall(function() ScreenGui:Destroy() end)
end

if game:GetService("TextChatService").ChatVersion == Enum.ChatVersion.TextChatService then
    chatConnection = game:GetService("TextChatService").MessageReceived:Connect(function(msg)
        if msg.TextSource and msg.TextSource.UserId == lplayer.UserId and string.lower(msg.Text) == "/unload" then unloadScript() end
    end)
else
    chatConnection = lplayer.Chatted:Connect(function(msg)
        if string.lower(msg) == "/unload" then unloadScript() end
    end)
end