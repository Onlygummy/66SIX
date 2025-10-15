# 66SIX Project

โปรเจกต์ 66SIX เป็นสคริปต์อเนกประสงค์สำหรับ Roblox ที่พัฒนาขึ้นโดยใช้ WindUI Library เพื่อมอบประสบการณ์การใช้งานที่สวยงามและทันสมัย

## การติดตั้งและใช้งาน

คัดลอกและรันสคริปต์ด้านล่างนี้ใน Executor ของคุณ:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Onlygummy/66SIX/develop/script.lua"))()
```
*(หมายเหตุ: สคริปต์นี้กำลังอยู่ในระหว่างการพัฒนาบน branch `develop`)*

## ฟีเจอร์หลัก

สคริปต์ประกอบด้วย 2 แท็บหลัก:

### 1. แท็บหน้าหลัก (Main Tab)

เป็นศูนย์รวมฟังก์ชันสำหรับจัดการและมีปฏิสัมพันธ์กับผู้เล่นอื่น รวมถึงฟังก์ชันพิเศษสำหรับบางแมพ

-   **การเลือกเป้าหมาย**: เลือกผู้เล่นในเซิร์ฟเวอร์จาก Dropdown
-   **รีเฟรชรายชื่อ**: อัปเดตรายชื่อผู้เล่นล่าสุด
-   **ส่อง (Spy)**: เข้าสู่โหมดดูกล้องตามผู้เล่นเป้าหมาย สามารถควบคุมมุมกล้องได้อย่างอิสระด้วย `WASD`
-   **เทเลพอร์ต (Teleport)**: วาร์ปตัวละครของคุณไปหาผู้เล่นที่เลือก

#### **ฟังก์ชันพิเศษ: BannaTown**
เมื่ออยู่ในแมพ BannaTown (Place ID: `77837537595343`) จะมี Section พิเศษปรากฏขึ้นพร้อมฟังก์ชัน:
-   **God Mode**: โหมดบินและเดินทะลุสิ่งกีดขวาง ควบคุมการเคลื่อนที่ด้วยเมาส์และ `WASD`

### 2. แท็บตั้งค่า (Settings Tab)

-   **เปลี่ยนธีม**: ปรับแต่งสีสันของหน้าต่าง UI ได้หลายรูปแบบ
-   **เปลี่ยนปุ่มเปิด/ปิด**: ตั้งค่าปุ่มบนคีย์บอร์ดสำหรับเปิด-ปิดหน้าต่าง
-   **ปิดโปรแกรม**: ทำลาย UI ทั้งหมดและปิดการทำงานของสคริปต์

---

*เอกสารด้านล่างนี้เป็นสรุปการใช้งาน WindUI Library ที่ใช้ในโปรเจกต์นี้*

---

# WindUI Documentation (สรุปการใช้งาน)

เอกสารนี้สรุปวิธีการใช้งาน `WindUI` สำหรับสร้าง GUI ในเกม Roblox

## โครงสร้างพื้นฐาน

1.  **Window**: หน้าต่างหลักของ GUI
2.  **Tab**: แท็บสำหรับแบ่งหมวดหมู่ต่างๆ ซึ่งองค์ประกอบ UI จะถูกสร้างขึ้นภายในแท็บนี้โดยตรง
3.  **Elements**: องค์ประกอบ UI เช่น ปุ่ม, สไลเดอร์, ตัวเลือกสี ฯลฯ

## การเริ่มต้น

```lua
-- โหลดไลบรารี
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- สร้างหน้าต่างหลัก
local Window = WindUI:CreateWindow({
    Title = "ชื่อหน้าต่าง",
    Size = UDim2.new(0, 580, 0, 460), -- ขนาดหน้าต่าง
    Theme = "Dark", -- ธีมที่ใช้ (เช่น Dark, Light, Rose, Midnight)
    ToggleKey = Enum.KeyCode.RightControl -- ปุ่มสำหรับเปิด/ปิด
})
```

## การสร้างแท็บและองค์ประกอบ (Elements)

องค์ประกอบต่างๆ จะถูกสร้างขึ้นโดยเรียกใช้ฟังก์ชันจากอ็อบเจกต์ `Tab` โดยตรง

### 1. การสร้าง Tab

```lua
-- สร้างแท็บใหม่
local MainTab = Window:Tab({
    Title = "หน้าหลัก",
    Icon = "home" -- ชื่อไอคอนจากไลบรารี (https://lucide.dev/icons/)
})

local SettingsTab = Window:Tab({
    Title = "ตั้งค่า",
    Icon = "settings"
})
```

### 2. การสร้างองค์ประกอบ (Elements)

-   **Button**: ปุ่มกด
    ```lua
    MainTab:Button({
        Title = "กดปุ่ม",
        Desc = "คำอธิบายสั้นๆ เกี่ยวกับปุ่มนี้",
        Icon = "mouse-pointer-click",
        Callback = function()
            WindUI:Notify({
                Title = "แจ้งเตือน",
                Content = "คุณได้กดปุ่มแล้ว",
                Icon = "check-circle",
                Duration = 5
            })
        end
    })
    ```
-   **Toggle**: สวิตช์เปิด/ปิด
    ```lua
    MainTab:Toggle({
        Title = "เปิด/ปิด ฟังก์ชัน",
        Desc = "สำหรับเปิดหรือปิดการทำงาน",
        Value = true, -- ค่าเริ่มต้น (true/false)
        Callback = function(value)
            print("สถานะตอนนี้คือ:", value)
        end
    })
    ```
-   **Slider**: แถบเลื่อนปรับค่า
    ```lua
    MainTab:Slider({
        Title = "ปรับความเร็ว",
        Desc = "ปรับความเร็วในการเคลื่อนที่",
        Value = {
            Default = 50, -- ค่าเริ่มต้น
            Min = 0,      -- ค่าต่ำสุด
            Max = 100     -- ค่าสูงสุด
        },
        Step = 1, -- (ไม่จำเป็น) ระยะการเพิ่ม/ลดค่าในแต่ละครั้ง
        Callback = function(value)
            print("ปรับค่าเป็น:", value)
        end
    })
    ```
-   **Input**: กล่องข้อความสำหรับกรอกข้อมูล
    ```lua
    MainTab:Input({
        Title = "ชื่อของคุณ",
        Desc = "กรุณากรอกชื่อของคุณ",
        Placeholder = "ชื่อ...",
        Callback = function(text)
            print("ข้อความที่ยืนยัน:", text)
        end
    })
    ```
-   **Dropdown**: กล่องตัวเลือก
    ```lua
    MainTab:Dropdown({
        Title = "เลือกผลไม้",
        Desc = "เลือกผลไม้ที่คุณชอบ",
        Values = {"Apple", "Banana", "Orange"}, -- รายการตัวเลือก
        Multi = false, -- อนุญาตให้เลือกหลายรายการหรือไม่
        Value = "Apple", -- (ไม่จำเป็น) ค่าเริ่มต้น
        Callback = function(value)
            -- ถ้า Multi = false, value คือ string
            -- ถ้า Multi = true, value คือ table
            print("คุณเลือก:", value)
        end
    })
    ```
-   **Keybind**: ปุ่มสำหรับตั้งค่าคีย์ลัด
    ```lua
    MainTab:Keybind({
        Title = "ตั้งค่าปุ่ม",
        Desc = "ตั้งค่าปุ่มสำหรับใช้งาน",
        Value = "F", -- ปุ่มเริ่มต้น
        Callback = function(key)
            print("ปุ่มทำงาน:", key)
        end
    })
    ```
-   **Colorpicker**: ตัวเลือกสี
    ```lua
    MainTab:Colorpicker({
        Title = "เลือกสี",
        Desc = "เลือกสีที่ต้องการ",
        Default = Color3.fromRGB(255, 80, 80),
        Callback = function(color)
            print("เลือกสี:", color)
        end
    })
    ```
-   **Paragraph**: กลุ่มข้อความ
    ```lua
    MainTab:Paragraph({
        Title = "หัวข้อเรื่อง",
        Desc = "นี่คือเนื้อหาของ Paragraph ที่สามารถใส่ข้อความยาวๆ ได้"
    })
    ```
-   **Divider & Space**: เส้นคั่นและเว้นวรรค
    ```lua
    MainTab:Divider()
    MainTab:Space()
    ```
-   **Section**: กลุ่มขององค์ประกอบที่พับเก็บได้
    ```lua
    local MySection = MainTab:Section({
        Title = "ส่วนที่พับเก็บได้",
        Icon = "box",
        Opened = true -- (ไม่จำเป็น) ให้แสดงเนื้อหาเริ่มต้นหรือไม่
    })
    
    -- สามารถเพิ่มองค์ประกอบภายใน Section ได้
    MySection:Button({ Title = "ปุ่มใน Section" })
    ```

## ฟังก์ชันเพิ่มเติม

-   **การแจ้งเตือน (Notification)**
    ```lua
    WindUI:Notify({
        Title = "หัวข้อ",
        Content = "รายละเอียด...",
        Icon = "info",
        Duration = 5 -- วินาที
    })
    ```
-   **กล่องโต้ตอบ (Dialog)**
    ```lua
    Window:Dialog({
        Title = "ยืนยัน",
        Content = "คุณต้องการดำเนินการต่อหรือไม่?",
        Icon = "alert-triangle",
        Buttons = {
            {
                Title = "ยกเลิก",
                Variant = "Secondary" -- "Primary", "Secondary", "Tertiary"
            },
            {
                Title = "ยืนยัน",
                Variant = "Primary",
                Callback = function() print("ยืนยันแล้ว") end
            }
        }
    })
    ```
