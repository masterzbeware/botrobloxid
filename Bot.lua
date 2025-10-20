-- Bot.lua
-- MasterZ Beware Bot System (Command Loader Only, tanpa Client & tanpa Command Handler)

local repoBase     = "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Commands/"
local obsidianRepo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

-- Load Obsidian Library
local Library = loadstring(game:HttpGet(obsidianRepo .. "Library.lua"))()

-- Debug print helper
local function debugPrint(msg)
    print("[DEBUG] " .. tostring(msg))
end

-- Global Variables
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

-- Bot identity map
local botMapping = {
    ["8802945328"] = "Bot1 - XBODYGUARDVIP01",
    ["8802949363"] = "Bot2 - XBODYGUARDVIP02",
    ["8802939883"] = "Bot3 - XBODYGUARDVIP03",
    ["8802998147"] = "Bot4 - XBODYGUARDVIP04",
    ["8802991722"] = "Bot5 - XBODYGUARDVIP05",
}
_G.BotVars.BotIdentity = botMapping[tostring(_G.BotVars.LocalPlayer.UserId)] or "Unknown Bot"

debugPrint("Detected identity: " .. _G.BotVars.BotIdentity)

-- 🔹 Load command files (hanya script berbasis UI seperti ESP.lua / Absen.lua)
local VIPCommands = {}
local commandFiles = { "ESP.lua" } -- ubah atau tambah jika ada file lain

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
                    debugPrint("Loaded command: " .. nameKey)
                end
            end
        else
            warn("Failed to load " .. fileName)
        end
    end
end

loadScripts(commandFiles, repoBase, VIPCommands)
_G.BotVars.CommandFiles = VIPCommands

-- 🔹 Jalankan semua UI module otomatis
for name, module in pairs(VIPCommands) do
    if module.Execute then
        debugPrint("Running module UI: " .. name)
        module.Execute()
    end
end

debugPrint("✅ Bot.lua loaded (Tanpa Client & Command Handler, hanya UI modules aktif)")
