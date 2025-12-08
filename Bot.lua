-- Bot.lua (versi lengkap dan sudah diperbaiki)

local repoBase     = "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Commands/"
local obsidianRepo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

-- =========================
-- Load Obsidian Library
-- =========================
local success, Library = pcall(function()
    return loadstring(game:HttpGet(obsidianRepo .. "Library.lua"))()
end)
if not success or not Library then
    error("[Bot.lua] Gagal load Obsidian Library!")
end

-- =========================
-- Global Variables
-- =========================
_G.BotVars = {
    Players = game:GetService("Players"),
    TextChatService = game:GetService("TextChatService"),
    RunService = game:GetService("RunService"),
    LocalPlayer = game:GetService("Players").LocalPlayer,
    ToggleAktif = false,
}

local player = _G.BotVars.LocalPlayer

-- =========================
-- Create Main Window
-- =========================
local MainWindow = Library:CreateWindow({
    Title = "MasterZ HUB",
    Footer = "1.0.1",
    Icon = 0,
})

_G.BotVars.Library = Library
_G.BotVars.MainWindow = MainWindow

-- =========================
-- List Modul UI
-- =========================
local commandFiles = {
    "WindowTab.lua",   -- harus load dulu agar Tabs.Main ada
    "AutoInsert.lua"
}

-- =========================
-- Load Modul dari GitHub
-- =========================
_G.BotVars.Modules = {}

for _, fileName in ipairs(commandFiles) do
    local url = repoBase .. fileName
    local success, response = pcall(function() return game:HttpGet(url) end)
    if success and response then
        local func = loadstring(response)
        if func then
            local status, cmdTable = pcall(func)
            if status and type(cmdTable) == "table" then
                local nameKey = fileName:sub(1, #fileName - 4)
                _G.BotVars.Modules[nameKey:lower()] = cmdTable
                print("[Bot.lua] Loaded module: " .. nameKey)
            else
                warn("[Bot.lua] Module " .. fileName .. " tidak mengembalikan table!")
            end
        else
            warn("[Bot.lua] Loadstring gagal untuk " .. fileName)
        end
    else
        warn("[Bot.lua] Failed to load " .. fileName)
    end
end

-- =========================
-- Jalankan WindowTab.lua dulu
-- =========================
local windowTabModule = _G.BotVars.Modules.windowtab
if windowTabModule then
    -- WindowTab.lua tidak memiliki Execute? kalau ada gunakan:
    if type(windowTabModule.Execute) == "function" then
        windowTabModule.Execute()
    end
end

-- =========================
-- Jalankan AutoInsert.lua di tab Oven
-- =========================
local autoInsertModule = _G.BotVars.Modules.autoinsert
if autoInsertModule and type(autoInsertModule.Execute) == "function" then
    -- pastikan Tabs.Main sudah ada
    if _G.BotVars.Tabs and _G.BotVars.Tabs.Main then
        autoInsertModule.Execute(_G.BotVars.Tabs.Main)
    else
        warn("[Bot.lua] Tabs.Main belum ditemukan, AutoInsert tidak dijalankan.")
    end
end

print("✅ Bot.lua loaded — semua modul siap digunakan.")
