-- Commands/WindowTab.lua

local Library = _G.BotVars.Library
local MainWindow = _G.BotVars.MainWindow

local Tabs = {}

-- Info Tab
Tabs.Info = MainWindow:AddTab("Info", "info")

-- Bot Info
local BotGroup = Tabs.Info:AddLeftGroupbox("Bot Info")
BotGroup:AddLabel("MasterZ HUB v1.0.0")
BotGroup:AddLabel("Script loaded")

-- Server Info
local ServerGroup = Tabs.Info:AddLeftGroupbox("Server Info")

-- Players (Auto Detect)
local playersLabel = ServerGroup:AddLabel("Players: ...")
local function updatePlayers()
    local players = game:GetService("Players")
    local playerCount = #players:GetPlayers()
    local maxPlayers = players.MaxPlayers
    playersLabel:SetText("Players: " .. playerCount .. "/" .. maxPlayers)
end

-- Latency (Auto Detect)
local latencyLabel = ServerGroup:AddLabel("Latency: ...")
local function updateLatency()
    local stats = game:GetService("Stats")
    local ping = stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    latencyLabel:SetText("Latency: " .. math.floor(ping) .. "ms")
end

-- Server Region (Auto Detect)
local regionLabel = ServerGroup:AddLabel("Server Region: ...")
local function updateRegion()
    local region = "Unknown"
    local success, result = pcall(function()
        return game:GetService("LocalizationService").RobloxLocaleId
    end)
    if success then
        region = result or "Unknown"
    end
    regionLabel:SetText("Server Region: " .. region)
end

-- In Server Time (Auto Detect)
local timeLabel = ServerGroup:AddLabel("In Server: ...")
local startTime = os.time()
local function updateTime()
    local currentTime = os.time()
    local timeInServer = currentTime - startTime
    local hours = math.floor(timeInServer / 3600)
    local minutes = math.floor((timeInServer % 3600) / 60)
    local seconds = timeInServer % 60
    timeLabel:SetText(string.format("In Server: %02d:%02d:%02d", hours, minutes, seconds))
end

-- Update semua info server setiap detik
spawn(function()
    while wait(1) do
        updatePlayers()
        updateLatency()
        updateRegion()
        updateTime()
    end
end)

ServerGroup:AddButton("Join Script", function()
    print("Copy join script")
end)

-- Wave / Status
local StatusGroup = Tabs.Info:AddLeftGroupbox("Wave")
StatusGroup:AddLabel("Your executor seems to support this script")

-- Discord
local DiscordGroup = Tabs.Info:AddLeftGroupbox("Discord")
DiscordGroup:AddButton("Tap to join the Discord Server", function()
    print("Join Discord")
end)

-- Combat Tab
Tabs.Combat = MainWindow:AddTab("Combat", "crosshair")

-- Utility Tab
Tabs.Utility = MainWindow:AddTab("Utility", "tool")

-- Visual Tab
Tabs.Visual = MainWindow:AddTab("Visual", "eye")

-- Save Tabs di global
_G.BotVars.Tabs = Tabs

print("[MasterZ HUB] WindowTab.lua loaded - Tabs siap digunakan.")

return Tabs