--// Venyx UI (2 Pages: Auto & Settings)
local Venyx = loadstring(game:HttpGet("https://raw.githubusercontent.com/Stefanuk12/Venyx-UI-Library/main/source.lua"))()

-- Window
local venyx = Venyx.new("Maslini Hub", 5013109572)
venyx:Notify("Loaded", "UI 2 page berhasil dibuka", 2)

-- Default Theme
local darkTheme = {
    Background = Color3.fromRGB(24, 24, 24),
    Glow = Color3.fromRGB(0, 0, 0),
    Accent = Color3.fromRGB(10, 10, 10),
    LightContrast = Color3.fromRGB(20, 20, 20),
    DarkContrast = Color3.fromRGB(14, 14, 14),
    TextColor = Color3.fromRGB(255, 255, 255)
}
venyx:setTheme(darkTheme)

-- State
_G.AutoEnabled = false
_G.AutoDelay = 0.2
_G.StartX = 0
_G.EndX = 100
_G.TargetY = 37

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
        print(("Run Once | X: %d -> %d | Y: %d"):format(_G.StartX, _G.EndX, _G.TargetY))
        -- taruh logic auto kamu di sini (sekali jalan)
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

uiSec:addButton({
    title = "Dark Theme",
    callback = function()
        venyx:setTheme({
            Background = Color3.fromRGB(24, 24, 24),
            Glow = Color3.fromRGB(0, 0, 0),
            Accent = Color3.fromRGB(10, 10, 10),
            LightContrast = Color3.fromRGB(20, 20, 20),
            DarkContrast = Color3.fromRGB(14, 14, 14),
            TextColor = Color3.fromRGB(255, 255, 255)
        })
    end
})

uiSec:addButton({
    title = "Blue Theme",
    callback = function()
        venyx:setTheme({
            Background = Color3.fromRGB(20, 24, 30),
            Glow = Color3.fromRGB(0, 0, 0),
            Accent = Color3.fromRGB(25, 60, 120),
            LightContrast = Color3.fromRGB(24, 30, 40),
            DarkContrast = Color3.fromRGB(18, 22, 30),
            TextColor = Color3.fromRGB(255, 255, 255)
        })
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
-- AUTO LOOP (edit logic kamu di sini)
-- ==================================================
task.spawn(function()
    while task.wait(_G.AutoDelay) do
        if _G.AutoEnabled then
            -- Contoh loop range X (0,37 sampai 100,37)
            local fromX = math.min(_G.StartX, _G.EndX)
            local toX = math.max(_G.StartX, _G.EndX)

            for x = fromX, toX do
                if not _G.AutoEnabled then break end

                -- ==================================================
                -- TEMPATKAN LOGIC KAMU DI SINI
                -- misalnya:
                -- 1) move ke tile (x, _G.TargetY)
                -- 2) punch/break tile (x, _G.TargetY)
                -- ==================================================
                print(("Auto Action => (%d, %d)"):format(x, _G.TargetY))

                task.wait(_G.AutoDelay)
            end
        end
    end
end)