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
    local originalCameraCFrame = nil
    local cameraTarget = nil
    local selectedPlayer = nil
    local yaw, pitch, zoomDistance = 0, 0, 10
    local minZoom, maxZoom = 5, 20
    local cameraSpeed = 0.03
    local isWPressed, isAPressed, isSPressed, isDPressed = false, false, false, false
    local renderSteppedConnection = nil
    local targetLostDebounce = false

    -- Forward-declare UI elements and functions
    local playerDropdown
    local statusParagraph
    local spyButton
    local restoreCamera

    -- ================================= --
    --  Core Logic from Teleport Script
    -- ================================= --

    local function updateCamera()
        if isCameraMode and cameraTarget and cameraTarget.Character and cameraTarget.Character:FindFirstChild("Head") then
            Camera.CameraType = Enum.CameraType.Scriptable
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
            statusParagraph:SetDesc("เป้าหมาย: หายไป (รอ 3 วินาที)")
            task.wait(3)
            if isCameraMode and (not cameraTarget or not cameraTarget.Character or not cameraTarget.Character:FindFirstChild("Head")) then
                restoreCamera()
            end
        end
    end

    restoreCamera = function()
        if not isCameraMode then return end

        if renderSteppedConnection then
            renderSteppedConnection:Disconnect()
            renderSteppedConnection = nil
        end

        if originalCameraCFrame then
            Camera.CFrame = originalCameraCFrame
        end
        
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

        if spyButton then spyButton:SetTitle("ส่อง (SPY)") end
        statusParagraph:SetDesc("เป้าหมาย: " .. (selectedPlayer and selectedPlayer.Name or "ยังไม่ได้เลือก"))

        local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
        if playerScripts then
            local control = playerScripts:FindFirstChild("PlayerModule"):FindFirstChild("ControlModule")
            if control then require(control):Enable() end
        end
    end

    local function moveCameraToPlayer(targetPlayer)
        if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("Head") then
            WindUI:Notify({ Title = "ข้อผิดพลาด", Content = "เป้าหมายไม่ถูกต้อง", Icon = "x" })
            return false
        end
        
        isCameraMode = true
        originalCameraCFrame = Camera.CFrame
        cameraTarget = targetPlayer
        Camera.CameraType = Enum.CameraType.Scriptable
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

        local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
        if playerScripts then
            local control = playerScripts:FindFirstChild("PlayerModule"):FindFirstChild("ControlModule")
            if control then require(control):Disable() end
        end

        if not renderSteppedConnection then
            renderSteppedConnection = RunService.RenderStepped:Connect(updateCamera)
        end
        
        spyButton:SetTitle("หยุดส่อง (STOP)")
        return true
    end

    local function teleportToPlayer(targetPlayer)
        if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myRoot then return end
        myRoot.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3, 5)
        WindUI:Notify({ Title = "สำเร็จ", Content = "เทเลพอร์ตไปยัง " .. targetPlayer.Name, Icon = "check" })
    end

    -- Mouse wheel for zoom
    UserInputService.InputChanged:Connect(function(input)
        if isCameraMode and input.UserInputType == Enum.UserInputType.MouseWheel then
            zoomDistance = math.clamp(zoomDistance - input.Position.Z * 2, minZoom, maxZoom)
        end
    end)

    -- ================================= --
    --      WindUI Element Creation
    -- ================================= --

    statusParagraph = Tab:Paragraph({
        Title = "สถานะ",
        Desc = "เป้าหมาย: ยังไม่ได้เลือก"
    })

    playerDropdown = Tab:Dropdown({
        Title = "เลือกเป้าหมาย",
        Desc = "เลือกผู้เล่นที่จะส่องหรือเทเลพอร์ต",
        Values = {},
        Callback = function(playerName)
            selectedPlayer = Players:FindFirstChild(playerName)
            if selectedPlayer then
                statusParagraph:SetDesc("เป้าหมาย: " .. selectedPlayer.Name)
            else
                statusParagraph:SetDesc("เป้าหมาย: ไม่พบผู้เล่น")
            end
        end
    })

    Tab:Button({
        Title = "รีเฟรชรายชื่อผู้เล่น",
        Icon = "refresh-cw",
        Callback = function()
            local playerNames = {}
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    table.insert(playerNames, player.Name)
                end
            end
            playerDropdown:Refresh(playerNames) 
            WindUI:Notify({ Title = "สำเร็จ", Content = "รีเฟรชรายชื่อผู้เล่นแล้ว", Icon = "check" })
        end
    })

    Tab:Divider()

    spyButton = Tab:Button({
        Title = "ส่อง (SPY)",
        Icon = "camera",
        Callback = function()
            if isCameraMode then
                restoreCamera()
            elseif selectedPlayer then
                moveCameraToPlayer(selectedPlayer)
            else
                WindUI:Notify({ Title = "ข้อผิดพลาด", Content = "กรุณาเลือกเป้าหมายก่อน", Icon = "x" })
            end
        end
    })

    Tab:Button({
        Title = "เทเลพอร์ต (WARP)",
        Icon = "send",
        Callback = function()
            if selectedPlayer then
                teleportToPlayer(selectedPlayer)
            else
                WindUI:Notify({ Title = "ข้อผิดพลาด", Content = "กรุณาเลือกเป้าหมายก่อน", Icon = "x" })
            end
        end
    })
end