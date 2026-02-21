--// LOCKED OLD VENYX VERSION (supports page:addToggle)
local Venyx = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Stefan-uk/VenyxUI/main/source.lua"
))()

local venyx = Venyx.new("MasterZ UX", 5013109572)

-- Halaman
local page = venyx:addPage("Auto", 5012544693)

-- DIRECT TOGGLE (NO SECTION)
local autoEnabled = false

page:addToggle("Auto Start", false, function(v)
    autoEnabled = v
    print("Auto:", v and "ON" or "OFF")
end)

-- Loop
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