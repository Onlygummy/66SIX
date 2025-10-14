-- D:/Script/tabs/self_tab.lua
-- ไฟล์นี้จะเก็บโค้ดทั้งหมดที่เกี่ยวกับแท็บ "ส่วนตัว"

return function(Tab, Window, WindUI)
    -- Services
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")

    -- Fly and Noclip Variables
    local flySpeed = 50 -- ความเร็วคงที่
    local flying = false
    local noclip = false
    local bodyVelocity, bodyGyro
    local isFly = false -- To handle respawn

    -- ================================= --
    --      Fly + Noclip Logic
    -- ================================= --

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
        
        -- Use the exact logic from the reference script
        bodyVelocity.Velocity = moveDir * flySpeed
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

    local function setFly(value)
        isFly = value
        flying = value
        noclip = value -- Sync noclip with flying
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
            WindUI:Notify({ Title = "สถานะ", Content = "เปิดใช้งาน Fly / Noclip", Icon = "feather" })
        else
            if bodyVelocity then bodyVelocity.Parent = nil end
            if bodyGyro then bodyGyro.Parent = nil end
            humanoid.PlatformStand = false
            WindUI:Notify({ Title = "สถานะ", Content = "ปิดใช้งาน Fly / Noclip", Icon = "feather" })
        end
    end

    -- Connect persistent listeners
    RunService.RenderStepped:Connect(updateMovement)
    RunService.Stepped:Connect(updateNoclip)

    -- ================================= --
    --      WindUI Element Creation
    -- ================================= --

    local GodModeSection = Tab:Section({ Title = "God Mode", Icon = "feather", Opened = true })
    
    GodModeSection:Toggle({
        Title = "God Mode",
        Desc = "เปิด/ปิดโหมด God (บิน, เดินทะลุ)",
        Value = false,
        Callback = function(value)
            setFly(value)
        end
    })

    -- Handle character respawn
    LocalPlayer.CharacterAdded:Connect(function(character)
        task.wait(1)
        -- Fly mode will be disabled on respawn, which is standard behavior.
        if isFly then
            setFly(false)
        end
    end)
end