-- D:/Script/tabs/settings_tab.lua
-- ไฟล์นี้จะเก็บโค้ดทั้งหมดที่เกี่ยวกับ "แท็บตั้งค่า"

return function(Tab, Window, WindUI)
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
