-- Load Venyx
local Venyx = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Stefanuk12/Venyx-UI-Library/main/source.lua"
))()

-- Window
local venyx = Venyx.new("MasterZ UX", 5013109572)

-- Page
local page = venyx:addPage("Auto", 5012544693)

-- Section kosong (wajib supaya element bisa tampil)
local sec = page:addSection("")

-- Button (ini pasti muncul)
sec:addButton("CLICK ME", function()
    print("Button ditekan!")
    -- taruh function kamu di sini
end)