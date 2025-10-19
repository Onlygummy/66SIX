-- D:/Script/tabs/main_tab.lua
-- This is the merged version with the old stable Spy function and the new God Mode function.

return function(Tab, Window, WindUI, TeleportService)
    -- Services
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local UserInputService = game:GetService("UserInputService")
    local ContextActionService = game:GetService("ContextActionService")
    local Camera = game:GetService("Workspace").CurrentCamera
    local RunService = game:GetService("RunService")

    -- State Variables
    local isCameraMode = false
    local originalCameraCFrame = nil
    local cameraTarget = nil
    local selectedPlayer = nil
    local yaw, pitch, zoomDistance = 0, 0, 10
    local minZoom, maxZoom = 5, 20
    local cameraSpeed = 0.03
    local isWPressed, isAPressed, isSPressed, isDPressed = false, false, false, false
    local targetLostDebounce = false

    local isFollowing = false
    local followLoop = nil
    local bodyVelocity, bodyPosition

    -- Forward-declare UI elements and functions
    local playerDropdown
    local statusParagraph
    local spyButton
    local restoreCamera

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



    restoreCamera = function()
        if not isCameraMode then return end

        if originalCameraCFrame then Camera.CFrame = originalCameraCFrame end
        
        Camera.CameraType = Enum.CameraType.Custom
        isCameraMode = false
        cameraTarget = nil
        yaw, pitch, zoomDistance = 0, 0, 10
        isWPressed, isAPressed, isSPressed, isDPressed = false, false, false, false
        targetLostDebounce = false

        ContextActionService:UnbindAction("SpyCameraControlW")
        ContextActionService:UnbindAction("SpyCameraControlA")
        ContextActionService:UnbindAction("SpyCameraControlS")
        ContextActionService:UnbindAction("SpyCameraControlD")

        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 16
            LocalPlayer.Character.Humanoid.JumpPower = 50
        end
        setPlayerScriptsEnabled(true)

        -- spyButton is now a toggle, no need to set title
        if statusParagraph then statusParagraph:SetDesc("เป้าหมาย: " .. (selectedPlayer and selectedPlayer.Name or "ยังไม่ได้เลือก")) end
        WindUI:Notify({ Title = "สถานะ", Content = "ออกจากโหมดส่องแล้ว", Icon = "camera-off" })
    end

    local function moveCameraToPlayer(targetPlayer)
        if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("Head") then
            WindUI:Notify({ Title = "ข้อผิดพลาด", Content = "เป้าหมายไม่ถูกต้อง", Icon = "x" })
            return false
        end
        
        isCameraMode = true
        originalCameraCFrame = Camera.CFrame
        cameraTarget = targetPlayer
        yaw, pitch, zoomDistance = 0, 0, 10

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
        
        -- spyButton is now a toggle, no need to set title
        WindUI:Notify({ Title = "สถานะ", Content = "เข้าสู่โหมดส่อง! ใช้ WASD ควบคุม", Icon = "camera" })
        return true
    end

    local function teleportToPlayer(targetPlayer)
        if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        if not TeleportService then return end -- Safety check

        local targetRoot = targetPlayer.Character.HumanoidRootPart
        local destination = targetRoot.Position + Vector3.new(0, 5, 5) -- Calculate destination Vector3

        TeleportService:moveTo(destination)
        WindUI:Notify({ Title = "สำเร็จ", Content = "กำลังเคลื่อนที่ไปยัง " .. targetPlayer.Name, Icon = "check" })
    end

    -- ================================= --
    --      Persistent Event Listeners
    -- ================================= --

    UserInputService.InputChanged:Connect(function(input)
        if isCameraMode and input.UserInputType == Enum.UserInputType.MouseWheel then
            zoomDistance = math.clamp(zoomDistance - input.Position.Z * 2, minZoom, maxZoom)
        end
    end)

    RunService.RenderStepped:Connect(function()
        if isCameraMode and cameraTarget and cameraTarget.Character and cameraTarget.Character:FindFirstChild("Head") then
            Camera.CameraType = Enum.CameraType.Scriptable
            if Camera.CameraType ~= Enum.CameraType.Scriptable then
                Camera.CameraType = Enum.CameraType.Scriptable
            end
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default

            local targetPos = cameraTarget.Character.Head.Position
            if isWPressed then pitch = math.clamp(pitch - cameraSpeed, -math.pi / 3, math.pi / 3) end
            if isSPressed then pitch = math.clamp(pitch + cameraSpeed, -math.pi / 3, math.pi / 3) end
            if isAPressed then yaw = yaw + cameraSpeed end
            if isDPressed then yaw = yaw - cameraSpeed end

            local cameraPos = targetPos + CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0) * Vector3.new(0, 5, zoomDistance)
            Camera.CFrame = CFrame.new(cameraPos, targetPos)
            targetLostDebounce = false

        elseif isCameraMode and not targetLostDebounce then
            targetLostDebounce = true
            if statusParagraph then statusParagraph:SetDesc("เป้าหมาย: หายไป (รอ 3 วินาที)") end
            task.wait(3)
            if isCameraMode and (not cameraTarget or not cameraTarget.Character or not cameraTarget.Character:FindFirstChild("Head")) then
                restoreCamera()
            end
        end


    end)

    -- ================================= --
    --      WindUI Element Creation
    -- ================================= --

    -- Section 1: Target Selection
    local TargetSection = Tab:Section({
        Title = "การเลือกเป้าหมาย",
        Icon = "crosshair",
        Opened = true
    })

    statusParagraph = TargetSection:Paragraph({
        Title = "สถานะ",
        Desc = "เป้าหมาย: ยังไม่ได้เลือก"
    })

    playerDropdown = TargetSection:Dropdown({
        Title = "เลือกเป้าหมาย",
        Desc = "เลือกผู้เล่นที่จะส่องหรือเทเลพอร์ต",
        Values = {},
        SearchBarEnabled = true,
        Callback = function(playerName)
            selectedPlayer = Players:FindFirstChild(playerName)
            if selectedPlayer then
                statusParagraph:SetDesc("เป้าหมาย: " .. selectedPlayer.Name)
            else
                statusParagraph:SetDesc("เป้าหมาย: ไม่พบผู้เล่น")
            end
            playerDropdown:Close()
        end
    })

    local function refreshPlayerList()
        local playerNames = {}
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                table.insert(playerNames, player.Name)
            end
        end
        playerDropdown:Refresh(playerNames)
    end

    TargetSection:Button({
        Title = "รีเฟรชรายชื่อผู้เล่น",
        Icon = "refresh-cw",
        Callback = function()
            refreshPlayerList()
            WindUI:Notify({ Title = "สำเร็จ", Content = "รีเฟรชรายชื่อผู้เล่นแล้ว", Icon = "check" })
        end
    })

    -- Section 2: Actions
    local ActionSection = Tab:Section({
        Title = "คำสั่ง",
        Icon = "zap",
        Opened = true
    })

    local spyToggle -- Forward declare for the callback
    spyToggle = ActionSection:Toggle({
        Title = "ส่อง",
        Icon = "camera",
        Callback = function(value)
            if value then
                if not moveCameraToPlayer(selectedPlayer) then
                    task.wait()
                    spyToggle:SetValue(false)
                end
            else
                if isCameraMode then
                    restoreCamera()
                end
            end
        end
    })

    -- Combined Spy/Follow God Mode implementation
    local flySpeed = 50
    local isFollowModeActive = false
    local bodyVelocity, bodyGyro
    local followAndCameraLoop, noclipLoop
    local isAutoDescending = false

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

    local function updateFollowAndCamera()
        if not isFollowModeActive then return end

        -- Part 1: Update Camera (from original spy logic)
        if isCameraMode and cameraTarget and cameraTarget.Character and cameraTarget.Character:FindFirstChild("Head") then
            Camera.CameraType = Enum.CameraType.Scriptable
            if Camera.CameraType ~= Enum.CameraType.Scriptable then Camera.CameraType = Enum.CameraType.Scriptable end
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default

            local targetPos = cameraTarget.Character.Head.Position
            if isWPressed then pitch = math.clamp(pitch - cameraSpeed, -math.pi / 3, math.pi / 3) end
            if isSPressed then pitch = math.clamp(pitch + cameraSpeed, -math.pi / 3, math.pi / 3) end
            if isAPressed then yaw = yaw + cameraSpeed end
            if isDPressed then yaw = yaw - cameraSpeed end

            local cameraPos = targetPos + CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0) * Vector3.new(0, 5, zoomDistance)
            Camera.CFrame = CFrame.new(cameraPos, targetPos)
        end

        -- Part 2: Update Player Movement (fully automatic)
        local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart or not rootPart.Parent then return end

        local moveDir = Vector3.new(0, 0, 0)

        if isAutoDescending then
            if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local targetRootPart = selectedPlayer.Character.HumanoidRootPart
                local targetY = targetRootPart.Position.Y - 12 -- Dynamic target Y
                if rootPart.Position.Y > targetY then
                    moveDir = moveDir + Vector3.new(0, -1, 0)
                else
                    isAutoDescending = false -- Stop auto-descent once target Y is reached
                end
            else
                isAutoDescending = false
            end
        else -- Auto-follow logic
            if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local targetRootPart = selectedPlayer.Character.HumanoidRootPart
                local direction = targetRootPart.Position - rootPart.Position
                local horizontalDirection = Vector3.new(direction.X, 0, direction.Z)
                if horizontalDirection.Magnitude > 7 then
                    moveDir = moveDir + horizontalDirection
                end
            end
        end

        if moveDir.Magnitude > 0 then
            bodyVelocity.Velocity = moveDir.Unit * flySpeed
        else
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end

        if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character.PrimaryPart then
            local targetPos = selectedPlayer.Character.PrimaryPart.Position
            local lookAtPos = Vector3.new(targetPos.X, rootPart.Position.Y, targetPos.Z)
            bodyGyro.CFrame = CFrame.new(rootPart.Position, lookAtPos)
        end
    end

    local followToggle
    followToggle = ActionSection:Toggle({
        Title = "ติดตาม",
        Icon = "user-check",
        Callback = function(value)
            isFollowModeActive = value
            local char = LocalPlayer.Character
            if not char then return end
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local rootPart = char:FindFirstChild("HumanoidRootPart")

            if value then
                if not selectedPlayer or not selectedPlayer.Character then
                    WindUI:Notify({ Title = "ข้อผิดพลาด", Content = "กรุณาเลือกเป้าหมายก่อน", Icon = "x" })
                    task.wait()
                    followToggle:SetValue(false)
                    isFollowModeActive = false
                    return
                end
                if not humanoid or not rootPart then
                     WindUI:Notify({ Title = "ข้อผิดพลาด", Content = "ไม่พบตัวละคร", Icon = "x" })
                    task.wait()
                    followToggle:SetValue(false)
                    isFollowModeActive = false
                    return
                end
                
                -- Store original CFrame for snap-back
                originalFollowCFrame = rootPart.CFrame

                -- Activate states
                isAutoDescending = true
                isCameraMode = true

                -- Activate God Mode
                setupFlyMovers()
                bodyVelocity.Parent = rootPart
                bodyGyro.Parent = rootPart
                humanoid.PlatformStand = true
                noclipLoop = RunService.Stepped:Connect(function() setNoclip(true) end)

                -- Activate Spy Camera
                originalCameraCFrame = Camera.CFrame
                cameraTarget = selectedPlayer
                yaw, pitch, zoomDistance = 0, 0, 10
                local function createKeybind(name, key) 
                    ContextActionService:BindActionAtPriority(name, function(_, s) 
                        if UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
                        if name == "SpyCameraControlW" then isWPressed = (s == Enum.UserInputState.Begin) end
                        if name == "SpyCameraControlA" then isAPressed = (s == Enum.UserInputState.Begin) end
                        if name == "SpyCameraControlS" then isSPressed = (s == Enum.UserInputState.Begin) end
                        if name == "SpyCameraControlD" then isDPressed = (s == Enum.UserInputState.Begin) end
                        return Enum.ContextActionResult.Sink 
                    end, false, 2001, key)
                end
                createKeybind("SpyCameraControlW", Enum.KeyCode.W)
                createKeybind("SpyCameraControlA", Enum.KeyCode.A)
                createKeybind("SpyCameraControlS", Enum.KeyCode.S)
                createKeybind("SpyCameraControlD", Enum.KeyCode.D)

                -- Start combined loop
                if followAndCameraLoop then followAndCameraLoop:Disconnect() end
                followAndCameraLoop = RunService.RenderStepped:Connect(updateFollowAndCamera)
                
                WindUI:Notify({ Title = "ติดตาม", Content = "เปิดใช้งานโหมดติดตามอัตโนมัติ", Icon = "user-check" })
            else
                -- Deactivate everything
                isAutoDescending = false
                isCameraMode = false

                if followAndCameraLoop then followAndCameraLoop:Disconnect(); followAndCameraLoop = nil end
                if noclipLoop then noclipLoop:Disconnect(); noclipLoop = nil end

                if bodyVelocity then bodyVelocity.Parent = nil end
                if bodyGyro then bodyGyro.Parent = nil end
                if humanoid then humanoid.PlatformStand = false end
                setNoclip(false)

                ContextActionService:UnbindAction("SpyCameraControlW")
                ContextActionService:UnbindAction("SpyCameraControlA")
                ContextActionService:UnbindAction("SpyCameraControlS")
                ContextActionService:UnbindAction("SpyCameraControlD")

                if originalCameraCFrame then Camera.CFrame = originalCameraCFrame end
                Camera.CameraType = Enum.CameraType.Custom

                -- Snap back to original position
                if originalFollowCFrame and rootPart and rootPart.Parent then
                    rootPart.CFrame = originalFollowCFrame
                    originalFollowCFrame = nil
                end

                WindUI:Notify({ Title = "ติดตาม", Content = "ปิดใช้งานแล้ว", Icon = "user-x" })
            end
        end
    })
    ActionSection:Button({
        Title = "เทเลพอร์ต",
        Icon = "send",
        Callback = function()
            if selectedPlayer then
                teleportToPlayer(selectedPlayer)
            else
                WindUI:Notify({ Title = "ข้อผิดพลาด", Content = "กรุณาเลือกเป้าหมายก่อน", Icon = "x" })
            end
        end
    })

    -- Initial population of the player list
    refreshPlayerList()


end