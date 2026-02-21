local Venyx = loadstring(game:HttpGet("https://raw.githubusercontent.com/masterzbeware/peta-peta/refs/heads/main/petapeta"))()

local UI = Venyx.new("MasterZ UX", 5013109572)

local Rage = UI:addPage("AUTO", 5012544693)
local Section = Rage:addSection("Main")

Section:addToggle("Auto Place", false, function(v)
    print("Auto Place:", v)
end)

-- Slider (default 50, min 0, max 100)
Section:addSlider("Min Damage", 50, 0, 100, function(v)
    print("Min Damage:", v)
end)

-- Dropdown (kasih default)
Section:addDropdown("Hitbox", {"Head","Body","Legs"}, "Head", function(v)
    print("Selected:", v)
end)

UI:SelectPage(UI.pages[1], true)