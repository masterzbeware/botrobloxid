-- Bot.lua (Fixed Version tanpa Moderator & GameCommands)
-- MasterZ Beware Bot System (Dispatcher Only)

local repoBase       = "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Commands/"
local obsidianRepo   = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

-- Load Obsidian Library
local Library = loadstring(game:HttpGet(obsidianRepo .. "Library.lua"))()
local Options = Library.Options

-- UI Window
local Window = Library:CreateWindow({
    Title = "Made by MasterZ",
    Footer = "v2.0.4",
    Icon = 0,
    NotifySide = "Right",
    ShowCustomCursor = true,
})
local Tabs = { Main = Window:AddTab("Main", "user") }

-- Debug print
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

    ActiveClient = "guardfiesta", -- DisplayName / username
    ActiveClientId = 8802945328,  -- UserId client
    ClientRef = nil,
}

-- Bot Mapping
local botMapping = {
    ["8802945328"] = "Bot1 - XBODYGUARDVIP01",
    ["8802949363"] = "Bot2 - XBODYGUARDVIP02",
    ["8802939883"] = "Bot3 - XBODYGUARDVIP03",
    ["8802998147"] = "Bot4 - XBODYGUARDVIP04",
    ["8802991722"] = "Bot5 - XBODYGUARDVIP05",
}
_G.BotVars.BotIdentity = botMapping[tostring(_G.BotVars.LocalPlayer.UserId)] or "Unknown Bot"
debugPrint("Detected identity: " .. _G.BotVars.BotIdentity)

-- Load VIP Commands
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
        end
    end
end

loadScripts(commandFiles, repoBase, VIPCommands)
_G.BotVars.CommandFiles = VIPCommands

-- Handle Commands
local function handleCommand(msg, sender)
    msg = msg:lower()
    for name, cmd in pairs(VIPCommands) do
        if msg:match("^!" .. name) and cmd.Execute then
            debugPrint("Executing command: " .. name .. " by " .. sender.Name)
            cmd.Execute(msg, sender)
        end
    end
end

-- Setup Client Reference
local function setupClient(player)
    if player.UserId == _G.BotVars.ActiveClientId then
        _G.BotVars.ClientRef = player
        debugPrint("Client setup complete: " .. player.Name)

        -- TextChatService listener
        if _G.BotVars.TextChatService and _G.BotVars.TextChatService.TextChannels then
            local generalChannel = _G.BotVars.TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if generalChannel then
                generalChannel.OnIncomingMessage = function(message)
                    local senderUserId = message.TextSource and message.TextSource.UserId
                    local sender = senderUserId and _G.BotVars.Players:GetPlayerByUserId(senderUserId)
                    if sender and sender == _G.BotVars.ClientRef then
                        handleCommand(message.Text, sender)
                    end
                end
            end
        else
            -- Fallback: Player.Chatted
            player.Chatted:Connect(function(msg)
                handleCommand(msg, player)
            end)
        end
    end
end

-- Apply listener ke semua pemain + PlayerAdded
for _, plr in ipairs(_G.BotVars.Players:GetPlayers()) do
    setupClient(plr)
end
_G.BotVars.Players.PlayerAdded:Connect(setupClient)

-- UI Setup
local GroupBox1 = Tabs.Main:AddLeftGroupbox("Bot Options")

-- Bot Identity (readonly)
GroupBox1:AddInput("BotIdentity", { 
    Default=_G.BotVars.BotIdentity, 
    Text="Bot Identity", 
    Placeholder="Auto-detected bot info",
    Callback = function(Value) end
})

-- Active Client Username / DisplayName
GroupBox1:AddInput("ActiveClientName", {
    Default = _G.BotVars.ActiveClient,
    Text = "Active Client (Username/DisplayName)",
    Placeholder = "Masukkan username client",
    Callback = function(Value)
        _G.BotVars.ActiveClient = Value
        debugPrint("ActiveClient name updated: "..tostring(Value))

        local plr = _G.BotVars.Players:FindFirstChild(Value)
        if plr then
            _G.BotVars.ActiveClientId = plr.UserId
            Options.ActiveClientId:SetValue(tostring(plr.UserId))
            debugPrint("ActiveClientId auto updated: "..plr.UserId)
            setupClient(plr)
        end
    end
})

-- Active Client UserId
GroupBox1:AddInput("ActiveClientId", {
    Default = tostring(_G.BotVars.ActiveClientId),
    Text = "Active Client UserId",
    Placeholder = "Masukkan UserId client",
    Callback = function(Value)
        local id = tonumber(Value)
        if id then
            _G.BotVars.ActiveClientId = id
            debugPrint("ActiveClientId updated manually: "..id)
            local plr = nil
            for _, p in ipairs(_G.BotVars.Players:GetPlayers()) do
                if p.UserId == id then
                    plr = p
                    break
                end
            end
            if plr then
                setupClient(plr)
            end
        else
            debugPrint("UserId invalid input: "..tostring(Value))
        end
    end
})

-- Toggles
GroupBox1:AddToggle("AktifkanBot", {
    Text="Enable Bot System (VIP only)",
    Default=false,
    Callback=function(Value) _G.BotVars.ToggleAktif=Value end
})

-- Spacing / Distance Inputs
GroupBox1:AddInput("JarakIkutInput", { Default=tostring(_G.BotVars.JarakIkut), Text="Follow Distance (VIP)", Callback=function(Value) _G.BotVars.JarakIkut=tonumber(Value) end })
GroupBox1:AddInput("FollowSpacingInput", { Default=tostring(_G.BotVars.FollowSpacing), Text="Follow Spacing (Antar Bot)", Callback=function(Value) _G.BotVars.FollowSpacing=tonumber(Value) end })
GroupBox1:AddInput("ShieldDistanceInput", { Default=tostring(_G.BotVars.ShieldDistance), Text="Shield Distance (VIP)", Callback=function(Value) _G.BotVars.ShieldDistance=tonumber(Value) end })
GroupBox1:AddInput("ShieldSpacingInput", { Default=tostring(_G.BotVars.ShieldSpacing), Text="Shield Spacing (Rows)", Callback=function(Value) _G.BotVars.ShieldSpacing=tonumber(Value) end })
GroupBox1:AddInput("RowSpacingInput", { Default=tostring(_G.BotVars.RowSpacing), Text="Row Spacing (Baris)", Callback=function(Value) _G.BotVars.RowSpacing=tonumber(Value) end })
GroupBox1:AddInput("SideSpacingInput", { Default=tostring(_G.BotVars.SideSpacing), Text="Side Spacing (Kiri-Kanan)", Callback=function(Value) _G.BotVars.SideSpacing=tonumber(Value) end })

debugPrint("Bot.lua finished loading (Fixed Version tanpa Moderator & GameCommands)")
