local Players          = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

-- SCRIPT HUB CONFIGURATION
local CONFIG = {
	SummonCooldown = 1, -- Cooldown auf 1 Sekunde gesetzt
	EndPos         = Vector3.new(46, 6, -1835),
}

local KEYBINDS = {
	Summon = Enum.KeyCode.N,
	End    = Enum.KeyCode.V,
}

-- SCRIPT HUB NOTIFICATION SYSTEM
local function ScriptHubNotify(title, text, kind)
	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = "[Script Hub] " .. title,
		Text = text,
		Duration = 2
	})
end

-- TELEPORT FUNCTION
local function teleportTo(pos, label)
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.CFrame = CFrame.new(pos)
		ScriptHubNotify("Teleport", "Erfolgreich zu: " .. label, "success")
	else
		ScriptHubNotify("Fehler", "Charakter nicht gefunden!", "error")
	end
end

-- SUMMON FUNCTION WITH 1-SECOND COOLDOWN
local summonCD = false
local function doSummon()
	if summonCD then return end -- Blockiert die Ausführung, wenn der 1s Cooldown aktiv ist
	
	summonCD = true
	local ok = pcall(function()
		local args = { [1] = Workspace.Locations:FindFirstChild("End"), n = 1 }
		ReplicatedStorage.Events.SummonBrainrots:FireServer(unpack(args, 1, args.n or #args))
	end)
	
	if not ok then
		ScriptHubNotify("Fehler", "Summon fehlgeschlagen.", "error")
	end
	
	task.wait(CONFIG.SummonCooldown)
	summonCD = false
end

-- INPUT LISTENER (HOTKEYS)
UserInputService.InputBegan:Connect(function(i, gpe)
	if gpe then return end
	
	if i.KeyCode == KEYBINDS.Summon then
		doSummon()
	elseif i.KeyCode == KEYBINDS.End then
		teleportTo(CONFIG.EndPos, "Ziel (Finish Line)")
	end
end)

ScriptHubNotify("Geladen", "Script Hub aktiv! [N] für Summon (1s CD), [V] für End-TP.", "success")