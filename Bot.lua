local Venyx = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Stefanuk12/Venyx-UI-Library/main/source.lua"
))()

local venyx = Venyx.new("MasterZ UX", 5013109572)
local page = venyx:addPage("Auto", 5012544693)

-- Wajib, tapi tidak kelihatan
local sec = page:addSection("")

local aktif = false

local btn = sec:addButton("Auto : OFF", function()
    aktif = not aktif
    btn:update("Auto : " .. (aktif and "ON" or "OFF"))
    print("Status Auto =", aktif)
end)