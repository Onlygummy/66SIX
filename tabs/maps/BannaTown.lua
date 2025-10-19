return function(Tab, Window, WindUI)
    -- Services
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    -- God Mode function
    local function setNoclip(enabled)
        if not LocalPlayer.Character then return end
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not enabled
            end
        end
    end

    local flySpeed = 16 -- Default to normal walk speed
    local isFlyEnabled = false
    local bodyVelocity, bodyGyro
    local flyLoop, noclipLoop

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

    local function updateFlyMovement()
        if not isFlyEnabled or not LocalPlayer.Character then return end
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart or not workspace.CurrentCamera then return end
        local moveDir = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + workspace.CurrentCamera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - workspace.CurrentCamera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - workspace.CurrentCamera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + workspace.CurrentCamera.CFrame.RightVector end
        bodyVelocity.Velocity = moveDir * flySpeed
        bodyGyro.CFrame = workspace.CurrentCamera.CFrame
    end

    local function setFly(value)
        isFlyEnabled = value
        local char = LocalPlayer.Character
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        if not humanoid or not rootPart then return end

        if value then
            setupFlyMovers()
            bodyVelocity.Parent = rootPart
            bodyGyro.Parent = rootPart
            humanoid.PlatformStand = true
            if flyLoop then flyLoop:Disconnect() end
            if noclipLoop then noclipLoop:Disconnect() end
            flyLoop = RunService.RenderStepped:Connect(updateFlyMovement)
            noclipLoop = RunService.Stepped:Connect(function() setNoclip(true) end)
            WindUI:Notify({ Title = "พระเจ้า", Content = "เปิดใช้งาน", Icon = "feather" })
        else
            if bodyVelocity then bodyVelocity.Parent = nil end
            if bodyGyro then bodyGyro.Parent = nil end
            humanoid.PlatformStand = false
            if flyLoop then flyLoop:Disconnect(); flyLoop = nil end
            if noclipLoop then noclipLoop:Disconnect(); noclipLoop = nil end
            setNoclip(false)
            WindUI:Notify({ Title = "พระเจ้า", Content = "ปิดใช้งาน", Icon = "feather" })
        end
    end
    
    Tab:Toggle({
        Title = "พระเจ้า",
        Icon = "feather",
        Desc = "โหมดบินและเดินทะลุสิ่งกีดขวาง",
        Value = false,
        Callback = function(value) setFly(value) end
    })

    Tab:Slider({
        Title = "ปรับความเร็ว",
        Desc = "ปรับความเร็วของโหมดพระเจ้า",
        Value = {
            Default = 16,
            Min = 10,
            Max = 200
        },
        Step = 1,
        Callback = function(value)
            flySpeed = value
        end
    })
end