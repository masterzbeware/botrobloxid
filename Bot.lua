-- Bot.lua
-- MasterZ Beware Bot System (Dispatcher Only)

local repoBase       = "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Commands/"
local gamesRepo      = "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Games/"
local moderatorRepo  = "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Moderator/"
local obsidianRepo   = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

local Library = loadstring(game:HttpGet(obsidianRepo .. "Library.lua"))()
local Options = Library.Options

local Window = Library:CreateWindow({
    Title = "Made by MasterZ",
    Footer = "v1.0.0",
    Icon = 0,
    NotifySide = "Right",
    ShowCustomCursor = true,
})
local Tabs = { Main = Window:AddTab("Main", "user") }

local function debugPrint(msg)
    print("[DEBUG] " .. tostring(msg))
end

-- Global Variables
_G.BotVars = {
    Players = game:GetService("Players"),
    TextChatService = game:GetService("TextChatService"),
    LocalPlayer = game:GetService("Players").LocalPlayer,
    ClientName = "FiestaGuardVip",
    RunService = game:GetService("RunService"),

    ToggleAktif = false,
    ToggleGames = false,

    JarakIkut = 3,
    FollowSpacing = 3,
    ShieldDistance = 4,
    ShieldSpacing = 4,
    RowSpacing = 3,
    SideSpacing = 5,

    ActiveClient = "GuardFiesta",
}

-- Identity Detection
local botMapping = {
    ["8802945328"] = "Bot1 - XBODYGUARDVIP01",
    ["8802949363"] = "Bot2 - XBODYGUARDVIP02",
    ["8802939883"] = "Bot3 - XBODYGUARDVIP03",
    ["8802998147"] = "Bot4 - XBODYGUARDVIP04",
    ["8802991722"] = "Bot5 - XBODYGUARDVIP05",
}
_G.BotVars.BotIdentity = botMapping[tostring(_G.BotVars.LocalPlayer.UserId)] or "Unknown Bot"
debugPrint("Detected identity: " .. _G.BotVars.BotIdentity)

-- Commands Loader
local VIPCommands = {}
local GameCommands = {}

local commandFiles = {
    "Ikuti.lua","Stop.lua","RoomVIP.lua","Shield.lua","Row.lua","Sync.lua",
    "Pushup.lua","Frontline.lua","AmbilAlih.lua","Reset.lua","Salute.lua",
    "Absen.lua","Bubarbarisan.lua","Location.lua","LogChat.lua","Addtarget.lua",
    "ModeBuaya.lua","Square.lua","Wedge.lua","Barrier.lua","Say.lua","Box.lua",
    "FrontCover.lua","Text.lua","AddSong.lua","Vote.lua"
}
local gameFiles = { "Rockpaper.lua", "Coinflip.lua", "Slot.lua" }
local moderatorFiles = { "Client.lua", "Remove.lua","AutoJoinClient.lua" }

