-- Bot.lua
-- MasterZ Beware Bot System (UI Loader tanpa Client & tanpa Command Handler)

local repoBase     = "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Commands/"
local obsidianRepo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

-- 🧩 Load Obsidian Library
local Library = loadstring(game:HttpGet(obsidianRepo .. "Library.lua"))()

-- 🧠 Debug print helper
local function debugPrint(msg)
    print("[DEBUG] " .. tostring(msg))
end

-- 🌐 Global Variables
_G.BotVars = {
    Players = game:GetService("Players"),
    TextChatService = game:GetService("TextChatService"),
    RunService = game:GetService("RunService"),
    LocalPlayer = game:GetService("Players").LocalPlayer,

    ToggleAktif = false,

    JarakIkut = 3,
    FollowSpacing = 3,
    ShieldDistance = 4,
    ShieldSpacing = 4,
    RowSpacing = 3,
    SideSpacing = 5,
}

-- 🎨 Buat satu Window utama saja (dipakai semua module)
local MainWindow = Library:CreateWindow({
    Title = "MasterZ HUB",
    Footer = "1.0.0", -- ⚠️ tidak lagi menggunakan identitas
    Icon = 0,
    ShowCustomCursor = false,
})

-- Simpan ke variabel global biar module lain bisa pakai
_G.BotVars.Library = Library
_G.BotVars.MainWindow = MainWindow

-- 📦 Daftar module UI yang mau dimuat
local VIPCommands = {}
local commandFiles = { "ESP.lua", "AIM.lua", "Hide.lua", "Bullet.lua" } -- tambah file lain di sini jika perlu

-- 🔹 Fungsi untuk load semua script module
local function loadScripts(files, repo, targetTable)
    for _, fileName in ipairs(files) do
        local url = repo .. fileName
        local success, response = pcall(function() return game:HttpGet(url) end)
        if success and response then
            local func = loadstring(response)
            if func then
                local status, cmdTable = pcall(func)
                if status and type(cmdTable) == "table" then
                    local nameKey = fileName:sub(1, #fileName - 4)
                    targetTable[nameKey:lower()] = cmdTable
                    debugPrint("Loaded module: " .. nameKey)
                end
            end
        else
            warn("Failed to load " .. fileName)
        end
    end
end

-- 🚀 Load dan jalankan semua module
loadScripts(commandFiles, repoBase, VIPCommands)
_G.BotVars.CommandFiles = VIPCommands

for name, module in pairs(VIPCommands) do
    if module.Execute then
        debugPrint("Running UI module: " .. name)
        module.Execute()
    end
end

debugPrint("✅ Bot.lua loaded — semua UI module aktif di satu window utama")
