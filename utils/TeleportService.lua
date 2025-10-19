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

    local originalSpeed = humanoid.WalkSpeed
    humanoid.WalkSpeed = 120 -- Set high speed

    -- Use a task.spawn to prevent the UI from freezing during pathfinding
    task.spawn(function()
        local path = PathfindingService:CreatePath()
        local success, err = pcall(function()
            path:ComputeAsync(rootPart.Position, destination)
        end)

        if not success or path.Status ~= Enum.PathStatus.Success then
            -- Path computation failed, fallback to a safer method
            humanoid.WalkSpeed = originalSpeed
            self:_phased(destination)
            return
        end

        local waypoints = path:GetWaypoints()
        local currentWaypointIndex = 1

        -- Path:Blocked event to trigger re-pathing
        local blockedConnection
        blockedConnection = path.Blocked:Connect(function(blockedWaypointIndex)
            -- If the path is blocked ahead of us, re-calculate
            if blockedWaypointIndex >= currentWaypointIndex then
                blockedConnection:Disconnect()
                self:_pathfind(destination) -- Recursively call to re-path
            end
        end)

        while currentWaypointIndex <= #waypoints do
            local waypoint = waypoints[currentWaypointIndex]
            humanoid:MoveTo(waypoint.Position)
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end

            local timeWaited = 0
            local lastPosition = rootPart.Position
            
            -- Loop to check progress towards the waypoint
            while true do
                task.wait(0.2)
                timeWaited = timeWaited + 0.2

                local distanceToWaypoint = (rootPart.Position - waypoint.Position).Magnitude
                
                -- 1. Proximity Check: If we are close enough, move to next waypoint
                if distanceToWaypoint < 6 then
                    break 
                end

                -- 2. Stuck Detection: If we haven't moved for a while, re-path
                if (rootPart.Position - lastPosition).Magnitude < 1 then
                    if timeWaited > 2 then -- Stuck for 2 seconds
                        blockedConnection:Disconnect()
                        self:_pathfind(destination) -- Re-path from current position
                        return -- Exit this failed attempt
                    end
                else
                    -- We moved, so reset the stuck timer and update position
                    timeWaited = 0
                    lastPosition = rootPart.Position
                end

                -- 3. General Timeout: If it takes too long to reach a waypoint, re-path
                if timeWaited > 5 then
                    blockedConnection:Disconnect()
                    self:_pathfind(destination) -- Re-path from current position
                    return -- Exit this failed attempt
                end
            end
            
            currentWaypointIndex = currentWaypointIndex + 1
        end

        blockedConnection:Disconnect()
        humanoid.WalkSpeed = originalSpeed
    end)
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
