-- Bot.lua (versi fix AutoBucket)

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
    Footer = "1.2.0",
    Icon = 0,
})

_G.BotVars.Library = Library
_G.BotVars.MainWindow = MainWindow

-- =========================
-- List Modul UI
-- =========================
local commandFiles = {
    "WindowTab.lua",
    "AutoInsert.lua",
    "AutoHarvest.lua",
    "AutoCrop.lua",
    "AutoCraft.lua",
    "AutoBucket.lua" -- FIX: nama file sudah benar
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
                -- nama key convert ke lowercase
                local nameKey = fileName:sub(1, #fileName - 4)
                _G.BotVars.Modules[nameKey:lower()] = cmdTable
                print("[Bot.lua] Loaded module:", nameKey)
            else
                warn("[Bot.lua] Module", fileName, "tidak mengembalikan table!")
            end
        else
            warn("[Bot.lua] Loadstring gagal untuk", fileName)
        end
    else
        warn("[Bot.lua] Failed to load", fileName)
    end
end

-- =========================
-- Jalankan WindowTab.lua
-- =========================
local windowTabModule = _G.BotVars.Modules.windowtab
if windowTabModule and type(windowTabModule.Execute) == "function" then
    windowTabModule.Execute()
end

task.wait(2) -- beri waktu UI ter-load

-- Helper Function untuk jalanin modul (lebih clean)
local function jalankan(nama)
    local module = _G.BotVars.Modules[nama]
    if module and type(module.Execute) == "function" then
        if _G.BotVars.Tabs and _G.BotVars.Tabs.Main then
            module.Execute(_G.BotVars.Tabs.Main)
        else
            warn("[Bot.lua]", nama, "tidak dijalankan — Tabs.Main belum ditemukan")
        end
    else
        warn("[Bot.lua] Modul", nama, "tidak ditemukan / tidak memiliki Execute")
    end
end

jalankan("autoinsert")
jalankan("autoharvest")
jalankan("autocrop")
jalankan("autocraft")
jalankan("autobucket") -- FIX: nama module benar

print("✅ Bot.lua loaded — semua modul UI aktif.")
