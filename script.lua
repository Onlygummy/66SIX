--[[
    ไฟล์นี้เป็นไฟล์หลัก (Main Entry Point)
    ทำหน้าที่โหลด Library และ Module ต่างๆ ที่จำเป็น
]]

-- =================================================================== --
--      สำคัญ: แก้ไข URL ด้านล่างนี้เป็น URL ไฟล์ Raw จาก GitHub ของคุณ
-- =================================================================== --

-- URL สำหรับโหลดไลบรารี (จาก GitHub ของคุณ)
local WindUI_URL = "https://raw.githubusercontent.com/Onlygummy/66SIX/main/windui.lua"

-- URL สำหรับโหลดโมดูลของแต่ละแท็บ (จาก GitHub ของคุณ)
local MainTab_URL = "https://raw.githubusercontent.com/Onlygummy/66SIX/main/tabs/main_tab.lua"
local SettingsTab_URL = "https://raw.githubusercontent.com/Onlygummy/66SIX/main/tabs/settings_tab.lua"


-- =================================================================== --
--      หมายเหตุ: หาก Executor ของคุณรองรับ readfile() หรือ loadfile()
--      คุณสามารถใช้โค้ดด้านล่างนี้แทนการใช้ URL ได้ เพื่อความสะดวกในการพัฒนา
-- =================================================================== --
-- local WindUI = loadstring(readfile("D:/Script/windui.lua"))()
-- local MainTabModule = loadstring(readfile("D:/Script/tabs/main_tab.lua"))()
-- local SettingsTabModule = loadstring(readfile("D:/Script/tabs/settings_tab.lua"))()
-- =================================================================== --


-- โหลดไลบรารีและโมดูลจาก URL
local WindUI = loadstring(game:HttpGet(WindUI_URL))()
local MainTabModule = loadstring(game:HttpGet(MainTab_URL))()
local SettingsTabModule = loadstring(game:HttpGet(SettingsTab_URL))()


-- สร้างหน้าต่างหลัก (Window)
local Window = WindUI:CreateWindow({
    Title = "66SIX",
    Size = UDim2.new(0, 580, 0, 460),
    Theme = "Midnight",
    ToggleKey = Enum.KeyCode.RightControl
})

-- สร้างแท็บ
local MainTab = Window:Tab({
    Title = "หน้าหลัก",
    Icon = "layout-dashboard"
})

local SettingsTab = Window:Tab({
    Title = "ตั้งค่า",
    Icon = "settings"
})

-- เรียกใช้ Module เพื่อสร้าง UI ในแต่ละแท็บ
-- โดยส่งอ็อบเจกต์ของ Tab, Window, และ WindUI เข้าไปให้ Module ใช้งาน
MainTabModule(MainTab, Window, WindUI)
SettingsTabModule(SettingsTab, Window, WindUI)

-- เลือกให้แท็บ "หน้าหลัก" แสดงผลเป็นค่าเริ่มต้น
MainTab:Select()
