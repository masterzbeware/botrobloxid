-- Bot.lua
-- MasterZ Beware Bot System (Command Loader Only)

local repoBase     = "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Commands/"
local obsidianRepo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

-- Load Obsidian Library
local Library = loadstring(game:HttpGet(obsidianRepo .. "Library.lua"))()

-- Debug
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

    ActiveClient = "FiestaGuardShop",
    ActiveClientId = 9722561353,
    ClientRef = nil,
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

-- Load command files
local VIPCommands = {}
local commandFiles = {
    "Ikuti.lua","Stop.lua","RoomVIP.lua","Shield.lua","Row.lua","Sync.lua",
    "Pushup.lua","Frontline.lua","AmbilAlih.lua","Reset.lua","Salute.lua",
    "Absen.lua","Bubarbarisan.lua","Location.lua","LogChat.lua","Addtarget.lua",
    "ModeBuaya.lua","Square.lua","Wedge.lua","Barrier.lua","Say.lua","Box.lua",
    "FrontCover.lua","Text.lua","AddSong.lua","Vote.lua","Color.lua"
}

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

-- Command handler
local function handleCommand(msg, sender)
    msg = msg:lower()
    for name, cmd in pairs(VIPCommands) do
        if msg:match("^!" .. name) and cmd.Execute then
            debugPrint("Executing command: " .. name .. " by " .. sender.Name)
            cmd.Execute(msg, sender)
        end
    end
end

-- Setup client connection
local function setupClient(player)
    if player.UserId == _G.BotVars.ActiveClientId then
        _G.BotVars.ClientRef = player
        debugPrint("Client setup complete: " .. player.Name)

        local TCS = _G.BotVars.TextChatService
        if TCS and TCS.TextChannels then
            local general = TCS.TextChannels:FindFirstChild("RBXGeneral")
            if general then
                general.OnIncomingMessage = function(message)
                    local senderUserId = message.TextSource and message.TextSource.UserId
                    local sender = senderUserId and _G.BotVars.Players:GetPlayerByUserId(senderUserId)
                    if sender and sender == _G.BotVars.ClientRef then
                        handleCommand(message.Text, sender)
                    end
                end
            end
        else
            player.Chatted:Connect(function(msg)
                handleCommand(msg, player)
            end)
        end
    end
end

-- Apply to all players
for _, plr in ipairs(_G.BotVars.Players:GetPlayers()) do
    setupClient(plr)
end
_G.BotVars.Players.PlayerAdded:Connect(setupClient)

debugPrint("✅ Bot.lua loaded (Commands only, UI handled by Absen.lua)")
