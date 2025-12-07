-- Bot.lua (versi load-only, tanpa VIPCommands / auto execute)

local repoBase     = "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Commands/"
local obsidianRepo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

-- Load Obsidian Library
local success, Library = pcall(function()
    return loadstring(game:HttpGet(obsidianRepo .. "Library.lua"))()
end)
if not success or not Library then
    error("[Bot.lua] Gagal load Obsidian Library!")
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
    Footer = "1.1.0",
    Icon = 0,
})

_G.BotVars.Library = Library
_G.BotVars.MainWindow = MainWindow

-- LIST MODUL UI
local commandFiles = {
    "AutoOven.lua",
    "WindowTab.lua",
    "Cow.lua",
    "Treetap.lua",
    "Compostbin.lua",
    "AutoInsert.lua",
}

-- FUNCTION LOAD SCRIPT DARI GITHUB
_G.BotVars.Modules = {} -- tempat menyimpan modul

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

print("✅ Bot.lua loaded — semua modul siap digunakan.")
