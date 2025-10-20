--[[--
    LiteUI.lua
    A new, custom, lightweight UI library built from scratch for the 66SIX project.
    Goal: Minimal code, easy to understand, and contains only necessary components.
--]]--

local LiteUI = {}

-- =================================================================== --
-- Part 1: Configuration
-- =================================================================== --
LiteUI.Config = {
    Font = "rbxassetid://12187365364",
    Colors = {
        Background = Color3.fromHex("#1c1c1c"),
        Header = Color3.fromHex("#212121"),
        Section = Color3.fromHex("#212121"),
        Button = Color3.fromHex("#2c2c2c"),
        Outline = Color3.fromHex("#414141"),
        Accent = Color3.fromHex("#313131"),
        Text = Color3.fromHex("#ffffff"),
        MutedText = Color3.fromRGB(180, 180, 180),
        Placeholder = Color3.fromRGB(142, 142, 142),
    },
    Sizes = {
        HeaderHeight = 64,
        TabButtonsHeight = 58,
        WindowPadding = 20,
        SectionPadding = 15,
        ComponentPadding = 12,
    },
    Assets = {
        Squircle = "rbxassetid://80999662900595",
        ToggleTrack = "rbxassetid://3926305904", -- A sliced image for the track
        ToggleKnob = "rbxassetid://3926305904", -- A sliced image for the knob
    }
}

-- =================================================================== --
-- Part 2: Core Helper Functions
-- =================================================================== --
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local function Create(instanceType, properties)
    local inst = Instance.new(instanceType)
    for k, v in pairs(properties) do
        inst[k] = v
    end
    return inst
end

local function MakeDraggable(guiObject, dragHandle)
    local dragging = false
    local dragStart, startPos

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            if not dragStart then return end
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- =================================================================== --
-- Part 3: Main UI Creation Functions
-- =================================================================== --

