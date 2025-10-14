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
local MainTab_URL = baseURL .. "tabs/main_tab.lua?v=" .. cacheBuster
local SettingsTab_URL = baseURL .. "tabs/settings_tab.lua?v=" .. cacheBuster
local SelfTab_URL = baseURL .. "tabs/self_tab.lua?v=" .. cacheBuster


-- =================================================================== --
--      หมายเหตุ: หาก Executor ของคุณรองรับ readfile() หรือ loadfile()
--      คุณสามารถใช้โค้ดด้านล่างนี้แทนการใช้ URL ได้ เพื่อความสะดวกในการพัฒนา
-- =================================================================== --
-- local WindUI = loadstring(readfile("D:/Script/windui.lua"))()
-- local MainTabModule = loadstring(readfile("D:/Script/tabs/main_tab.lua"))()
-- local SettingsTabModule = loadstring(readfile("D:/Script/tabs/settings_tab.lua"))()
-- local SelfTabModule = loadstring(readfile("D:/Script/tabs/self_tab.lua"))()
-- =================================================================== --


-- โหลดไลบรารีและโมดูลจาก URL
local WindUI = loadstring(game:HttpGet(WindUI_URL))()
local MainTabModule = loadstring(game:HttpGet(MainTab_URL))()
local SettingsTabModule = loadstring(game:HttpGet(SettingsTab_URL))()
local SelfTabModule = loadstring(game:HttpGet(SelfTab_URL))()


-- สร้างหน้าต่างหลัก (Window)
local Window = WindUI:CreateWindow({
    Title = "66SIX",
    Size = UDim2.new(0, 580, 0, 460),
    Theme = "Midnight",
    ToggleKey = Enum.KeyCode.RightControl,
    OpenButton = {
        Enabled = false
    }
})

-- สร้างแท็บ
local MainTab = Window:Tab({
    Title = "หน้าหลัก",
    Icon = "layout-dashboard"
})

local SelfTab = Window:Tab({
    Title = "ส่วนตัว",
    Icon = "user"
})

local SettingsTab = Window:Tab({
    Title = "ตั้งค่า",
    Icon = "settings"
})

-- เรียกใช้ Module เพื่อสร้าง UI ในแต่ละแท็บ
-- โดยส่งอ็อบเจกต์ของ Tab, Window, และ WindUI เข้าไปให้ Module ใช้งาน
MainTabModule(MainTab, Window, WindUI)
SelfTabModule(SelfTab, Window, WindUI)
SettingsTabModule(SettingsTab, Window, WindUI)

-- เลือกให้แท็บ "หน้าหลัก" แสดงผลเป็นค่าเริ่มต้น
MainTab:Select()
