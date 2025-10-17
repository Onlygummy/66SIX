-- D:/Script/tabs/main_tab.lua
-- This is the merged version with the old stable Spy function and the new God Mode function.

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

    -- ADDED for God Mode
    local function setNoclip(enabled)
        if not LocalPlayer.Character then return end
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not enabled
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
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        myRoot.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 5)
        WindUI:Notify({ Title = "สำเร็จ", Content = "เทเลพอร์ตไปยัง " .. targetPlayer.Name, Icon = "check" })
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

    local followToggle
    followToggle = ActionSection:Toggle({
        Title = "ติดตาม",
        Icon = "user-check",
        Callback = function(value)
            if value then
                if not selectedPlayer or not selectedPlayer.Character or not selectedPlayer.Character:FindFirstChild("Head") then
                    WindUI:Notify({ Title = "ข้อผิดพลาด", Content = "กรุณาเลือกเป้าหมายที่ถูกต้องก่อน", Icon = "x" })
                    task.wait()
                    followToggle:SetValue(false)
                    return
                end

                -- Start Follow Mode
                isFollowing = true

                -- Store original player state
                local char = LocalPlayer.Character
                local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                local rootPart = humanoid and char:FindFirstChild("HumanoidRootPart")
                originalFollowCFrame = rootPart.CFrame

                -- Create BodyMovers
                bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bodyVelocity.P = 2000
                bodyVelocity.Parent = rootPart

                bodyPosition = Instance.new("BodyPosition")
                bodyPosition.MaxForce = Vector3.new(0, math.huge, 0) -- Only affect Y-axis
                bodyPosition.P = 500000 -- Strong P to maintain position
                bodyPosition.D = 1250 -- Damping
                bodyPosition.Parent = rootPart

                -- Activate God Mode / Noclip
                setNoclip(true)
                humanoid.PlatformStand = true

                -- Activate Spy Camera
                isCameraMode = true
                originalCameraCFrame = Camera.CFrame
                cameraTarget = selectedPlayer
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
                setPlayerScriptsEnabled(false) -- Disable controls

                -- Start the follow loop
                followLoop = RunService.RenderStepped:Connect(function()
                    local targetRootPart = selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not targetRootPart or not rootPart or not rootPart.Parent or not isFollowing then
                        followToggle:SetValue(false) -- Automatically turn off if target is lost
                        return
                    end
                    -- Move our character using BodyVelocity for X/Z and BodyPosition for Y
                    local targetPositionForBodyMovers = Vector3.new(targetRootPart.Position.X, -12, targetRootPart.Position.Z)
                    bodyVelocity.Velocity = Vector3.new(targetRootPart.Velocity.X, 0, targetRootPart.Velocity.Z) -- Match target's X/Z velocity
                    bodyPosition.Position = Vector3.new(rootPart.Position.X, -12, rootPart.Position.Z) -- Y-lock
                end)

                WindUI:Notify({ Title = "ติดตาม", Content = "เปิดใช้งานโหมดติดตาม", Icon = "user-check" })

            else
                if not isFollowing then return end -- Prevent running disable logic twice
                
                -- Stop Follow Mode
                isFollowing = false

                -- Stop the loop
                if followLoop then
                    followLoop:Disconnect()
                    followLoop = nil
                end

                -- Destroy BodyMovers
                if bodyVelocity then bodyVelocity:Destroy(); bodyVelocity = nil end
                if bodyPosition then bodyPosition:Destroy(); bodyPosition = nil end

                -- Restore camera
                if originalCameraCFrame then Camera.CFrame = originalCameraCFrame end
                Camera.CameraType = Enum.CameraType.Custom
                isCameraMode = false
                cameraTarget = nil
                ContextActionService:UnbindAction("SpyCameraControlW")
                ContextActionService:UnbindAction("SpyCameraControlA")
                ContextActionService:UnbindAction("SpyCameraControlS")
                ContextActionService:UnbindAction("SpyCameraControlD")

                -- Restore player character
                local char = LocalPlayer.Character
                local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                local rootPart = humanoid and char:FindFirstChild("HumanoidRootPart")

                setNoclip(false)
                if humanoid then
                    humanoid.PlatformStand = false
                end
                setPlayerScriptsEnabled(true) -- Re-enable controls

                if originalFollowCFrame and rootPart then
                    rootPart.CFrame = originalFollowCFrame
                    originalFollowCFrame = nil
                end

                WindUI:Notify({ Title = "ติดตาม", Content = "ปิดใช้งานโหมดติดตาม", Icon = "user-x" })
            end
        end
    })

    -- ================================= --
    --      Map-Specific Section (God Mode ADDED BACK)
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
            Value = false,
            Callback = function(value) setFly(value) end
        })



    end

    -- Initial population of the player list
    refreshPlayerList()


end