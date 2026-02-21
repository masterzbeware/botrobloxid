--// Venyx UI (2 Pages: Auto & Settings) - MasterZ UX (No Theme)
--// NOTE: Theme dihapus sesuai request

local ok, Venyx = pcall(function()
	return loadstring(game:HttpGet("https://raw.githubusercontent.com/Stefanuk12/Venyx-UI-Library/main/source.lua"))()
end)

if not ok or not Venyx then
	warn("Gagal load Venyx UI Library:", Venyx)
	return
end

-- Window
local venyx = Venyx.new("MasterZ UX", 5013109572)
if venyx and venyx.Notify then
	venyx:Notify("Loaded", "MasterZ UX berhasil dibuka", 2)
end

-- ==================================================
-- STATE
-- ==================================================
_G.AutoEnabled = false
_G.AutoDelay = 0.2
_G.StartX = 0
_G.EndX = 100
_G.TargetY = 37
_G.AutoReverse = false

-- ==================================================
-- PAGE 1: AUTO
-- ==================================================
local autoPage = venyx:addPage("Auto", 5012544693)
local autoMain = autoPage:addSection("Auto Controls")
local autoRange = autoPage:addSection("Range Settings")

autoMain:addToggle({
	title = "Auto Start",
	default = false,
	callback = function(v)
			_G.AutoEnabled = v
			venyx:Notify("Auto", v and "Auto ON" or "Auto OFF", 1.5)
	end
})

autoMain:addSlider({
	title = "Delay (x10)",
	default = 2, -- 2 = 0.2s
	min = 1,
	max = 20,
	callback = function(v)
			_G.AutoDelay = v / 10
	end
})

autoMain:addButton({
	title = "Run Once",
	callback = function()
			local fromX = math.min(_G.StartX, _G.EndX)
			local toX = math.max(_G.StartX, _G.EndX)

			if not _G.AutoReverse then
					for x = fromX, toX do
							print(("Run Once => (%d, %d)"):format(x, _G.TargetY))
							-- TEMPATKAN LOGIC MOVE/BREAK KAMU DI SINI
							task.wait(_G.AutoDelay)
					end
			else
					for x = toX, fromX, -1 do
							print(("Run Once => (%d, %d)"):format(x, _G.TargetY))
							-- TEMPATKAN LOGIC MOVE/BREAK KAMU DI SINI
							task.wait(_G.AutoDelay)
					end
			end

			venyx:Notify("Run Once", "Selesai menjalankan 1x range", 1.5)
	end
})

autoMain:addToggle({
	title = "Reverse Loop",
	default = false,
	callback = function(v)
			_G.AutoReverse = v
	end
})

autoRange:addSlider({
	title = "Start X",
	default = 0,
	min = 0,
	max = 200,
	callback = function(v)
			_G.StartX = v
	end
})

autoRange:addSlider({
	title = "End X",
	default = 100,
	min = 0,
	max = 200,
	callback = function(v)
			_G.EndX = v
	end
})

autoRange:addSlider({
	title = "Y Tile",
	default = 37,
	min = 0,
	max = 200,
	callback = function(v)
			_G.TargetY = v
	end
})

-- ==================================================
-- PAGE 2: SETTINGS
-- ==================================================
local settingsPage = venyx:addPage("Settings", 5012544693)
local uiSec = settingsPage:addSection("UI")
local miscSec = settingsPage:addSection("Misc")

uiSec:addKeybind({
	title = "Toggle UI Key",
	default = Enum.KeyCode.RightControl,
	key = Enum.KeyCode.RightControl,
	callback = function()
			venyx:toggle()
	end
})

miscSec:addButton({
	title = "Hide / Show UI",
	callback = function()
			venyx:toggle()
	end
})

miscSec:addButton({
	title = "Unload (Hide)",
	callback = function()
			venyx:toggle()
			venyx:Notify("UI", "UI disembunyikan", 1.5)
	end
})

-- ==================================================
-- AUTO LOOP (EDIT LOGIC KAMU DI SINI)
-- ==================================================
task.spawn(function()
	while true do
			task.wait(_G.AutoDelay)

			if _G.AutoEnabled then
					local fromX = math.min(_G.StartX, _G.EndX)
					local toX = math.max(_G.StartX, _G.EndX)

					if not _G.AutoReverse then
							for x = fromX, toX do
									if not _G.AutoEnabled then break end

									-- ============================================
									-- TEMPATKAN LOGIC KAMU DI SINI
									-- Contoh:
									-- move ke tile (x, _G.TargetY)
									-- break/punch tile (x, _G.TargetY)
									-- ============================================
									print(("Auto Action => (%d, %d)"):format(x, _G.TargetY))

									task.wait(_G.AutoDelay)
							end
					else
							for x = toX, fromX, -1 do
									if not _G.AutoEnabled then break end

									-- ============================================
									-- TEMPATKAN LOGIC KAMU DI SINI
									-- ============================================
									print(("Auto Action => (%d, %d)"):format(x, _G.TargetY))

									task.wait(_G.AutoDelay)
							end
					end
			end
	end
end)