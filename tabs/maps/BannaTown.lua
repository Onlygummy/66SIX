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

    local function triggerProximityPrompt(targetPart)
        print("triggerProximityPrompt: Called with targetPart = " .. tostring(targetPart.Name))
        if not targetPart then print("triggerProximityPrompt: targetPart is nil"); return false end

        -- Find the ProximityPrompt on the target or its parent
        local prompt = targetPart:FindFirstChildOfClass("ProximityPrompt")
        if not prompt then
            prompt = targetPart.Parent and targetPart.Parent:FindFirstChildOfClass("ProximityPrompt")
        end

        if prompt then
            print("triggerProximityPrompt: Found prompt. Name = " .. tostring(prompt.Name) .. ", Enabled = " .. tostring(prompt.Enabled) .. ", HoldDuration = " .. tostring(prompt.HoldDuration))
            if prompt.Enabled then
                print("triggerProximityPrompt: Calling InputHoldBegin()")
                prompt:InputHoldBegin()
                if prompt.HoldDuration > 0 then
                    task.wait(prompt.HoldDuration)
                end
                prompt:InputHoldEnd()
                print("triggerProximityPrompt: Called InputHoldEnd()")
                return true -- Indicate success
            else
                print("triggerProximityPrompt: Prompt is not Enabled.")
            end
        else
            print("triggerProximityPrompt: No ProximityPrompt found on targetPart or its parent.")
        end
        
        return false -- Indicate failure
    end

    local function triggerProximityPromptTrial(targetPart)
        if not targetPart then return false end

        -- Find the ProximityPrompt on the target or its parent
        local prompt = targetPart:FindFirstChildOfClass("ProximityPrompt")
        if not prompt then
            prompt = targetPart.Parent and targetPart.Parent:FindFirstChildOfClass("ProximityPrompt")
        end

        -- If a valid prompt is found, trigger it instantly
        if prompt and prompt.Enabled then
            local originalHoldDuration = prompt.HoldDuration -- Store original
            prompt.HoldDuration = 0 -- Set to 0 for instant activation

            prompt:InputHoldBegin()
            -- No manual wait here, as user wants it instant
            prompt:InputHoldEnd()

            prompt.HoldDuration = originalHoldDuration -- Restore original
            return true -- Indicate success
        end
        
        return false -- Indicate failure
    end

    local function getSpecificShopPrompt()
        -- WARNING: This path uses GetChildren() by index, which is extremely fragile and prone to breaking if the game's hierarchy changes.
        local obj77 = workspace:GetChildren()[77]
        if not obj77 then warn("getSpecificShopPrompt: workspace:GetChildren()[77] not found!"); return nil end

        local obj3 = obj77:GetChildren()[3]
        if not obj3 then warn("getSpecificShopPrompt: workspace:GetChildren()[77]:GetChildren()[3] not found!"); return nil end

        local meshPad = obj3:FindFirstChild("Mesh/Pad")
        if not meshPad then warn("getSpecificShopPrompt: Mesh/Pad not found!"); return nil end

        local attachment = meshPad:FindFirstChild("Attachment")
        if not attachment then warn("getSpecificShopPrompt: Attachment not found!"); return nil end

        local prompt = attachment:FindFirstChildOfClass("ProximityPrompt")
        if not prompt then warn("getSpecificShopPrompt: ProximityPrompt not found!"); return nil end

        return prompt
    end

    local meatFarmLocation = Vector3.new(-1391.72, 16.75, -155.69) -- Position for "เนื้อ" farm

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
    --      Building Teleport
    -- ================================= --
    local BuildingSection = Tab:Section({
        Title = "เทเลพอร์ตอาคาร",
        Icon = "building",
        Opened = true
    })

    local buildingLocations = {
        { Name = "ร้านรับซื้อ", Pos = Vector3.new(638.69, 6.56, 171.37) },
        { Name = "ร้านขายอาหาร", Pos = Vector3.new(767.23, 6.74, 175.34) },
        { Name = "ร้านขายอุปกรณ์", Pos = Vector3.new(-303.57, 6.81, 1.26) }
    }

    local buildingNames = {}
    for _, loc in ipairs(buildingLocations) do
        table.insert(buildingNames, loc.Name)
    end

    local selectedBuilding = nil
    local buildingDropdown -- Forward declare

    buildingDropdown = BuildingSection:Dropdown({
        Title = "เลือกอาคาร",
        Desc = "เลือกตำแหน่งอาคารที่ต้องการเทเลพอร์ต",
        Values = buildingNames,
        SearchBarEnabled = true,
        Callback = function(buildingName)
            for _, loc in ipairs(buildingLocations) do
                if loc.Name == buildingName then
                    selectedBuilding = loc
                    break
                end
            end
            buildingDropdown:Close()
        end
    })

    BuildingSection:Button({
        Title = "เทเลพอร์ต",
        Icon = "send",
        Callback = function()
            if selectedBuilding and TeleportService then
                TeleportService:moveTo(selectedBuilding.Pos)
                WindUI:Notify({ Title = "สำเร็จ", Content = "กำลังเคลื่อนที่ไปยัง " .. selectedBuilding.Name, Icon = "check" })
            elseif not selectedBuilding then
                WindUI:Notify({ Title = "ข้อผิดพลาด", Content = "กรุณาเลือกอาคารก่อน", Icon = "x" })
            end
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

    Tab:Divider()

    -- ================================= --
    --      Auto-Farm
    -- ================================= --
    local AutoFarmMeatSection = Tab:Section({
        Title = "ออโต้ฟาร์ม",
        Icon = "cow",
        Opened = true
    })

    local isAutoFarming = false
    local autoFarmLoop = nil

    local autoFarmStatusParagraph = AutoFarmMeatSection:Paragraph({
        Title = "สถานะ",
        Desc = "สถานะ: หยุดทำงาน"
    })

    local function findNearestCow()
        local nearestCow = nil
        local minDistance = math.huge
        local playerPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position

        if not playerPos then return nil end

        local cowContainer = workspace.Plants.Cow
        if not cowContainer then return nil end

        for _, child in pairs(cowContainer:GetChildren()) do
            if child:IsA("Model") and child:FindFirstChild("Cube") and child:FindFirstChild("Cube").LocalTransparencyModifier < 1 then -- Assuming cows are models with a 'Cube' part and are visible
                local cowPart = child:FindFirstChild("Cube")
                if cowPart then
                    local cowPos = cowPart.Position
                    local distance = (playerPos - cowPos).Magnitude
                    if distance < minDistance then
                        minDistance = distance
                        nearestCow = cowPart -- Return the 'Cube' part directly
                    end
                end
            end
        end
        return nearestCow
    end

    local function moveToTarget(targetPart)
        if not TeleportService or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local playerRoot = LocalPlayer.Character.HumanoidRootPart
        local targetPos = targetPart.Position

        -- Calculate a position slightly in front of the target
        local direction = (playerRoot.Position - targetPos).Unit
        local offsetDistance = 3 -- Distance from the target to stand
        local destination = targetPos + (direction * offsetDistance)
        destination = Vector3.new(destination.X, targetPos.Y, destination.Z) -- Keep player at target's Y level

        TeleportService:moveTo(destination)
    end

    local function teleportToCowInstant(targetPart)
        if not TeleportService or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local playerRoot = LocalPlayer.Character.HumanoidRootPart
        local targetPos = targetPart.Position

        -- Calculate a position slightly in front of the target
        local direction = (playerRoot.Position - targetPos).Unit
        local offsetDistance = 3 -- Distance from the target to stand
        local destination = targetPos + (direction * offsetDistance)
        destination = Vector3.new(destination.X, targetPos.Y, destination.Z) -- Keep player at target's Y level

        TeleportService:_instant(destination) -- Use _instant for forced instant teleport
    end

    local SELL_POINT_LOCATION = Vector3.new(373.72, 7.15, 184.99) -- Coordinates for "ร้านรับซื้อ"
    local CRAFTING_ACTIVATION_POINT = Vector3.new(-1442.04, 16.53, -88.63) -- Coordinates for Crafting Activation Point

    local function checkInventoryCapacity()
        local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui", 5)
        if not playerGui then warn("PlayerGui not found!"); return nil, nil end

        local menu = playerGui:FindFirstChild("Menu")
        if not menu then warn("Menu UI not found!"); return nil, nil end

        local backpackFrame = menu:FindFirstChild("BackpackFrame")
        if not backpackFrame then warn("BackpackFrame UI not found!"); return nil, nil end

        local top1 = backpackFrame:FindFirstChild("TOP1")
        if not top1 then warn("TOP1 UI not found!"); return nil, nil end

        local allItem = top1:FindFirstChild("AllItem")
        if not allItem then warn("AllItem UI not found!"); return nil, nil end

        if allItem:IsA("TextLabel") then
            local parts = allItem.Text:split("/")
            if #parts == 2 then
                local currentCapacity = tonumber(parts[1])
                local maxCapacity = tonumber(parts[2])
                if currentCapacity and maxCapacity then
                    return currentCapacity, maxCapacity
                else
                    warn("Failed to convert inventory capacity to numbers: " .. allItem.Text)
                            return nil, nil
                        end
                    
            else
                warn("Inventory Text format ain't X/Y: " .. allItem.Text)
                return nil, nil
            end
        else
            warn("AllItem ain't a TextLabel, fix your path!")
            return nil, nil
        end
    end

    local function startAutoFarm()
        isAutoFarming = true
        autoFarmStatusParagraph:SetDesc("สถานะ: กำลังเริ่มต้น...")
        WindUI:Notify({ Title = "ออโต้ฟาร์ม", Content = "เริ่มระบบออโต้ฟาร์ม", Icon = "play" })

        autoFarmLoop = task.spawn(function()
            -- Initial teleport to meatFarmLocation once at start
            autoFarmStatusParagraph:SetDesc("สถานะ: กำลังเทเลพอร์ตไปยังฟาร์ม...")
            TeleportService:moveTo(meatFarmLocation)
            task.wait(1) -- Wait for teleport to complete

            -- Find the first cow and teleport to it
            local firstCow = findNearestCow()
            if firstCow then
                autoFarmStatusParagraph:SetDesc("สถานะ: กำลังวาร์ปไปยังวัวตัวแรก...")
                moveToTarget(firstCow) -- Use moveToTarget to get to the cow's position
                task.wait(0.5) -- Wait for movement
            else
                autoFarmStatusParagraph:SetDesc("สถานะ: ไม่พบวัวตัวแรกในบริเวณฟาร์ม...")
                -- If no cow found, it will just start scanning from meatFarmLocation
            end

            while isAutoFarming do -- Continuous farming loop
                local nearestCow = findNearestCow()

                if nearestCow then
                    autoFarmStatusParagraph:SetDesc("สถานะ: กำลังเคลื่อนที่ไปยัง " .. nearestCow.Parent.Name .. "...")
                    moveToTarget(nearestCow)
                    task.wait(0.5) -- Wait for movement

                    autoFarmStatusParagraph:SetDesc("สถานะ: กำลังเก็บเกี่ยว " .. nearestCow.Parent.Name .. "...")
                    
                    local interactionAttempts = 0
                    local maxInteractionAttempts = 10
                    while nearestCow.LocalTransparencyModifier < 1 and interactionAttempts < maxInteractionAttempts do
                        if triggerProximityPromptTrial(nearestCow) then -- Use trial version prompt
                            autoFarmStatusParagraph:SetDesc("สถานะ: เก็บเกี่ยว " .. nearestCow.Parent.Name .. " (ครั้งที่ " .. (interactionAttempts + 1) .. ")")
                            task.wait(1) -- Fixed cooldown for trial
                        else
                            break
                        end
                        interactionAttempts = interactionAttempts + 1
                    end

                    -- Inventory check (keep this)
                    local currentCapacity, maxCapacity = checkInventoryCapacity()
                    if currentCapacity and maxCapacity and currentCapacity >= maxCapacity then
                        autoFarmStatusParagraph:SetDesc("ช่องเก็บของเต็ม! กำลังวาร์ปไปจุดเปิด Crafting...")
                        WindUI:Notify({ Title = "ออโต้ฟาร์ม", Content = "ช่องเก็บของเต็ม! กำลังวาร์ปไปจุดเปิด Crafting", Icon = "package" })
                        
                        task.wait(3) -- Wait for 3 seconds before teleporting

                        -- Store original Humanoid state
                        local playerHumanoid = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                        local originalPlatformStand = playerHumanoid and playerHumanoid.PlatformStand
                        local originalWalkSpeed = playerHumanoid and playerHumanoid.WalkSpeed
                        local originalJumpPower = playerHumanoid and playerHumanoid.JumpPower

                        -- Freeze player
                        if playerHumanoid then
                            playerHumanoid.PlatformStand = true
                            playerHumanoid.WalkSpeed = 0
                            playerHumanoid.JumpPower = 0
                        end

                        TeleportService:moveTo(CRAFTING_ACTIVATION_POINT)
                        task.wait(1) -- Wait for teleport to complete

                        autoFarmStatusParagraph:SetDesc("กำลังพยายามเปิด UI Crafting...")
                        local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui", 5)
                        local craftingUI = playerGui and playerGui:FindFirstChild("Menu") and playerGui:FindFirstChild("Menu"):FindFirstChild("Crafting")

                        local craftingPromptPart = workspace.KraftPowerStrength.Meat["Mesh/Pad"]
                        local activationAttempts = 0
                        local maxActivationAttempts = 20 -- Max attempts to open crafting UI

                        if craftingPromptPart and craftingUI then
                            while not craftingUI.Visible and activationAttempts < maxActivationAttempts do
                                if triggerProximityPromptTrial(craftingPromptPart) then
                                    autoFarmStatusParagraph:SetDesc("สถานะ: พยายามเปิด UI Crafting (ครั้งที่ " .. (activationAttempts + 1) .. ")")
                                    task.wait(0.5) -- Short wait between attempts
                                else
                                    autoFarmStatusParagraph:SetDesc("สถานะ: ไม่พบ Prompt เปิด Crafting หรือ Prompt ไม่ทำงาน")
                                    break -- Break if prompt interaction fails
                                end
                                activationAttempts = activationAttempts + 1
                            end

                            if craftingUI.Visible then
                                autoFarmStatusParagraph:SetDesc("UI Crafting เปิดแล้ว! หยุดระบบออโต้ฟาร์ม")
                                WindUI:Notify({ Title = "ออโต้ฟาร์ม", Content = "UI Crafting เปิดแล้ว! หยุดระบบออโต้ฟาร์ม", Icon = "package-x" })
                            else
                                autoFarmStatusParagraph:SetDesc("ไม่สามารถเปิด UI Crafting ได้! หยุดระบบออโต้ฟาร์ม")
                                WindUI:Notify({ Title = "ออโต้ฟาร์ม", Content = "ไม่สามารถเปิด UI Crafting ได้! หยุดระบบออโต้ฟาร์ม", Icon = "package-x" })
                            end
                        else
                            autoFarmStatusParagraph:SetDesc("ไม่พบส่วนประกอบ UI Crafting หรือ Prompt! หยุดระบบออโต้ฟาร์ม")
                            WindUI:Notify({ Title = "ออโต้ฟาร์ม", Content = "ไม่พบส่วนประกอบ UI Crafting หรือ Prompt! หยุดระบบออโต้ฟาร์ม", Icon = "package-x" })
                        end
                        
                        -- Restore original Humanoid state
                        if playerHumanoid then
                            playerHumanoid.PlatformStand = originalPlatformStand
                            playerHumanoid.WalkSpeed = originalWalkSpeed
                            playerHumanoid.JumpPower = originalJumpPower
                        end

                        stopAutoFarm() -- Stop the auto-farm regardless of success
                        return -- Exit the task.spawn function
                    end

                    -- If cow disappeared, it's done. If not, it means interaction failed or max attempts reached.
                    -- In trial, we don't track farmed cows, so it will be re-targeted if it reappears.
                    -- Just wait for cooldown before next findNearestCow()
                    task.wait(1) -- Fixed cooldown for trial before finding next cow

                else
                    -- No cow found, wait briefly and try again
                    autoFarmStatusParagraph:SetDesc("สถานะ: ไม่พบวัวที่เก็บเกี่ยวได้ในบริเวณ กำลังค้นหา...")
                    task.wait(1) -- Wait before re-scanning
                end
            end
        end)
    end

    local function stopAutoFarm()
        isAutoFarming = false
        if autoFarmLoop then
            task.cancel(autoFarmLoop)
            autoFarmLoop = nil
        end
        autoFarmStatusParagraph:SetDesc("สถานะ: หยุดทำงาน")
        WindUI:Notify({ Title = "ออโต้ฟาร์ม", Content = "หยุดระบบออโต้ฟาร์ม", Icon = "stop" })
    end

    AutoFarmMeatSection:Toggle({
        Title = "เปิด/ปิด ออโต้ฟาร์ม",
        Desc = "เปิด/ปิดระบบฟาร์มวัวอัตโนมัติ (เก็บเกี่ยวทันที, Cooldown 1 วินาที)",
        Value = false,
        Callback = function(value)
            if value then
                startAutoFarm()
            else
                stopAutoFarm()
            end
        end
    })

    Tab:Divider()

    local ShopManagementSection = Tab:Section({
        Title = "การจัดการร้านค้า",
        Icon = "store", -- A suitable icon
        Opened = true
    })

    ShopManagementSection:Toggle({
        Title = "เปิด/ปิดร้านค้า",
        Desc = "บังคับเปิดหรือปิด ProximityPrompt ของร้านค้า",
        Value = false, -- Default to off
        Callback = function(value)
            local shopPrompt = getSpecificShopPrompt()
            if shopPrompt then
                shopPrompt.Enabled = value
                WindUI:Notify({ Title = "การจัดการร้านค้า", Content = "Prompt ร้านค้าถูกตั้งค่าเป็น: " .. tostring(value), Icon = "check" })
            else
                WindUI:Notify({ Title = "การจัดการร้านค้า", Content = "ไม่พบ Prompt ร้านค้าตาม Path ที่ระบุ!", Icon = "x" })
            end
        end
    })
end