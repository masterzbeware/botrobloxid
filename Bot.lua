-- Load Venyx
local Venyx = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Stefanuk12/Venyx-UI-Library/main/source.lua"
))()

local venyx = Venyx.new("MasterZ UX", 5013109572)

-- Buat page
local page = venyx:addPage("Auto", 5012544693)

-- Section TANPA JUDUL (tampilannya bersih)
local sec = page:addSection("")

-- Toggle asli Venyx
local aktif = false

sec:addToggle("Auto Start", false, function(v)
    aktif = v
    print("Auto =", v and "ON" or "OFF")
end)