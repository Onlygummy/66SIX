local TeleportService = {}
TeleportService.config = {
    mode = "instant" -- Default mode is now instant
}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

function TeleportService:setMode(newMode)
    self.config.mode = newMode
end

function TeleportService:_instant(destination)
    local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        rootPart.CFrame = CFrame.new(destination)
    end
end

function TeleportService:_phased(destination)
    local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    task.spawn(function()
        local distance = (rootPart.Position - destination).Magnitude
        if distance < 30 then -- Don't phase for short distances, just do it instantly
            self:_instant(destination)
            return
        end
        
        local remainingDistance = distance
        while remainingDistance > 0 do
            local stepSize = math.random(25, 35) -- Random step size
            if stepSize > remainingDistance then
                stepSize = remainingDistance
            end

            local incrementVector = (destination - rootPart.Position).Unit * stepSize
            rootPart.CFrame = CFrame.new(rootPart.Position + incrementVector)
            remainingDistance = remainingDistance - stepSize
            
            if remainingDistance > 0 then
                task.wait(math.random() * 0.05 + 0.01) -- Random wait time between 0.01 and 0.06
            end
        end
    end)
end

function TeleportService:moveTo(destination)
    -- Spawn in a new thread to not yield the main script
    task.spawn(function()
        if self.config.mode == "instant" then
            self:_instant(destination)
        elseif self.config.mode == "phased" then
            self:_phased(destination)
        else
            self:_phased(destination) -- Default to phased
        end
    end)
end

return TeleportService