local Venyx = loadstring(game:HttpGet("https://raw.githubusercontent.com/masterzbeware/peta-peta/main/petapeta"))()

local UI = Venyx.new("MasterZ UX", 5013109572)

-- =========================
-- PAGE 1
-- =========================
local Auto = UI:addPage("AUTO", 5012544693)
local AutoSection = Auto:addSection("Main")

AutoSection:addToggle("Auto Place", false, function(v)
    print("Auto Place:", v)
end)

AutoSection:addSlider("Min Damage", 50, 0, 100, function(v)
    print("Min Damage:", v)
end)

AutoSection:addDropdown("Hitbox", {"Head","Body","Legs"}, "Head", function(v)
    print("Selected:", v)
end)

-- =========================
-- PAGE 2
-- =========================
local Visual = UI:addPage("VISUAL", 5012544693)
local VisualSection = Visual:addSection("ESP Settings")

VisualSection:addToggle("ESP Enabled", false, function(v)
    print("ESP:", v)
end)

VisualSection:addColorPicker("ESP Color", Color3.fromRGB(255,0,0), function(v)
    print("Color:", v)
end)


-- Pilih page pertama saat buka
UI:SelectPage(Auto, true)