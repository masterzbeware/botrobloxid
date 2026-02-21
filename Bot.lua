-- LOAD VENYX
local Venyx = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Stefanuk12/Venyx-UI-Library/main/source.lua"
))()

-- WINDOW
local venyx = Venyx.new("MasterZ UX", 5013109572)

-- PAGE
local page = venyx:addPage("Auto", 5012544693)

-- PATCH: Buat addToggle di page, tapi format STRING, bukan TABLE
function page:addToggle(name, default, callback)
    local section = self:addSection("") -- section kosong, tidak terlihat
    return section:addToggle(name, default, callback)
end

-- TOGGLE (FORMAT STRING)
local auto = false
page:addToggle("Auto Start", false, function(v)
    auto = v
    print("Auto:", v and "ON" or "OFF")
end)

-- LOOP
task.spawn(function()
    while task.wait(0.2) do
        if auto then
            for x = 0, 100 do
                if not auto then break end
                print("Auto =>", x, 37)
                task.wait(0.2)
            end
        end
    end
end)