local repoBase = "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Commands/"
local obsidianRepo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

-- Load Obsidian
local success, Library = pcall(function()
    return loadstring(game:HttpGet(obsidianRepo .. "Library.lua"))()
end)

if not success or not Library then
    error("[Bot.lua] Gagal load Obsidian Library")
end

_G.BotVars = {
    Players = game:GetService("Players"),
    TextChatService = game:GetService("TextChatService"),
    RunService = game:GetService("RunService"),
    LocalPlayer = game:GetService("Players").LocalPlayer,

    -- Target yang dipilih oleh admin melalui !follow.
    -- Target ini boleh mengganti formasi dengan !frontline/!circle/!fourline.
    -- Hanya admin yang boleh mengakhiri semuanya dengan !stop.
    CommandTarget = nil,
}

local Window = Library:CreateWindow({
    Title = "MasterZ HUB",
    Footer = "1.0.1",
    Icon = 0
})

_G.BotVars.Library = Library
_G.BotVars.MainWindow = Window
_G.BotVars.Modules = {}

-- ✅ SEMUA COMMAND
local commandFiles = {
    "Perfix.lua",
    "Main.lua",
    "Follow.lua",
    "Frontline.lua",
    "Circle.lua",
    "Fourline.lua",
    "Rest.lua",
    "Salute.lua",
    "Sit.lua",
    "Agree.lua",
    "Backline.lua",
    "PushUp.lua",
    "Message.lua",
    "Collision.lua",
    "AteezDance.lua",
    "GabresDance.lua",
    "PakodiDance.lua",
    "KangoraDance.lua",
    "AsmaraDance.lua",
    "PargoyDance.lua",
    "VacationDance.lua",
    "BrazilDance.lua",
    "KetlinDance.lua",
    "HarleyDance.lua",
    "HeeseungDance.lua",
    "Worship.lua",
    "Centerline.lua",
}

for _, fileName in ipairs(commandFiles) do
    local ok, response = pcall(function()
        return game:HttpGet(repoBase .. fileName)
    end)

    if ok and response then
        local loader = loadstring(response)
        if loader then
            local successModule, moduleTable = pcall(loader)
            if successModule and type(moduleTable) == "table" then
                local key = fileName:gsub("%.lua$", ""):lower()
                _G.BotVars.Modules[key] = moduleTable
                print("[Bot.lua] Loaded:", key)
            end
        end
    end
end

task.wait(0.3)

local function jalankan(name)
    local module = _G.BotVars.Modules[name]
    if module and module.Execute then
        module.Execute()
        print("[Bot.lua] Executed:", name)
    end
end

-- ✅ EXECUTION ORDER
jalankan("perfix")
jalankan("main")
jalankan("follow")
jalankan("frontline")
jalankan("circle")
jalankan("fourline")
jalankan("rest")
jalankan("salute")
jalankan("sit")
jalankan("agree")
jalankan("backline")
jalankan("pushup")
jalankan("message")
jalankan("collision")
jalankan("ateezdance")
jalankan("gabresdance")
jalankan("pakodidance")
jalankan("kangoradance")
jalankan("asmaradance")
jalankan("pargoydance")
jalankan("vacationdance")
jalankan("brazildance")
jalankan("ketlindance")
jalankan("harleydance")
jalankan("heeseungdance")
jalankan("worship")
jalankan("centerline")

print("✅ Bot.lua loaded — All systems active.")
