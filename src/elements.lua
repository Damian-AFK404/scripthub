local Elements = {}

-- Schützt Funktionen vor Abstürzen und gibt eine saubere Fehlermeldung aus
function Elements:SafeExecute(funcName, func)
    local success, err = pcall(func)
    if not success then
        warn("[Script Hub Error] Failed to execute " .. tostring(funcName) .. ": " .. tostring(err))
    end
    return success
end

-- Hilfsfunktion, um schnell den eigenen Charakter und RootPart zu bekommen
function Elements:GetLocalCharacter()
    local player = game:GetService("Players").LocalPlayer
    if player and player.Character then
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        return player.Character, root, humanoid
    end
    return nil, nil, nil
end

-- Beispiel für eine globale Bewegungsfunktion (z. B. WalkSpeed ändern)
function Elements:SetWalkSpeed(speed)
    local _, _, humanoid = self:GetLocalCharacter()
    if humanoid then
        humanoid.WalkSpeed = speed
    end
end

-- Beispiel für eine globale Sprungfunktion (z. B. JumpPower ändern)
function Elements:SetJumpPower(power)
    local _, _, humanoid = self:GetLocalCharacter()
    if humanoid then
        humanoid.UseJumpPower = true
        humanoid.JumpPower = power
    end
end

return Elements