-- Load Commands VIP
for _, fileName in ipairs(commandFiles) do
    local url = repoBase .. fileName
    local success, response = pcall(function() return game:HttpGet(url) end)
    if success and response then
        local func = loadstring(response)
        if func then
            local status, cmdTable = pcall(func)
            if status and type(cmdTable) == "table" then
                local nameKey = fileName:sub(1, #fileName - 4)
                VIPCommands[nameKey:lower()] = cmdTable
                debugPrint("Loaded VIP command: " .. nameKey)
            end
        end
    end
end

-- Load Games
for _, fileName in ipairs(gameFiles) do
    local url = gamesRepo .. fileName
    local success, response = pcall(function() return game:HttpGet(url) end)
    if success and response then
        local func = loadstring(response)
        if func then
            local status, cmdTable = pcall(func)
            if status and type(cmdTable) == "table" then
                local nameKey = fileName:sub(1, #fileName - 4)
                GameCommands[nameKey:lower()] = cmdTable
                debugPrint("Loaded Game command: " .. nameKey)
            end
        end
    end
end

-- Load Moderator (Client + Remove)
for _, fileName in ipairs(moderatorFiles) do
    local url = moderatorRepo .. fileName
    local success, response = pcall(function() return game:HttpGet(url) end)
    if success and response then
        local func = loadstring(response)
        if func then
            local status, cmdTable = pcall(func)
            if status and type(cmdTable) == "table" then
                local nameKey = fileName:sub(1, #fileName - 4)
                VIPCommands[nameKey:lower()] = cmdTable
                debugPrint("Loaded Moderator command: " .. nameKey)
            end
        end
    end
end

-- Simpan untuk Client.lua
_G.BotVars.CommandFiles = VIPCommands

-- Handle Commands
local function handleCommand(msg, client, cmdTable)
    msg = msg:lower()
    for name, cmd in pairs(cmdTable) do
        if msg:match("^!" .. name) and cmd.Execute then
            debugPrint("Executing command: " .. name .. " by " .. client.Name)
            cmd.Execute(msg, client)
        end
    end
end

-- Client Listener
local function setupClient(player)
    local function processMessage(msg, sender)
        msg = msg:lower()
        local activeClient = _G.BotVars.ActiveClient or _G.BotVars.ClientName

        if _G.BotVars.ToggleAktif then
            if sender.Name == _G.BotVars.ClientName or sender.Name == activeClient then
                handleCommand(msg, sender, VIPCommands)
            end
        end
        if _G.BotVars.ToggleGames then
            handleCommand(msg, sender, GameCommands)
        end
    end

    if _G.BotVars.TextChatService and _G.BotVars.TextChatService.TextChannels then
        local generalChannel = _G.BotVars.TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if generalChannel then
            generalChannel.OnIncomingMessage = function(message)
                local senderUserId = message.TextSource and message.TextSource.UserId
                local sender = senderUserId and _G.BotVars.Players:GetPlayerByUserId(senderUserId)
                if sender then
                    processMessage(message.Text, sender)
                end
            end
        end
    else
        player.Chatted:Connect(function(msg)
            processMessage(msg, player)
        end)
    end
end

-- Apply listener ke semua pemain
for _, plr in ipairs(_G.BotVars.Players:GetPlayers()) do
    setupClient(plr)
end
_G.BotVars.Players.PlayerAdded:Connect(setupClient)

-- UI Setup
local GroupBox1 = Tabs.Main:AddLeftGroupbox("Bot Options")

GroupBox1:AddInput("BotIdentity", { Default=_G.BotVars.BotIdentity, Text="Bot Identity", Placeholder="Auto-detected bot info" })

GroupBox1:AddToggle("AktifkanBot", {
    Text="Enable Bot System (VIP only)",
    Default=false,
    Callback=function(Value) _G.BotVars.ToggleAktif=Value end
})

GroupBox1:AddToggle("AktifkanGames", {
    Text="Enable Game Commands",
    Default=false,
    Callback=function(Value) _G.BotVars.ToggleGames=Value end
})

GroupBox1:AddInput("JarakIkutInput", { Default=tostring(_G.BotVars.JarakIkut), Text="Follow Distance (VIP)", Callback=function(Value) _G.BotVars.JarakIkut=tonumber(Value) end })
GroupBox1:AddInput("FollowSpacingInput", { Default=tostring(_G.BotVars.FollowSpacing), Text="Follow Spacing (Antar Bot)", Callback=function(Value) _G.BotVars.FollowSpacing=tonumber(Value) end })
GroupBox1:AddInput("ShieldDistanceInput", { Default=tostring(_G.BotVars.ShieldDistance), Text="Shield Distance (VIP)", Callback=function(Value) _G.BotVars.ShieldDistance=tonumber(Value) end })
GroupBox1:AddInput("ShieldSpacingInput", { Default=tostring(_G.BotVars.ShieldSpacing), Text="Shield Spacing (Rows)", Callback=function(Value) _G.BotVars.ShieldSpacing=tonumber(Value) end })
GroupBox1:AddInput("RowSpacingInput", { Default=tostring(_G.BotVars.RowSpacing), Text="Row Spacing (Baris)", Callback=function(Value) _G.BotVars.RowSpacing=tonumber(Value) end })
GroupBox1:AddInput("SideSpacingInput", { Default=tostring(_G.BotVars.SideSpacing), Text="Side Spacing (Kiri-Kanan)", Callback=function(Value) _G.BotVars.SideSpacing=tonumber(Value) end })

debugPrint("Bot.lua finished loading")
