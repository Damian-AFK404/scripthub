local UI = {}

-- Standard-Konfiguration für das UI
UI.HubName = "Script Hub"
UI.Theme = "Dark"

-- Funktion für Benachrichtigungen (Notifications) im Spiel
function UI:CreateNotification(title, text, duration)
    duration = duration or 5
    
    local StarterGui = game:GetService("StarterGui")
    local success, err = pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = tostring(title),
            Text = tostring(text),
            Duration = duration
        })
    end)
    
    if not success then
        print("[" .. tostring(title) .. "]: " .. tostring(text))
    end
end

-- Funktion, um das Hauptmenü für den Spieler zu laden
function UI:LoadMainWindow()
    print("[Script Hub] Loading UI Main Window...")
    
    -- Hier kommt später dein UI-Library-Code rein 
    -- (z.B. Orion, Rayfield, Kavo oder deine eigene UI)
    
    self:CreateNotification(self.HubName, "Interface loaded successfully!", 4)
end

return UI