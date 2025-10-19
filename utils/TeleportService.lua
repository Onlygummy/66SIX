local TeleportService = {}
TeleportService.config = {
    mode = "pathfind" -- Default mode
}

local PathfindingService = game:GetService("PathfindingService")
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

    local distance = (rootPart.Position - destination).Magnitude
    if distance < 25 then -- Don't phase for short distances
        self:_instant(destination)
        return
    end
    
    local incrementVector = (destination - rootPart.Position).Unit * 25 -- Step of 25 studs
    local steps = math.floor(distance / 25)

    for i = 1, steps do
        rootPart.CFrame = CFrame.new(rootPart.Position + incrementVector)
        task.wait() -- Wait for next frame
    end
    rootPart.CFrame = CFrame.new(destination) -- Final step to ensure accuracy
end

function TeleportService:_pathfind(destination)
    local char = LocalPlayer.Character
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not rootPart or not humanoid then return end

    local path = PathfindingService:CreatePath()
    local success, err = pcall(function()
        path:ComputeAsync(rootPart.Position, destination)
    end)

    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        local originalSpeed = humanoid.WalkSpeed
        humanoid.WalkSpeed = 120 -- High speed
        for _, waypoint in ipairs(waypoints) do
            humanoid:MoveTo(waypoint.Position)
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end
            humanoid.MoveToFinished:Wait(2) -- Add a timeout
        end
        humanoid.WalkSpeed = originalSpeed
    else
        -- Fallback to a safer method if path fails
        self:_phased(destination)
    end
end

function TeleportService:moveTo(destination)
    if self.config.mode == "instant" then
        self:_instant(destination)
    elseif self.config.mode == "phased" then
        self:_phased(destination)
    elseif self.config.mode == "pathfind" then
        self:_pathfind(destination)
    else
        self:_pathfind(destination) -- Default to safest
    end
end

return TeleportService
