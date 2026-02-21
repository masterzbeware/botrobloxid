local Venyx = loadstring(game:HttpGet("https://raw.githubusercontent.com/masterzbeware/peta-peta/refs/heads/main/petapeta"))()

local UI = Venyx.new("MasterZ UX", 5013109572)

-- Buat Page
local Rage = UI:addPage("AUTO", 5012544693)

-- Buat Section
local Section = Rage:addSection("Main")

-- Toggle
Section:addToggle("Auto Place", false, function(v)
    print("Auto Place:", v)
end)

-- Slider (default, min, max)
Section:addSlider("Min Damage", 50, 0, 100, function(v)
    print("Min Damage:", v)
end)

-- Dropdown (judul, list, default, callback)
Section:addDropdown("Hitbox", {"Head","Body","Legs"}, "Head", function(v)
    print("Selected:", v)
end)

-- INI YANG PENTING
UI:SelectPage(Rage, true)