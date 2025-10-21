-- Bot.lua
-- MasterZ Beware Bot System (UI Loader tanpa Client, tanpa Command Handler, dan tanpa Cursor)

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
}

-- 🖱️ Hapus semua bentuk cursor
pcall(function()
    local UserInputService = game:GetService("UserInputService")
    local player = _G.BotVars.LocalPlayer
    if player and player:FindFirstChild("PlayerGui") then
        for _, gui in ipairs(player.PlayerGui:GetDescendants()) do
            if gui:IsA("ImageLabel") or gui:IsA("ImageButton") then
                if gui.Name:lower():find("cursor") then
                    gui:Destroy()
                end
            end
        end
    end
    UserInputService.MouseIconEnabled = false
end)

-- 🎨 Buat Window utama
local MainWindow = Library:CreateWindow({
    Title = "MasterZ HUB",
    Footer = "1.0.0",
    Icon = 0,
})

-- Simpan ke global
_G.BotVars.Library = Library
_G.BotVars.MainWindow = MainWindow

-- 📦 Daftar module
local VIPCommands = {}
local commandFiles = { "Headshot.lua", "ESP.lua", "AIM.lua", "Hide.lua", "WindowTab.lua"}

-- 🔹 Fungsi load semua module
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

-- 🚀 Load semua module
loadScripts(commandFiles, repoBase, VIPCommands)
_G.BotVars.CommandFiles = VIPCommands

-- 🔹 Jalankan semua module
for name, module in pairs(VIPCommands) do
    if module.Execute then
        debugPrint("Running UI module: " .. name)
        module.Execute()
    end
end

debugPrint("✅ Bot.lua loaded — semua UI module aktif (tanpa cursor apa pun)")
