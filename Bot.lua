-- =========================
-- SAFE LOAD LIBRARY
-- =========================

local url = "https://raw.githubusercontent.com/masterzbeware/peta-peta/main/petapeta"

local ok, source = pcall(function()
    return game:HttpGet(url)
end)

if not ok then
    warn("HttpGet gagal:", source)
    return
end

local func = loadstring(source)
if not func then
    warn("Loadstring gagal compile. Cek syntax di file GitHub.")
    return
end

local Venyx = func()
if not Venyx then
    warn("Library tidak return apa-apa. Pastikan ada 'return library' di paling bawah.")
    return
end

if not Venyx.new then
    warn("Venyx.new tidak ditemukan di library.")
    for k,v in pairs(Venyx) do
        print("Isi Venyx:", k, v)
    end
    return
end

-- =========================
-- BUAT UI
-- =========================

local UI = Venyx.new("MasterZ UX") -- FIXED (hapus parameter icon)

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

-- =========================
-- DEFAULT PAGE
-- =========================

UI:SelectPage(Auto, true)