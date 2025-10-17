return function(Tab, Window, WindUI)
    local RunService = game:GetService("RunService")
    local LocalPlayer = game:GetService("Players").LocalPlayer

    local positionParagraph = Tab:Paragraph({
        Title = "พิกัด",
        Desc = "X: 0, Y: 0, Z: 0"
    })

    RunService.RenderStepped:Connect(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local pos = LocalPlayer.Character.HumanoidRootPart.Position
            positionParagraph:SetDesc(string.format("X: %.2f, Y: %.2f, Z: %.2f", pos.X, pos.Y, pos.Z))
        end
    end)
end