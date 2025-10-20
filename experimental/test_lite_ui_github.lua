--[[--
    File: test_lite_ui_github.lua
    Description: A realistic test script that loads the new LiteUI.lua from GitHub
    and then builds a comprehensive UI to test all of its components.
--]]--

-- =================================================================== --
-- Part 1: Load LiteUI from GitHub
-- IMPORTANT: This URL must point to the raw LiteUI.lua file on your GitHub repo.
-- Using the 'develop' branch for now. This might change to 'main' later.
-- =================================================================== --

local GITHUB_USER = "Onlygummy"
local GITHUB_REPO = "66SIX"
local GITHUB_BRANCH = "develop" -- Or "main" when ready

local LITE_UI_URL = string.format("https://raw.githubusercontent.com/%s/%s/%s/experimental/LiteUI.lua", GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH)

local LiteUI, success, err = pcall(function() 
    return loadstring(game:HttpGet(LITE_UI_URL))()
end)

if not success or not LiteUI then
    warn("LiteUI failed to load!", err)
    return
end

print("LiteUI loaded successfully!")

-- =================================================================== --
-- Part 2: Build a comprehensive test UI
-- =================================================================== --

-- Create the main window
local Window = LiteUI:CreateWindow({
    Title = "LiteUI Test Suite",
    Size = UDim2.new(0, 580, 0, 460),
    ToggleKey = Enum.KeyCode.RightControl
})

-- === Components Tab ===
local ComponentsTab = Window:Tab({ Title = "Components" })

local basicSection = ComponentsTab:Section({ Title = "Basic Components" })

basicSection:Paragraph({
    Title = "Paragraph Component",
    Desc = "This is a description for the paragraph component."
})

basicSection:Button({
    Title = "Test Button",
    Callback = function()
        print("Test Button clicked!")
    end
})

basicSection:Toggle({
    Title = "Test Toggle",
    Value = false,
    Callback = function(value)
        print("Toggle state is now: " .. tostring(value))
    end
})

basicSection:Divider()

local options = {"Option 1", "Option B", "Third Choice"}
basicSection:Dropdown({
    Title = "Test Dropdown",
    Values = options,
    Callback = function(value)
        print("Dropdown selected: " .. value)
    end
})

local sliderSection = ComponentsTab:Section({ Title = "Slider Component" })

sliderSection:Slider({
    Title = "Test Slider",
    Value = {
        Default = 50, Min = 0, Max = 100, Step = 5
    },
    Callback = function(value)
        print("Slider value: " .. tostring(value))
    end
})

-- === Notifications Tab ===
local NotifyTab = Window:Tab({ Title = "Notifications" })

local notifySection = NotifyTab:Section({ Title = "Test Notifications" })

notifySection:Button({
    Title = "Show Notification",
    Callback = function()
        print("Showing notification...")
        LiteUI:Notify({
            Title = "LiteUI Notification",
            Content = "This is a test notification.",
            Duration = 5
        })
    end
})

-- Select the first tab by default
ComponentsTab:Select()

print("LiteUI Test Suite created.")