function LiteUI:CreateWindow(props)
    local Cfg = LiteUI.Config
    local screenGui = Create("ScreenGui", { Name = "LiteUI_ScreenGui", DisplayOrder = 999, ResetOnSpawn = false })
    local mainFrame = Create("Frame", {
        Name = "MainFrame", Size = props.Size or UDim2.new(0, 580, 0, 460), Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Cfg.Colors.Background, BorderSizePixel = 0, Parent = screenGui,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 26), Parent = mainFrame })

    local header = Create("Frame", {
        Name = "Header", Size = UDim2.new(1, 0, 0, Cfg.Sizes.HeaderHeight), BackgroundColor3 = Cfg.Colors.Header,
        BorderSizePixel = 0, Parent = mainFrame, BackgroundTransparency = 0
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 26), Parent = header })
    Create("UIStroke", { Thickness = 1, Color = Cfg.Colors.Outline, ApplyStrokeMode = "Border", Parent = header })

    Create("TextLabel", {
        Name = "Title", Size = UDim2.new(1, -Cfg.Sizes.WindowPadding * 2, 1, 0), Position = UDim2.new(0, Cfg.Sizes.WindowPadding, 0, 0),
        BackgroundTransparency = 1, Text = props.Title or "LiteUI", TextColor3 = Cfg.Colors.Text,
        FontFace = Font.new(Cfg.Font, Enum.FontWeight.SemiBold), TextSize = 20, TextXAlignment = "Left", Parent = header
    })

    local tabButtonsFrame = Create("Frame", {
        Name = "TabButtonsFrame", Size = UDim2.new(1, 0, 0, Cfg.Sizes.TabButtonsHeight), Position = UDim2.new(0, 0, 0, Cfg.Sizes.HeaderHeight),
        BackgroundTransparency = 1, Parent = mainFrame
    })
    Create("UIPadding", { PaddingLeft = UDim.new(0, Cfg.Sizes.WindowPadding), Parent = tabButtonsFrame })
    Create("UIListLayout", { FillDirection = "Horizontal", VerticalAlignment = "Center", Padding = UDim.new(0, 12), Parent = tabButtonsFrame })

    local contentFrame = Create("Frame", {
        Name = "ContentFrame", Size = UDim2.new(1, 0, 1, -(Cfg.Sizes.HeaderHeight + Cfg.Sizes.TabButtonsHeight)),
        Position = UDim2.new(0, 0, 0, Cfg.Sizes.HeaderHeight + Cfg.Sizes.TabButtonsHeight), BackgroundTransparency = 1, Parent = mainFrame
    })

    MakeDraggable(mainFrame, header)

    local toggleKey = props.ToggleKey or Enum.KeyCode.RightControl
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == toggleKey then mainFrame.Visible = not mainFrame.Visible end
    end)

    local Window = { _screenGui = screenGui, _mainFrame = mainFrame, _tabs = {}, _currentTab = nil }

    function Window:Tab(tabProps)
        local tabContainer = Create("ScrollingFrame", {
            Name = tabProps.Title or "Tab", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ScrollingDirection = "Y",
            CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 4, ScrollBarImageColor3 = Cfg.Colors.Accent, Visible = false, Parent = contentFrame
        })
        Create("UIPadding", { PaddingLeft = UDim.new(0, Cfg.Sizes.WindowPadding), PaddingRight = UDim.new(0, Cfg.Sizes.WindowPadding), PaddingTop = UDim.new(0, 10), Parent = tabContainer })
        local tabLayout = Create("UIListLayout", { Padding = UDim.new(0, Cfg.Sizes.ComponentPadding), SortOrder = "LayoutOrder", Parent = tabContainer })
        tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() tabContainer.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 10) end)

        local tabButton = Create("TextButton", { Name = "TabButton_" .. tabProps.Title, AutomaticSize = "X", Size = UDim2.new(0, 0, 1, 0), Text = "", BackgroundTransparency = 1, Parent = tabButtonsFrame })
        local buttonText = Create("TextLabel", { Text = tabProps.Title or "Tab", TextSize = 17, FontFace = Font.new(Cfg.Font, Enum.FontWeight.Medium), TextColor3 = Cfg.Colors.MutedText, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = tabButton })
        local indicator = Create("Frame", { Name = "Indicator", Position = UDim2.new(0.5, 0, 1, 0), AnchorPoint = Vector2.new(0.5, 1), Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Cfg.Colors.Text, BorderSizePixel = 0, Visible = false, Parent = tabButton })

        local tabInfo = { Button = tabButton, Container = tabContainer, Text = buttonText, Indicator = indicator }
        table.insert(Window._tabs, tabInfo)

        local Tab = { _container = tabContainer }

        function Tab:Select()
            if Window._currentTab then
                Window._currentTab.Container.Visible = false
                Window._currentTab.Indicator.Visible = false
                TweenService:Create(Window._currentTab.Text, TweenInfo.new(0.2), { TextColor3 = Cfg.Colors.MutedText }):Play()
            end
            tabContainer.Visible = true
            indicator.Visible = true
            TweenService:Create(buttonText, TweenInfo.new(0.2), { TextColor3 = Cfg.Colors.Text }):Play()
            Window._currentTab = tabInfo
        end
        tabButton.MouseButton1Click:Connect(function() Tab:Select() end)

        function Tab:Section(secProps)
            local sectionFrame = Create("Frame", { Name = secProps.Title or "Section", AutomaticSize = "Y", Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Cfg.Colors.Section, Parent = tabContainer })
            Create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = sectionFrame })
            Create("UIStroke", { Thickness = 1, Color = Cfg.Colors.Outline, Parent = sectionFrame })
            Create("UIPadding", { All = UDim.new(0, Cfg.Sizes.SectionPadding), Parent = sectionFrame })
            Create("UIListLayout", { Padding = UDim.new(0, Cfg.Sizes.ComponentPadding), Parent = sectionFrame })
            
            local Section = {}
            local function AddComponent(inst) inst.Parent = sectionFrame; return inst end

            function Section:Button(btnProps)
                local btn = Create("TextButton", { Name = btnProps.Title, Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = Cfg.Colors.Button, Text = "" })
                Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = btn })
                Create("TextLabel", { Text = btnProps.Title, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), TextColor3 = Cfg.Colors.Text, FontFace = Font.new(Cfg.Font, Enum.FontWeight.SemiBold), TextSize = 16, Parent = btn })
                if btnProps.Callback then btn.MouseButton1Click:Connect(btnProps.Callback) end
                return AddComponent(btn)
            end

            function Section:Paragraph(pProps)
                local pFrame = Create("Frame", { AutomaticSize = "Y", Size = UDim2.new(1,0,0,0), BackgroundTransparency = 1 })
                local pLayout = Create("UIListLayout", { Padding = UDim.new(0, 2), Parent = pFrame })
                Create("TextLabel", { Name = "Title", Text = pProps.Title or "", TextSize = 16, FontFace = Font.new(Cfg.Font, Enum.FontWeight.Medium), TextColor3 = Cfg.Colors.Text, BackgroundTransparency = 1, TextXAlignment = "Left", AutomaticSize = "Y", Size = UDim2.new(1,0,0,0), Parent = pFrame })
                local pDesc = Create("TextLabel", { Name = "Desc", Text = pProps.Desc or "", TextSize = 14, FontFace = Font.new(Cfg.Font, Enum.FontWeight.Regular), TextColor3 = Cfg.Colors.MutedText, BackgroundTransparency = 1, TextXAlignment = "Left", AutomaticSize = "Y", Size = UDim2.new(1,0,0,0), RichText = true, TextWrapped = true, Parent = pFrame })
                function pFrame:SetDesc(text) pDesc.Text = text end
                return AddComponent(pFrame)
            end

            function Section:Toggle(tProps)
                local value = tProps.Value or false
                local tFrame = Create("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1 })
                Create("TextLabel", { Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Text = tProps.Title or "", TextSize = 16, FontFace = Font.new(Cfg.Font, Enum.FontWeight.Medium), TextColor3 = Cfg.Colors.Text, BackgroundTransparency = 1, Parent = tFrame })
                local switch = Create("ImageButton", { Size = UDim2.new(0, 44, 0, 24), Position = UDim2.new(1, 0, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Image = Cfg.Assets.ToggleTrack, SliceCenter = Rect.new(100, 100, 100, 100), ScaleType = "Slice", BackgroundColor3 = Cfg.Colors.Accent, ImageColor3 = Cfg.Colors.Accent, Parent = tFrame })
                local knob = Create("ImageLabel", { Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(0, 2, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Image = Cfg.Assets.ToggleKnob, SliceCenter = Rect.new(100, 100, 100, 100), ScaleType = "Slice", ImageColor3 = Cfg.Colors.MutedText, Parent = switch })
                local function updateVisuals(v)
                    local knobPos = v and UDim2.new(1, -2, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
                    local knobAnchor = v and Vector2.new(1, 0.5) or Vector2.new(0, 0.5)
                    local knobColor = v and Cfg.Colors.Text or Cfg.Colors.MutedText
                    TweenService:Create(knob, TweenInfo.new(0.2), { Position = knobPos, AnchorPoint = knobAnchor, ImageColor3 = knobColor }):Play()
                end
                updateVisuals(value)
                function tFrame:SetValue(v) value = v; updateVisuals(v) end
                switch.MouseButton1Click:Connect(function() value = not value; updateVisuals(value); if tProps.Callback then tProps.Callback(value) end end)
                return AddComponent(tFrame)
            end

            function Section:Divider() return AddComponent(Create("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Cfg.Colors.Outline })) end
            
            function Section:Slider(sProps)
                local sFrame = Create("Frame", { AutomaticSize = "Y", Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 })
                local titleFrame = Create("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Parent = sFrame })
                Create("TextLabel", { Name = "Title", Text = sProps.Title or "", TextSize = 16, FontFace = Font.new(Cfg.Font, Enum.FontWeight.Medium), TextColor3 = Cfg.Colors.Text, BackgroundTransparency = 1, TextXAlignment = "Left", Position = UDim2.new(0,0,0.5,0), AnchorPoint = Vector2.new(0, 0.5), Parent = titleFrame })
                local valueLabel = Create("TextLabel", { Name = "ValueLabel", Text = tostring(sProps.Value.Default or 50), TextSize = 16, FontFace = Font.new(Cfg.Font, Enum.FontWeight.Medium), TextColor3 = Cfg.Colors.MutedText, BackgroundTransparency = 1, TextXAlignment = "Right", Position = UDim2.new(1,0,0.5,0), AnchorPoint = Vector2.new(1, 0.5), Parent = titleFrame })
                
                local sliderFrame = Create("Frame", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Position = UDim2.new(0,0,0,20), Parent = sFrame })
                Create("Frame", { Name = "Back", Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0.5,0,0.5,0), AnchorPoint = Vector2.new(0.5,0.5), BackgroundColor3 = Cfg.Colors.Accent, Parent = sliderFrame }, { Create("UICorner", { CornerRadius = UDim.new(0, 3) }) })
                local fill = Create("Frame", { Name = "Fill", Size = UDim2.new(0, 0, 0, 6), Position = UDim2.new(0,0,0.5,0), AnchorPoint = Vector2.new(0,0.5), BackgroundColor3 = Cfg.Colors.Text, Parent = sliderFrame }, { Create("UICorner", { CornerRadius = UDim.new(0, 3) }) })
                local dragger = Create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = sliderFrame })

                local value, min, max, step = sProps.Value.Default or 50, sProps.Value.Min or 0, sProps.Value.Max or 100, sProps.Value.Step or 1
                local function updateValue(inputPos)
                    local relativeX = inputPos.X - sliderFrame.AbsolutePosition.X
                    local percentage = math.clamp(relativeX / sliderFrame.AbsoluteSize.X, 0, 1)
                    local rawValue = min + (max - min) * percentage
                    value = math.floor(rawValue / step + 0.5) * step
                    fill.Size = UDim2.new(percentage, 0, 0, 6)
                    valueLabel.Text = tostring(value)
                    if sProps.Callback then sProps.Callback(value) end
                end
                fill.Size = UDim2.new((value - min) / (max - min), 0, 0, 6) -- Set initial size
                
                local dragging = false
                dragger.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; updateValue(input.Position) end end)
                dragger.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
                UserInputService.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then updateValue(input.Position) end end)
                return AddComponent(sFrame)
            end

            return Section
        end
        -- Convenience wrappers
        function Tab:Paragraph(p) return self:Section():Paragraph(p) end
        function Tab:Button(p) return self:Section():Button(p) end
        function Tab:Toggle(p) return self:Section():Toggle(p) end
        function Tab:Slider(p) return self:Section():Slider(p) end
        function Tab:Divider() return self:Section():Divider() end
        
        return Tab
    end

    function Window:Destroy() screenGui:Destroy() end

    if #Window._tabs > 0 then Window._tabs[1]:Select() end
    screenGui.Parent = game:GetService("CoreGui")
    return Window
end

return LiteUI
