-- Bot.lua (versi diperbaiki)

local repoBase     = "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Commands/"
local obsidianRepo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

-- Load Obsidian Library dengan pcall
local success, Library = pcall(function()
    return loadstring(game:HttpGet(obsidianRepo .. "Library.lua"))()
end)
if not success or not Library then
    error("[Bot.lua] Gagal load Obsidian Library!")
end

local function debugPrint(msg)
    print("[DEBUG] " .. tostring(msg))
end

-- GLOBAL VARIABLES
_G.BotVars = {
    Players = game:GetService("Players"),
    TextChatService = game:GetService("TextChatService"),
    RunService = game:GetService("RunService"),
    LocalPlayer = game:GetService("Players").LocalPlayer,
    ToggleAktif = false,
}

local player = _G.BotVars.LocalPlayer

-- CREATE MAIN WINDOW
local MainWindow = Library:CreateWindow({
    Title = "MasterZ HUB",
    Footer = "1.0.0",
    Icon = 0,
})

_G.BotVars.Library = Library
_G.BotVars.MainWindow = MainWindow

-- LIST MODUL UI
local VIPCommands = {}
local commandFiles = {
    "AutoOven.lua",
    "WindowTab.lua",
    "Cow.lua",
    "Treetap.lua",
    "Compostbin.lua",
    "AutoInsert.lua",
}

-- FUNCTION LOAD SCRIPT DARI GITHUB
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
                else
                    warn("Module " .. fileName .. " tidak mengembalikan table!")
                end
            else
                warn("Loadstring gagal untuk " .. fileName)
            end
        else
            warn("Failed to load " .. fileName)
        end
    end
end

-- LOAD MODUL
loadScripts(commandFiles, repoBase, VIPCommands)
_G.BotVars.CommandFiles = VIPCommands

-- EXECUTE MODUL UI
-- Gunakan task.defer agar UI siap, termasuk dropdown
task.defer(function()
    for name, module in pairs(VIPCommands) do
        if module.Execute then
            -- Pastikan setiap modul menerima parameter tab/window
            local success, err = pcall(function()
                module.Execute(MainWindow)
            end)
            if not success then
                warn("[Bot.lua] Gagal eksekusi modul " .. name .. ":", err)
            else
                debugPrint("UI module executed: " .. name)
            end
        end
    end
end)

debugPrint("✅ Bot.lua loaded — semua UI aktif tanpa kursor atau crosshair.")
