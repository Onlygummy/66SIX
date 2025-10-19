return function(Tab, Window, WindUI, TeleportService)
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

    Tab:Divider()

    -- ================================= --
    --      Farm Teleport
    -- ================================= --
    local FarmSection = Tab:Section({
        Title = "เทเลพอร์ตฟาร์ม",
        Icon = "tractor",
        Opened = true
    })

    local farmLocations = {
        { Name = "เนื้อ", Pos = Vector3.new(-1391.72, 16.75, -155.69) },
        { Name = "ไม้", Pos = Vector3.new(-1449.32, 16.54, -378.36) },
        { Name = "ข้าวโพด", Pos = Vector3.new(-4897.09, 36.43, -3786.27) },
        { Name = "กล้วย", Pos = Vector3.new(-4620.16, 16.54, -2758.60) },
        { Name = "ส้ม", Pos = Vector3.new(-3642.50, 16.54, -4024.09) },
        { Name = "แอปเปิ้ล", Pos = Vector3.new(-2072.55, 16.54, -3247.81) },
        { Name = "ทุเรียน", Pos = Vector3.new(-1890.37, 16.54, -1931.15) },
        { Name = "องุ่น", Pos = Vector3.new(-3496.18, 36.43, -212.87) },
        { Name = "สตอเบอรี่", Pos = Vector3.new(-4489.14, 36.43, 645.12) },
        { Name = "สัปปะรด", Pos = Vector3.new(-2316.62, 36.43, 962.75) },
        { Name = "มะม่วง", Pos = Vector3.new(-1803.09, 36.79, -39.39) },
        { Name = "ข้าวสาลี", Pos = Vector3.new(-1449.43, 16.54, 1038.49) },
        { Name = "ไก่", Pos = Vector3.new(-3075.27, 16.54, -1637.17) }
    }

    local farmNames = {}
    for _, loc in ipairs(farmLocations) do
        table.insert(farmNames, loc.Name)
    end

    local selectedFarm = nil
    local farmDropdown -- Forward declare

    farmDropdown = FarmSection:Dropdown({
        Title = "เลือกฟาร์ม",
        Desc = "เลือกตำแหน่งฟาร์มที่ต้องการเทเลพอร์ต",
        Values = farmNames,
        SearchBarEnabled = true, -- Add search bar
        Callback = function(farmName)
            for _, loc in ipairs(farmLocations) do
                if loc.Name == farmName then
                    selectedFarm = loc
                    break
                end
            end
            farmDropdown:Close() -- Add auto-close
        end
    })

    FarmSection:Button({
        Title = "เทเลพอร์ต",
        Icon = "send",
        Callback = function()
            if selectedFarm and TeleportService then
                TeleportService:moveTo(selectedFarm.Pos)
                WindUI:Notify({ Title = "สำเร็จ", Content = "กำลังเคลื่อนที่ไปยัง " .. selectedFarm.Name, Icon = "check" })
            elseif not selectedFarm then
                WindUI:Notify({ Title = "ข้อผิดพลาด", Content = "กรุณาเลือกฟาร์มก่อน", Icon = "x" })
            end
        end
    })
end