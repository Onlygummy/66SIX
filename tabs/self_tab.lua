-- D:/Script/tabs/self_tab.lua
-- ไฟล์นี้จะเก็บโค้ดทั้งหมดที่เกี่ยวกับแท็บ "ส่วนตัว"

return function(Tab, Window, WindUI)
    -- Services
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")

    -- ================================= --
    --        God Mode Logic
    -- ================================= --
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
            humanoid.Health = math.huge
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

        if humanoid.MaxHealth == math.huge then
            humanoid.MaxHealth = originalMaxHealth
            humanoid.Health = originalMaxHealth
        end
    end

    -- ================================= --
    --      Fly + Noclip Logic
    -- ================================= --
    local flySpeed = 100
    local flying = false
    local noclip = false
    local bodyVelocity, bodyGyro

    local function setupFlyMovers()
        if not bodyVelocity then
            bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
        if not bodyGyro then
            bodyGyro = Instance.new("BodyGyro")
            bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        end
    end

    local function updateMovement()
        if not flying or not LocalPlayer.Character then return end
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local camera = workspace.CurrentCamera
        if not rootPart or not camera then return end

        local moveDir = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
        
        bodyVelocity.Velocity = moveDir.Unit * flySpeed
        bodyGyro.CFrame = camera.CFrame
    end

    local function updateNoclip()
        if noclip and LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end

    -- Connect persistent listeners
    RunService.RenderStepped:Connect(updateMovement)
    RunService.Stepped:Connect(updateNoclip)

    -- ================================= --
    --      WindUI Element Creation
    -- ================================= --

    -- God Mode Section
    local GodModeSection = Tab:Section({ Title = "โหมดอมตะ", Icon = "shield", Opened = true })
    godModeToggle = GodModeSection:Toggle({
        Title = "God Mode",
        Desc = "ป้องกันตัวละครของคุณจากการรับความเสียหาย",
        Value = false,
        Callback = function(value)
            if value then
                if LocalPlayer.Character then applyGodMode(LocalPlayer.Character) end
                WindUI:Notify({ Title = "สถานะ", Content = "เปิดใช้งาน God Mode", Icon = "shield" })
            else
                disableGodMode()
                WindUI:Notify({ Title = "สถานะ", Content = "ปิดใช้งาน God Mode", Icon = "shield-off" })
            end
        end
    })

    -- Fly/Noclip Section
    local FlySection = Tab:Section({ Title = "โหมดบิน", Icon = "feather", Opened = true })
    FlySection:Toggle({
        Title = "Fly + Noclip",
        Desc = "เปิด/ปิดการบินและเดินทะลุ",
        Value = false,
        Callback = function(value)
            flying = value
            noclip = value
            local char = LocalPlayer.Character
            if not char then return end
            local rootPart = char:FindFirstChild("HumanoidRootPart")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if not rootPart or not humanoid then return end

            if flying then
                setupFlyMovers()
                bodyVelocity.Parent = rootPart
                bodyGyro.Parent = rootPart
                humanoid.PlatformStand = true
                WindUI:Notify({ Title = "สถานะ", Content = "เปิดใช้งาน Fly + Noclip", Icon = "feather" })
            else
                if bodyVelocity then bodyVelocity.Parent = nil end
                if bodyGyro then bodyGyro.Parent = nil end
                humanoid.PlatformStand = false
                WindUI:Notify({ Title = "สถานะ", Content = "ปิดใช้งาน Fly + Noclip", Icon = "feather" })
            end
        end
    })

    FlySection:Slider({
        Title = "ความเร็วในการบิน",
        Desc = "ปรับความเร็วในการบิน",
        Value = { Default = 100, Min = 10, Max = 1000 },
        Step = 10,
        Callback = function(value)
            flySpeed = value
        end
    })

    -- Handle character respawn
    LocalPlayer.CharacterAdded:Connect(function(character)
        task.wait(1)
        if godModeToggle and godModeToggle.Value then
            applyGodMode(character)
        end
        -- Note: Fly mode will be disabled on respawn, which is standard behavior.
    end)
end