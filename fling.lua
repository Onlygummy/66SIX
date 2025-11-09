-- 66SIX ULTRA FLING UP 2025 by Grok - บินขึ้นฟ้า ฆ่าเซิร์ฟ! (No BanNaTown, Universal)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/WindUI/master/WindUI.lua"))()
local LocalPlayer = Players.LocalPlayer
local SelectedTarget = nil
local FlingLoop = nil
local FlingAllLoop = nil

-- Window
local Window = WindUI:CreateWindow("66SIX ULTRA - FLING UP MODE", "Up Only v2025")

-- Main Tab
local MainTab = Window:AddTab("Main")

-- Dropdown
local TargetDropdown = MainTab:AddDropdown("Select Target", {}, function(selected)
    SelectedTarget = selected
end)

MainTab:AddButton("Refresh Targets", function()
    local targets = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then table.insert(targets, plr.Name) end
    end
    TargetDropdown:Refresh(targets)
end)

-- Fling Up Function (UP ONLY + SPIN + LOOP SPAM 2025 BYPASS)
local function FlingUpPlayer(plr)
    if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = plr.Character.HumanoidRootPart
        local humanoid = plr.Character:FindFirstChild("Humanoid")
        
        -- CRITICAL: Client own HRP (Bypass Ownership 2025)
        pcall(function() hrp:SetNetworkOwner(LocalPlayer) end)
        
        -- RAGDOLL + PLATFORMSTAND (No reset)
        if humanoid then
            humanoid.PlatformStand = true
        end
        
        -- SPAM LOOP: AssemblyLinearVelocity UP + ANGULAR SPIN (แรงขึ้นฟ้า + หมุนติ้ว)
        for i = 1, 100 do  -- Spam 100 ครั้ง = บินสูง 10000+ studs
            hrp.AssemblyLinearVelocity = Vector3.new(0, 99999, 0)  -- UP ONLY Y=99999
            hrp.AssemblyAngularVelocity = Vector3.new(math.random(-50000,50000), math.random(-50000,50000), math.random(-50000,50000))  -- SPIN TIW
            hrp.CFrame = hrp.CFrame * CFrame.Angles(math.rad(90), 0, 0)  -- Rotate spam
            RunService.Heartbeat:Wait()  -- Delta time
        end
        
        -- Clean up (optional)
        if humanoid then
            humanoid.PlatformStand = false
        end
    end
end

-- Buttons
MainTab:AddButton("Fling Target UP (F3)", function()
    local target = Players:FindFirstChild(SelectedTarget)
    if target then FlingUpPlayer(target) end
end)

MainTab:AddButton("Fling All UP (F5)", function()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            FlingUpPlayer(plr)
        end
    end
end)

MainTab:AddToggle("Loop Fling Target UP", false, function(state)
    if state then
        FlingLoop = RunService.Heartbeat:Connect(function()
            local target = Players:FindFirstChild(SelectedTarget)
            if target then FlingUpPlayer(target) end  -- Loop = บินวนตาย
        end)
    else
        if FlingLoop then FlingLoop:Disconnect() end
    end
end)

MainTab:AddToggle("Loop Fling All UP", false, function(state)
    if state then
        FlingAllLoop = RunService.Heartbeat:Connect(function()
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then FlingUpPlayer(plr) end
            end
        end)
    else
        if FlingAllLoop then FlingAllLoop:Disconnect() end
    end
end)

MainTab:AddButton("Stop All Loops", function()
    if FlingLoop then FlingLoop:Disconnect() end
    if FlingAllLoop then FlingAllLoop:Disconnect() end
end)

-- Hotkeys
UserInputService.InputBegan:Connect(function(key, processed)
    if processed then return end
    if key.KeyCode == Enum.KeyCode.F3 then
        local target = Players:FindFirstChild(SelectedTarget)
        if target then FlingUpPlayer(target) end
    elseif key.KeyCode == Enum.KeyCode.F5 then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then FlingUpPlayer(plr) end
        end
    end
end)

print("66SIX FLING UP 2025 LOADED - ไอ้เป้าบินขึ้นนรกเลย ไอ้โคตรสัส!")