--// Venyx UI Simple - MasterZ UX (1 Page, 1 Toggle, Tampil Keren)

local ok, Venyx = pcall(function()
	return loadstring(game:HttpGet(
			"https://raw.githubusercontent.com/Stefanuk12/Venyx-UI-Library/main/source.lua"
	))()
end)

if not ok then
	warn("Gagal load Venyx:", Venyx)
	return
end

-- WAJIB: Icon ID agar page tampil di sidebar (tanpa ini UI tidak muncul)
local venyx = Venyx.new("MasterZ UX", 5013109572)

-- AUTO VARIABLE
local autoEnabled = false

-- PAGE (harus ada icon biar tampil)
local page = venyx:addPage("Auto", 5012544693)
-- TOGGLE (ini akan muncul di UI)
sec:addToggle({
	title = "Auto Start",
	default = false,
	callback = function(v)
			autoEnabled = v
			print("Auto:", v and "ON" or "OFF")
	end
})

-- Keybind untuk hide UI
sec:addKeybind({
	title = "Toggle UI",
	default = Enum.KeyCode.RightControl,
	key = Enum.KeyCode.RightControl,
	callback = function()
			venyx:toggle()
	end
})

-- Auto loop
task.spawn(function()
	while task.wait(0.2) do
			if autoEnabled then
					for x = 0, 100 do
							if not autoEnabled then break end
							print("Auto =>", x, 37)
							-- logic break/move taruh disini
							task.wait(0.2)
					end
			end
	end
end)