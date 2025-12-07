local Library = _G.BotVars.Library
local MainWindow = _G.BotVars.MainWindow

local Tabs = {}

-- Info Tab
Tabs.Info = MainWindow:AddTab("Info", "info")

-- Bot Info (Kiri)
local BotGroup = Tabs.Info:AddLeftGroupbox("Bot Info")
BotGroup:AddLabel("MasterZ HUB v1.0.0")
BotGroup:AddLabel("Script loaded")

-- Server Info (Kanan)
local ServerGroup = Tabs.Info:AddRightGroupbox("Server Info")

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
    local ping = 0
    pcall(function()
        local stats = game:GetService("Stats")
        local dataPing = stats.Network.ServerStatsItem["Data Ping"]
        if dataPing then ping = dataPing:GetValue() end
    end)
    latencyLabel:SetText("Latency: " .. math.floor(ping) .. "ms")
end

-- Server Region (Auto Detect)
local regionLabel = ServerGroup:AddLabel("Server Region: ...")
local function updateRegion()
    local region = "Unknown"
    pcall(function()
        region = game:GetService("LocalizationService").RobloxLocaleId or "Unknown"
    end)
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
task.spawn(function()
    while true do
        updatePlayers()
        updateLatency()
        updateRegion()
        updateTime()
        task.wait(1)
    end
end)

-- Oven Tab
Tabs.Main = MainWindow:AddTab("Oven", "crosshair")

-- Harvest Tab (baru)
Tabs.Harvest = MainWindow:AddTab("Harvest", "crosshair") -- ikon bisa diganti sesuai kebutuhan

-- Save Tabs di global
_G.BotVars.Tabs = Tabs

print("[MasterZ HUB] WindowTab.lua loaded - Tabs siap digunakan.")

return Tabs
