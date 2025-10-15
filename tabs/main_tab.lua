-- D:/Script/tabs/main_tab.lua
-- ไฟล์นี้จะเก็บโค้ดทั้งหมดที่เกี่ยวกับ "แท็บหน้าหลัก"

return function(Tab, Window, WindUI)
    -- Services
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local UserInputService = game:GetService("UserInputService")
    local ContextActionService = game:GetService("ContextActionService")
    local Camera = game:GetService("Workspace").CurrentCamera
    local RunService = game:GetService("RunService")

    -- State Variables
    local isCameraMode = false
    local isTrackerMode = false
    local originalPlayerCFrame = nil
    local originalCameraCFrame = nil
    local cameraTarget = nil
    local selectedPlayer = nil
    local yaw, pitch, zoomDistance = 0, 0, 10
    local minZoom, maxZoom = 5, 20
    local cameraSpeed = 0.03
    local isWPressed, isAPressed, isSPressed, isDPressed = false, false, false, false
    local targetLostDebounce = false

    -- Forward-declare UI elements
    local playerDropdown
    local statusParagraph
    local spyButton
    local trackerButton
    local restoreAllModes

    -- ================================= --
    --  Core Logic
    -- ================================= --

    local function setPlayerScriptsEnabled(enabled)
        local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
        if playerScripts then
            for _, script in pairs(playerScripts:GetChildren()) do
                if script.Name == "PlayerModule" or script.Name == "ControlModule" then
                    script.Disabled = not enabled
                end
            end
        end
    end

    local function setNoclip(enabled)
        if not LocalPlayer.Character then return end
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not enabled
            end
        end
    end

    local function setTransparency(enabled)
        if not LocalPlayer.Character then return end
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") or part:IsA("Decal") then
                part.Transparency = enabled and 0.7 or 0
            end
        end
    end

    restoreAllModes = function()
        if not (isCameraMode or isTrackerMode) then return end

        -- Restore Camera (based on old working version)
        if originalCameraCFrame then Camera.CFrame = originalCameraCFrame end
        Camera.CameraType = Enum.CameraType.Custom
        -- NOTE: Do not set Camera.CameraSubject, let the engine handle it. This seems to be the key.

        ContextActionService:UnbindAction("SpyCameraControlW")
        ContextActionService:UnbindAction("SpyCameraControlA")
        ContextActionService:UnbindAction("SpyCameraControlS")
        ContextActionService:UnbindAction("SpyCameraControlD")

        -- Restore Player
        if originalPlayerCFrame then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = originalPlayerCFrame
            end
        end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 16
            LocalPlayer.Character.Humanoid.JumpPower = 50
        end
        setPlayerScriptsEnabled(true)
        setNoclip(false)
        setTransparency(false)

        -- Reset State Variables
        isCameraMode = false
        isTrackerMode = false
        cameraTarget = nil
        originalPlayerCFrame = nil
        originalCameraCFrame = nil
        yaw, pitch, zoomDistance = 0, 0, 10
        isWPressed, isAPressed, isSPressed, isDPressed = false, false, false, false
        targetLostDebounce = false

        -- Update UI (WindUI v1.6 does not seem to have a SetTitle method, so we can't change button text)
        if statusParagraph then statusParagraph:SetDesc("เป้าหมาย: " .. (selectedPlayer and selectedPlayer.Name or "ยังไม่ได้เลือก")) end
        WindUI:Notify({ Title = "สถานะ", Content = "ออกจากโหมดพิเศษแล้ว", Icon = "camera-off" })
    end

    local function startSpyMode(targetPlayer)
        if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("Head") then
            WindUI:Notify({ Title = "ข้อผิดพลาด", Content = "เป้าหมายไม่ถูกต้อง", Icon = "x" })
            return false
        end
        
        isCameraMode = true
        originalCameraCFrame = Camera.CFrame
        cameraTarget = targetPlayer

        local function createKeybind(name, key) 
            ContextActionService:BindActionAtPriority(name, function(_, state) 
                if UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
                if name == "SpyCameraControlW" then isWPressed = (state == Enum.UserInputState.Begin) end
                if name == "SpyCameraControlA" then isAPressed = (state == Enum.UserInputState.Begin) end
                if name == "SpyCameraControlS" then isSPressed = (state == Enum.UserInputState.Begin) end
                if name == "SpyCameraControlD" then isDPressed = (state == Enum.UserInputState.Begin) end
                return Enum.ContextActionResult.Sink 
            end, false, 2001, key)
        end
        createKeybind("SpyCameraControlW", Enum.KeyCode.W)
        createKeybind("SpyCameraControlA", Enum.KeyCode.A)
        createKeybind("SpyCameraControlS", Enum.KeyCode.S)
        createKeybind("SpyCameraControlD", Enum.KeyCode.D)

        setPlayerScriptsEnabled(false)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 0
            LocalPlayer.Character.Humanoid.JumpPower = 0
        end
        
        WindUI:Notify({ Title = "สถานะ", Content = "เข้าสู่โหมดส่อง! ใช้ WASD ควบคุมกล้อง", Icon = "camera" })
        return true
    end

    local function startTrackerMode(targetPlayer)
        if isCameraMode then restoreAllModes() end -- Stop spy mode if active
        if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("Head") then
            WindUI:Notify({ Title = "ข้อผิดพลาด", Content = "เป้าหมายไม่ถูกต้อง", Icon = "x" })
            return false
        end
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            WindUI:Notify({ Title = "ข้อผิดพลาด", Content = "ไม่พบตัวละครของคุณ", Icon = "x" })
            return false
        end

        isTrackerMode = true
        isCameraMode = true -- Tracker mode is an extension of camera mode
        originalPlayerCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
        originalCameraCFrame = Camera.CFrame
        cameraTarget = targetPlayer

        -- Reuse keybinds from spy mode
        startSpyMode(targetPlayer)
        isCameraMode = true -- startSpyMode sets it, but just to be sure
        isTrackerMode = true -- startSpyMode doesn't know about tracker mode

        setNoclip(true)
        setTransparency(true)
        
        WindUI:Notify({ Title = "สถานะ", Content = "เข้าสู่โหมด Tracker!", Icon = "footprints" })
        return true
    end

    local function teleportToPlayer(targetPlayer)
        if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        myRoot.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 5)
        WindUI:Notify({ Title = "สำเร็จ", Content = "เทเลพอร์ตไปยัง " .. targetPlayer.Name, Icon = "check" })
    end

    -- ================================= --
    --      Persistent Event Listeners
    -- ================================= --

    UserInputService.InputChanged:Connect(function(input)
        if (isCameraMode or isTrackerMode) and input.UserInputType == Enum.UserInputType.MouseWheel then
            zoomDistance = math.clamp(zoomDistance - input.Position.Z * 2, minZoom, maxZoom)
        end
    end)

    RunService.RenderStepped:Connect(function()
        local inSpecialMode = isCameraMode or isTrackerMode
        if inSpecialMode and cameraTarget and cameraTarget.Character and cameraTarget.Character:FindFirstChild("Head") then
            Camera.CameraType = Enum.CameraType.Scriptable
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default

            local targetPos = cameraTarget.Character.Head.Position
            if isWPressed then pitch = math.clamp(pitch - cameraSpeed, -math.pi / 3, math.pi / 3) end
            if isSPressed then pitch = math.clamp(pitch + cameraSpeed, -math.pi / 3, math.pi / 3) end
            if isAPressed then yaw = yaw + cameraSpeed end
            if isDPressed then yaw = yaw - cameraSpeed end
            local cameraPos = targetPos + CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0) * Vector3.new(0, 5, zoomDistance)
            Camera.CFrame = CFrame.new(cameraPos, targetPos)
            
            if isTrackerMode then
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local targetRoot = cameraTarget.Character:FindFirstChild("HumanoidRootPart")
                if myRoot and targetRoot then
                    myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, -5, 0)
                end
            end
            targetLostDebounce = false

        elseif inSpecialMode and not targetLostDebounce then
            targetLostDebounce = true
            if statusParagraph then statusParagraph:SetDesc("เป้าหมาย: หายไป (รอ 3 วินาที)") end
            task.wait(3)
            if (isCameraMode or isTrackerMode) and (not cameraTarget or not cameraTarget.Character or not cameraTarget.Character:FindFirstChild("Head")) then
                restoreAllModes()
            end
        end
    end)

    -- ================================= --
    --      WindUI Element Creation
    -- ================================= --

    local TargetSection = Tab:Section({ Title = "การเลือกเป้าหมาย", Icon = "crosshair", Opened = true })
    statusParagraph = TargetSection:Paragraph({ Title = "สถานะ", Desc = "เป้าหมาย: ยังไม่ได้เลือก" })
    playerDropdown = TargetSection:Dropdown({
        Title = "เลือกเป้าหมาย",
        Desc = "เลือกผู้เล่นที่จะส่องหรือเทเลพอร์ต",
        Values = {},
        SearchBarEnabled = true,
        Callback = function(playerName)
            selectedPlayer = Players:FindFirstChild(playerName)
            if selectedPlayer then statusParagraph:SetDesc("เป้าหมาย: " .. selectedPlayer.Name)
            else statusParagraph:SetDesc("เป้าหมาย: ไม่พบผู้เล่น") end
            playerDropdown:Close()
        end
    })
    TargetSection:Button({
        Title = "รีเฟรชรายชื่อผู้เล่น",
        Icon = "refresh-cw",
        Callback = function()
            local playerNames = {}
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then table.insert(playerNames, player.Name) end
            end
            playerDropdown:Refresh(playerNames)
            WindUI:Notify({ Title = "สำเร็จ", Content = "รีเฟรชรายชื่อผู้เล่นแล้ว", Icon = "check" })
        end
    })

    local ActionSection = Tab:Section({ Title = "คำสั่งทั่วไป", Icon = "zap", Opened = true })
    spyButton = ActionSection:Button({
        Title = "ส่อง",
        Icon = "camera",
        Callback = function()
            if isCameraMode and not isTrackerMode then
                restoreAllModes()
            elseif selectedPlayer then
                if isTrackerMode then restoreAllModes() end
                startSpyMode(selectedPlayer)
            else
                WindUI:Notify({ Title = "ข้อผิดพลาด", Content = "กรุณาเลือกเป้าหมายก่อน", Icon = "x" })
            end
        end
    })
    ActionSection:Button({
        Title = "เทเลพอร์ต",
        Icon = "send",
        Callback = function()
            if selectedPlayer then teleportToPlayer(selectedPlayer)
            else WindUI:Notify({ Title = "ข้อผิดพลาด", Content = "กรุณาเลือกเป้าหมายก่อน", Icon = "x" }) end
        end
    })

    -- ================================= --
    --      Map-Specific Section
    -- ================================= --
    local BANNATOWN_PLACE_ID = 77837537595343
    if game.PlaceId == BANNATOWN_PLACE_ID then
        local BannaTownSection = Tab:Section({ Title = "BannaTown", Icon = "map-pin", Opened = true })

        local flySpeed = 50
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
                WindUI:Notify({ Title = "God Mode", Content = "เปิดใช้งาน", Icon = "feather" })
            else
                if bodyVelocity then bodyVelocity.Parent = nil end
                if bodyGyro then bodyGyro.Parent = nil end
                humanoid.PlatformStand = false
                if flyLoop then flyLoop:Disconnect(); flyLoop = nil end
                if noclipLoop then noclipLoop:Disconnect(); noclipLoop = nil end
                setNoclip(false)
                WindUI:Notify({ Title = "God Mode", Content = "ปิดใช้งาน", Icon = "feather" })
            end
        end
        
        BannaTownSection:Toggle({
            Title = "God Mode",
            Desc = "เปิด/ปิดโหมด God (บิน, เดินทะลุ)",
            Value = false,
            Callback = function(value) setFly(value) end
        })

        trackerButton = BannaTownSection:Button({
            Title = "Tracker",
            Icon = "footprints",
            Callback = function()
                if isTrackerMode then
                    restoreAllModes()
                elseif selectedPlayer then
                    startTrackerMode(selectedPlayer)
                else
                    WindUI:Notify({ Title = "ข้อผิดพลาด", Content = "กรุณาเลือกเป้าหมายก่อน", Icon = "x" })
                end
            end
        })
    end

    -- Initial population of the player list
    local playerNames = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then table.insert(playerNames, player.Name) end
    end
    playerDropdown:Refresh(playerNames)
end