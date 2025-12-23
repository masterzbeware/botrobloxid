local repoBase = "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Commands/"
local obsidianRepo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

local success, Library = pcall(function()
    return loadstring(game:HttpGet(obsidianRepo .. "Library.lua"))()
end)

if not success or not Library then
    error("[Bot.lua] Gagal load Obsidian Library!")
end

_G.BotVars = {
    Players = game:GetService("Players"),
    TextChatService = game:GetService("TextChatService"),
    RunService = game:GetService("RunService"),
    LocalPlayer = game:GetService("Players").LocalPlayer
}

local MainWindow = Library:CreateWindow({
    Title = "MasterZ HUB",
    Footer = "1.0.0",
    Icon = 0
})

_G.BotVars.Library = Library
_G.BotVars.MainWindow = MainWindow

local commandFiles = {
    "Main.lua"
}

_G.BotVars.Modules = {}

for _, fileName in ipairs(commandFiles) do
    local url = repoBase .. fileName
    local ok, response = pcall(function()
        return game:HttpGet(url)
    end)

    if ok and response then
        local loader = loadstring(response)
        if loader then
            local status, moduleTable = pcall(loader)
            if status and type(moduleTable) == "table" then
                local key = fileName:sub(1, #fileName - 4):lower()
                _G.BotVars.Modules[key] = moduleTable
                print("[Bot.lua] Loaded module:", key)
            end
        end
    end
end

local windowTabModule = _G.BotVars.Modules.windowtab
if windowTabModule and type(windowTabModule.Execute) == "function" then
    windowTabModule.Execute()
end

task.wait(1)

local function jalankan(nama)
    local module = _G.BotVars.Modules[nama]
    if module and type(module.Execute) == "function" then
        if _G.BotVars.Tabs and _G.BotVars.Tabs.Main then
            module.Execute(_G.BotVars.Tabs.Main)
        else
            warn("[Bot.lua] Tabs.Main belum siap")
        end
    else
        warn("[Bot.lua] Modul", nama, "tidak ditemukan")
    end
end

jalankan("main")

print("✅ Bot.lua loaded — Server Info aktif.")
