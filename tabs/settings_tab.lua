-- D:/Script/tabs/settings_tab.lua
-- ไฟล์นี้จะเก็บโค้ดทั้งหมดที่เกี่ยวกับ "แท็บตั้งค่า"

return function(Tab, Window, WindUI, TeleportService)

    local TeleportSection = Tab:Section({
        Title = "ตั้งค่าการเคลื่อนที่",
        Icon = "move-3d",
        Opened = true
    })

    local modeMapping = {
        ["วาร์ปทันที (เสี่ยง)"] = "instant",
        ["ซอยย่อย (ปลอดภัยขึ้น)"] = "phased"
    }

    TeleportSection:Dropdown({
        Title = "โหมดการเคลื่อนที่",
        Desc = "เลือกวิธีที่สคริปต์จะใช้ในการวาร์ป",
        Values = {"วาร์ปทันที (เสี่ยง)", "ซอยย่อย (ปลอดภัยขึ้น)"},
        Value = "วาร์ปทันที (เสี่ยง)", -- New Default
        Callback = function(selectedName)
            local mode = modeMapping[selectedName]
            if mode and TeleportService then
                TeleportService:setMode(mode)
                WindUI:Notify({ Title = "ตั้งค่า", Content = "เปลี่ยนโหมดการเคลื่อนที่เป็น: " .. selectedName })
            end
        end
    })

    Tab:Divider()

    Tab:Dropdown({
        Title = "เปลี่ยนธีม",
        Desc = "เลือกธีมของหน้าต่าง UI",
        Values = {"Dark", "Light", "Midnight", "Rose", "Crimson", "Plant", "MonokaiPro"}, -- รายชื่อธีม
        Value = "Midnight", -- ธีมเริ่มต้น
        Callback = function(ThemeName)
            WindUI:SetTheme(ThemeName) -- เปลี่ยนธีม
        end
    })

Tab:Keybind({
        Title = "ปุ่มเปิด/ปิดหน้าต่าง",
        Desc = "เปลี่ยนปุ่มสำหรับเปิด/ปิด UI",
        Value = "RightControl", -- ปุ่มเริ่มต้น
        Callback = function(key)
            Window:SetToggleKey(Enum.KeyCode[key])
            WindUI:Notify({ Title = "ตั้งค่า", Content = "เปลี่ยนปุ่มเปิด/ปิดเป็น " .. key })
        end
    })

    Tab:Button({
        Title = "ปิดโปรแกรม",
        Desc = "กดเพื่อปิดโปรแกรมทั้งหมด",
        Icon = "trash-2",
        Callback = function()
            Window:Destroy()
        end
    })
end