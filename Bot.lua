local Venyx = loadstring(game:HttpGet("https://raw.githubusercontent.com/Stefanuk12/Venyx-UI-Library/main/source.lua"))()

local UI = Venyx.new("MasterZ UX", 5013109572)

local Rage = UI:addPage("RAGE", 5012544693)
local Section = Rage:addSection("Main")

Section:addToggle("Auto Place", false, function(v)
    print("Auto Place:", v)
end)

Section:addSlider("Min Damage", 0, 100, 50, function(v)
    print("Min Damage:", v)
end)

Section:addDropdown("Hitbox", {"Head","Body","Legs"}, function(v)
    print("Selected:", v)
end)

UI:SelectPage(UI.pages[1], true)