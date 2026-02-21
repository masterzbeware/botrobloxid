--// Venyx UI Simple - MasterZ UX (NO SECTION, langsung toggle)

local ok, Venyx = pcall(function()
	return loadstring(game:HttpGet(
			"https://raw.githubusercontent.com/Stefanuk12/Venyx-UI-Library/main/source.lua"
	))()
end)

if not ok then
	warn("Gagal load Venyx:", Venyx)
	return
end

-- Window
local venyx = Venyx.new("MasterZ UX", 5013109572)

-- Page tanpa section
local page = venyx:addPage("Auto", 5012544693)

-- Toggle langsung ditaruh di page (bukan section)
page:addToggle({
	title = "Auto Start",
	default = false,
	callback = function(v)
			autoEnabled = v
			print("Auto:", v and "ON" or "OFF")
	end
})

-- Auto variable
local autoEnabled = false

-- Loop
task.spawn(function()
	while true do
			task.wait(0.2)

			if autoEnabled then
					for x = 0, 100 do
							if not autoEnabled then break end

							print("Auto =>", x, 37)
							-- logic kamu taruh di sini

							task.wait(0.2)
					end
			end
	end
end)