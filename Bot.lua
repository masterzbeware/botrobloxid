--// Venyx UI Super Simple (1 Page, Toggle Only, No State Table) - MasterZ UX
local ok, Venyx = pcall(function()
	return loadstring(game:HttpGet("https://raw.githubusercontent.com/Stefanuk12/Venyx-UI-Library/main/source.lua"))()
end)

if not ok or not Venyx then
	warn("Gagal load Venyx:", Venyx)
	return
end

local venyx = Venyx.new("MasterZ UX")
local autoEnabled = false

local page = venyx:addPage("Auto")
local sec = page:addSection("Controls")

sec:addToggle({
	title = "Auto Start",
	default = false,
	callback = function(v)
			autoEnabled = v
			print("Auto:", v and "ON" or "OFF")
	end
})

sec:addKeybind({
	title = "Toggle UI",
	default = Enum.KeyCode.RightControl,
	key = Enum.KeyCode.RightControl,
	callback = function()
			venyx:toggle()
	end
})

-- Auto loop (langsung jalan kalau toggle ON)
task.spawn(function()
	while true do
			task.wait(0.2)

			if autoEnabled then
					for x = 0, 100 do
							if not autoEnabled then break end

							print(("Auto => (%d, %d)"):format(x, 37))
							-- taruh logic move/break kamu di sini

							task.wait(0.2)
					end
			end
	end
end)