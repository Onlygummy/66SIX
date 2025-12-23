-- D:/Script/tabs/character_tab.lua
-- This file contains all code related to the "Character" tab.

return function(Tab, Window, WindUI, TeleportService)

    local PlayerSection = Tab:Section({
        Title = "การตั้งค่าผู้เล่น",
        Icon = "user",
        Opened = true
    })

    PlayerSection:Slider({
        Title = "ปรับความเร็วผู้เล่น",

        Value = {
            Default = 16,
            Min = 10,
            Max = 100
        },
        Step = 1,
        Callback = function(value)
            local LocalPlayer = game:GetService("Players").LocalPlayer
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = value
            end
        end
    })

end
