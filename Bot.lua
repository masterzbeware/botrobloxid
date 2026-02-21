-- Load venyx
local Venyx = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Stefanuk12/Venyx-UI-Library/main/source.lua"
))()

local venyx = Venyx.new("MasterZ UX", 5013109572)
local page = venyx:addPage("Auto", 5012544693)

-- ====== PATCH: TAMBAHKAN FUNGSI addToggle KE PAGE ======
function page:addToggle(name, default, callback)
    local section = self:addSection("")  -- section tanpa nama
    return section:addToggle({
        title = name,
        default = default,
        callback = callback
    })
end
-- ========================================================

-- Variable auto
local autoEnabled = false

-- Sekarang addToggle DI PAGE langsung BISA ✔
page:addToggle("Auto Start", false, function(v)
    autoEnabled = v
    print("Auto:", v and "ON" or "OFF")
end)

-- Auto Loop
task.spawn(function()
    while task.wait(0.2) do
        if autoEnabled then
            for x = 0, 100 do
                if not autoEnabled then break end
                print("Auto =>", x, 37)
                task.wait(0.2)
            end
        end
    end
end)