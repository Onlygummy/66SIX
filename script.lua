--[[
    ไฟล์นี้เป็นไฟล์หลัก (Main Entry Point)
    ทำหน้าที่โหลด Library และ Module ต่างๆ ที่จำเป็น
]]

-- =================================================================== --
--      สำคัญ: แก้ไข URL ด้านล่างนี้เป็น URL ไฟล์ Raw จาก GitHub ของคุณ
-- =================================================================== --

-- =================================================================== --
--      ตั้งค่าโปรเจกต์ (แก้ไขแค่ตรงนี้)
-- =================================================================== --
local GITHUB_USER = "Onlygummy"
local GITHUB_REPO = "66SIX"
local GITHUB_BRANCH = "develop" -- <-- เปลี่ยน branch ที่นี่ (เช่น "main" หรือ "develop")
-- =================================================================== --

-- ตัวแปรป้องกัน Cache และสร้าง Base URL
local cacheBuster = os.time()
local baseURL = string.format("https://raw.githubusercontent.com/%s/%s/%s/", GITHUB_USER, GITHUB_REPO, GITHUB_BRANCH)

-- URL สำหรับโหลดไฟล์ต่างๆ
local WindUI_URL = baseURL .. "windui.lua?v=" .. cacheBuster
local TeleportService_URL = baseURL .. "utils/TeleportService.lua?v=" .. cacheBuster
local MainTab_URL = baseURL .. "tabs/main_tab.lua?v=" .. cacheBuster
local SettingsTab_URL = baseURL .. "tabs/settings_tab.lua?v=" .. cacheBuster
local PositionTab_URL = baseURL .. "tabs/info_tab.lua?v=" .. cacheBuster
local CharacterTab_URL = baseURL .. "tabs/character_tab.lua?v=" .. cacheBuster

-- โหลดไลบรารีและโมดูลหลัก
local WindUI = loadstring(game:HttpGet(WindUI_URL))()
local TeleportService = loadstring(game:HttpGet(TeleportService_URL))()
local MainTabModule = loadstring(game:HttpGet(MainTab_URL))()
local InfoTabModule = loadstring(game:HttpGet(PositionTab_URL))()
local SettingsTabModule = loadstring(game:HttpGet(SettingsTab_URL))()
local CharacterTabModule = loadstring(game:HttpGet(CharacterTab_URL))()


-- สร้างหน้าต่างหลัก (Window)
local Window = WindUI:CreateWindow({
    Title = "66SIX",
    Size = UDim2.new(0, 580, 0, 460),
    Theme = "Rose",
    ToggleKey = Enum.KeyCode.RightControl,
    OpenButton = {
        Enabled = false
    }
})

-- สร้างแท็บและเรียกใช้โมดูลตามลำดับที่ต้องการ
    local MainTab = Window:Tab({ Title = "หน้าหลัก", Icon = "layout-dashboard" })
    MainTabModule(MainTab, Window, WindUI, TeleportService)

    local CharacterTab = Window:Tab({ Title = "ตัวละคร", Icon = "user" })
    CharacterTabModule(CharacterTab, Window, WindUI, TeleportService)

    local PositionTab = Window:Tab({ Title = "ข้อมูล", Icon = "map-pin" })InfoTabModule(PositionTab, Window, WindUI)

local SettingsTab = Window:Tab({ Title = "ตั้งค่า", Icon = "settings" })
SettingsTabModule(SettingsTab, Window, WindUI, TeleportService)

-- เลือกให้แท็บ "หน้าหลัก" แสดงผลเป็นค่าเริ่มต้น
MainTab:Select()
