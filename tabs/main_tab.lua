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

    -- NEW: Touch control variables
    local touchCameraSensitivity = 0.01 -- Increased Sensitivity
    local lastPanPosition
    local lastPinchDistance

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
        lastPanPosition = nil
        lastPinchDistance = nil

        ContextActionService:UnbindAction("SpyCameraControlW")
        ContextActionService:UnbindAction("SpyCameraControlA")
        ContextActionService:UnbindAction("SpyCameraControlS")
        ContextActionService:UnbindAction("SpyCameraControlD")

        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 16
            LocalPlayer.Character.Humanoid.JumpPower = 50
        end
        setPlayerScriptsEnabled(true)

    end

    local function moveCameraToPlayer(targetPlayer)
        if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("Head") then

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
        
        return true
    end

    local function teleportToPlayer(targetPlayer)
        if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        if not TeleportService then return end -- Safety check

        local targetRoot = targetPlayer.Character.HumanoidRootPart
        local destination = targetRoot.Position + Vector3.new(0, 5, 5) -- Calculate destination Vector3

        TeleportService:moveTo(destination)

    end

    -- ================================= --
    --      Persistent Event Listeners (REVISED FOR MOBILE)
    -- ================================= --

    local function handleRotation(delta)
        yaw = yaw - delta.X * touchCameraSensitivity
        pitch = math.clamp(pitch - delta.Y * touchCameraSensitivity, -math.pi / 2.2, math.pi / 2.2) -- Wider angle
    end

    local function handleZoom(delta)
        zoomDistance = math.clamp(zoomDistance - delta, minZoom, maxZoom)
    end
    
    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if not isCameraMode or gameProcessedEvent then return end

        if input.UserInputType == Enum.UserInputType.Touch then
            local touches = UserInputService:GetTouches()
            if #touches == 1 then
                lastPanPosition = touches[1].Position
                lastPinchDistance = nil -- Ensure pinch state is cleared
            elseif #touches == 2 then
                lastPinchDistance = (touches[1].Position - touches[2].Position).Magnitude
                lastPanPosition = nil -- Ensure pan state is cleared
            end
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input, gameProcessedEvent)
        if not isCameraMode or gameProcessedEvent then return end
        
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            handleZoom(input.Position.Z * 2)
        elseif input.UserInputType == Enum.UserInputType.Touch then
            local touches = UserInputService:GetTouches()
            if #touches == 1 and lastPanPosition then
                -- Single finger drag for rotation
                handleRotation(input.Position - lastPanPosition)
                lastPanPosition = input.Position
            elseif #touches >= 2 and lastPinchDistance then
                -- Two or more finger pinch for zoom
                local touch1 = touches[1]
                local touch2 = touches[2]
                local currentPinchDistance = (touch1.Position - touch2.Position).Magnitude
                local delta = currentPinchDistance - lastPinchDistance
                handleZoom(delta * 0.2) -- Increased sensitivity
                lastPinchDistance = currentPinchDistance
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
        if not isCameraMode or gameProcessedEvent then return end

        if input.UserInputType == Enum.UserInputType.Touch then
            -- Check remaining touches to transition state, e.g., from pinch to pan
            local touches = UserInputService:GetTouches()
            if #touches == 1 then
                lastPanPosition = touches[1].Position
                lastPinchDistance = nil
            elseif #touches >= 2 then
                -- This case might happen if more than 2 fingers were used
                lastPinchDistance = (touches[1].Position - touches[2].Position).Magnitude
                lastPanPosition = nil
            else
                -- No touches left
                lastPanPosition = nil
                lastPinchDistance = nil
            end
        end
    end)

    RunService.RenderStepped:Connect(function()
        if isFollowModeActive then return end -- Prevent conflict with Follow mode's camera handler

        if isCameraMode and cameraTarget and cameraTarget.Character and cameraTarget.Character:FindFirstChild("Head") then
            Camera.CameraType = Enum.CameraType.Scriptable
            if Camera.CameraType ~= Enum.CameraType.Scriptable then
                Camera.CameraType = Enum.CameraType.Scriptable
            end
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default

            local targetPos = cameraTarget.Character.Head.Position
            -- Keyboard input (classic controls)
            if isWPressed then pitch = math.clamp(pitch - cameraSpeed, -math.pi / 2.2, math.pi / 2.2) end
            if isSPressed then pitch = math.clamp(pitch + cameraSpeed, -math.pi / 2.2, math.pi / 2.2) end
            if isAPressed then yaw = yaw + cameraSpeed end
            if isDPressed then yaw = yaw - cameraSpeed end

            local cameraPos = targetPos + CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0) * Vector3.new(0, 5, zoomDistance)
            Camera.CFrame = CFrame.new(cameraPos, targetPos)
            targetLostDebounce = false

        elseif isCameraMode and not targetLostDebounce then
            targetLostDebounce = true
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



    playerDropdown = TargetSection:Dropdown({
        Title = "เลือกเป้าหมาย",
        Values = {},
        SearchBarEnabled = true,
        Callback = function(playerName)
            selectedPlayer = Players:FindFirstChild(playerName)
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

    -- Underground Follow (Teleport) implementation
    local isFollowModeActive = false
    local followLoop, noclipLoop, originalFollowCFrame
    local followDepth = 20 -- Default depth
    local lastFollowY = nil -- For stabilizing Y-axis
    local bodyVelocity = nil -- For stability

    local function setNoclip(enabled)
        if not LocalPlayer.Character then return end
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not enabled
            end
        end
    end

    local function updateFollowTeleport()
        if not isFollowModeActive then return end

        local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local targetRootPart = selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart")

        if not rootPart or not rootPart.Parent or not targetRootPart then return end

        local myPos = rootPart.Position
        local targetPos = targetRootPart.Position
        local horizontalDistance = (Vector2.new(myPos.X, myPos.Z) - Vector2.new(targetPos.X, targetPos.Z)).Magnitude

        if horizontalDistance > 3 then
            local destination = targetPos - Vector3.new(0, followDepth, 0)

            -- Y-Stabilization Logic
            if lastFollowY and math.abs(destination.Y - lastFollowY) < 2 then
                -- If vertical change is small (a bob), use the last stable Y position
                destination = Vector3.new(destination.X, lastFollowY, destination.Z)
            else
                -- If vertical change is large (a jump/fall), update the stable Y position
                lastFollowY = destination.Y
            end
            
            TeleportService:_instant(destination)
        end
    end

    local followToggle
    followToggle = ActionSection:Toggle({
        Title = "ติดตาม",
        Icon = "user-check",
        Callback = function(value)
            isFollowModeActive = value
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local rootPart = char.HumanoidRootPart

            if value then
                if not selectedPlayer or not selectedPlayer.Character then

                    task.wait()
                    followToggle:SetValue(false)
                    isFollowModeActive = false
                    return
                end
                
                originalFollowCFrame = rootPart.CFrame
                lastFollowY = nil 
                noclipLoop = RunService.Stepped:Connect(function() setNoclip(true) end)

                -- Create and apply BodyVelocity for stability
                if bodyVelocity then bodyVelocity:Destroy() end
                bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                bodyVelocity.Parent = rootPart

                if followLoop then task.cancel(followLoop); followLoop = nil end
                followLoop = task.spawn(function()
                    while isFollowModeActive do
                        updateFollowTeleport()
                        task.wait(0.1)
                    end
                end)
                

            else
                if followLoop then task.cancel(followLoop); followLoop = nil end
                if noclipLoop then noclipLoop:Disconnect(); noclipLoop = nil end
                setNoclip(false)

                -- Destroy BodyVelocity
                if bodyVelocity then bodyVelocity:Destroy(); bodyVelocity = nil end

                if originalFollowCFrame then
                    TeleportService:moveTo(originalFollowCFrame.Position)
                    originalFollowCFrame = nil
                end


            end
        end
    })

    ActionSection:Slider({
        Title = "ปรับความลึก",
        Value = {
            Default = 20,
            Min = 5,
            Max = 50
        },
        Step = 1,
        Callback = function(value)
            followDepth = value
            if isFollowModeActive then

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

            end
        end
    })

    -- Initial population of the player list
    refreshPlayerList()


end