-- Load Venyx UI library dari source2.lua
local Venyx = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Stefanuk12/Venyx-UI-Library/main/source2.lua"
))()

-- Membuat window Venyx dengan title
local venyx = Venyx.new({
    title = "MasterZ UX"
})

-- Membuat page Auto
local page = venyx:addPage("Autos")

-- Menyembunyikan section dengan cara langsung menambahkan toggle ke page
local autoEnabled = false

page:addToggle({
    title = "Auto Start",
    default = false,
    callback = function(value)
        autoEnabled = value
        print("Auto status:", value and "ON" or "OFF")
    end
})