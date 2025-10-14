-- D:/Script/tabs/self_tab.lua
-- ไฟล์นี้จะเก็บโค้ดทั้งหมดที่เกี่ยวกับแท็บ "ส่วนตัว"

return function(Tab, Window, WindUI)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local godModeConnection = nil
    local originalMaxHealth = 100
    local godModeToggle = nil

    local function applyGodMode(character)
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        if godModeConnection then godModeConnection:Disconnect() end

        originalMaxHealth = humanoid.MaxHealth
        humanoid.MaxHealth = math.huge
        humanoid.Health = math.huge

        godModeConnection = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            if humanoid.Health < humanoid.MaxHealth then
                humanoid.Health = math.huge
            end
        end)
    end

    local function disableGodMode()
        if godModeConnection then
            godModeConnection:Disconnect()
            godModeConnection = nil
        end

        local char = LocalPlayer.Character
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end

        -- Check if MaxHealth was changed before restoring
        if humanoid.MaxHealth == math.huge then
            humanoid.MaxHealth = originalMaxHealth
            humanoid.Health = originalMaxHealth
        end
    end

    godModeToggle = Tab:Toggle({
        Title = "God Mode (อมตะ)",
        Desc = "ป้องกันตัวละครของคุณจากการรับความเสียหายทั้งหมด",
        Value = false, -- ปิดเป็นค่าเริ่มต้น
        Callback = function(value)
            if value then
                if LocalPlayer.Character then
                    applyGodMode(LocalPlayer.Character)
                end
                WindUI:Notify({ Title = "สถานะ", Content = "เปิดใช้งาน God Mode", Icon = "shield" })
            else
                disableGodMode()
                WindUI:Notify({ Title = "สถานะ", Content = "ปิดใช้งาน God Mode", Icon = "shield-off" })
            end
        end
    })

    -- Re-apply God Mode if character respawns and the toggle is on
    LocalPlayer.CharacterAdded:Connect(function(character)
        task.wait(1) -- Wait for humanoid to be ready
        if godModeToggle and godModeToggle.Value then
            applyGodMode(character)
        end
    end)

end
