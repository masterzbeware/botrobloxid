-- Bot.lua
-- MasterZ Beware Bot System (Dispatcher Only)

-- ✅ Base repo untuk commands
local repoBase = "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Commands/"

-- ✅ Library UI
local obsidianRepo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(obsidianRepo .. "Library.lua"))()
local Options = Library.Options

-- ✅ Buat Window UI
local Window = Library:CreateWindow({
    Title = "Made by MasterZ",
    Footer = "v2.0.0",
    Icon = 0,
    NotifySide = "Right",
    ShowCustomCursor = true,
})
local Tabs = { Main = Window:AddTab("Main", "user") }

-- ✅ Debug helper
local function debugPrint(msg)
    print("[DEBUG] " .. tostring(msg))
end

-- ✅ Global Variables
_G.BotVars = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    TextChatService = game:GetService("TextChatService"),
    LocalPlayer = game:GetService("Players").LocalPlayer,
    ClientName = "FiestaGuardVip",

    ToggleAktif = false,

    -- 🔹 Default spacing & distance values
    JarakIkut = 5,
    FollowSpacing = 2,
    ShieldDistance = 5,
    ShieldSpacing = 4,
    RowSpacing = 4,
    SideSpacing = 4,
}

-- ✅ Identity Detection
local botMapping = {
    ["8802945328"] = "Bot1 - XBODYGUARDVIP01",
    ["8802949363"] = "Bot2 - XBODYGUARDVIP02",
    ["8802939883"] = "Bot3 - XBODYGUARDVIP03",
    ["8802998147"] = "Bot4 - XBODYGUARDVIP04",
}
_G.BotVars.BotIdentity = botMapping[tostring(_G.BotVars.LocalPlayer.UserId)] or "Unknown Bot"
debugPrint("Detected identity: " .. _G.BotVars.BotIdentity)

-- ✅ Commands Loader
local Commands = {}
local commandFiles = { "Ikuti.lua", "Stop.lua", "Shield.lua", "Row.lua", "Sync.lua" } -- RockPaper.lua dihapus

for _, fileName in ipairs(commandFiles) do
    local url = repoBase .. fileName
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if success and response then
        local func, err = loadstring(response)
        if func then
            local status, cmdTable = pcall(func)
            if status and type(cmdTable) == "table" then
                local nameKey = fileName:sub(1, #fileName - 4)
                Commands[nameKey:lower()] = cmdTable
                debugPrint("Loaded command via HTTP: " .. nameKey)
            else
                debugPrint("Failed executing command chunk: " .. fileName)
            end
        else
            debugPrint("Failed loadstring: " .. fileName)
        end
    else
        debugPrint("Failed HttpGet: " .. fileName)
    end
end

-- ✅ Handle Chat Commands
local function handleCommand(msg, client)
    if not _G.BotVars.ToggleAktif then return end
    msg = msg:lower()
    for name, cmd in pairs(Commands) do
        if msg:match("^!" .. name) and cmd.Execute then
            debugPrint("Executing command: " .. name .. " by " .. client.Name)
            cmd.Execute(msg, client)
        end
    end
end

-- ✅ Setup Client Listener (VIP only)
local function setupClient(player)
    local client = player

    if _G.BotVars.TextChatService and _G.BotVars.TextChatService.TextChannels then
        local generalChannel = _G.BotVars.TextChatService.TextChannels.RBXGeneral
        if generalChannel then
            generalChannel.OnIncomingMessage = function(message)
                local senderUserId = message.TextSource and message.TextSource.UserId
                local sender = senderUserId and _G.BotVars.Players:GetPlayerByUserId(senderUserId)
                if sender and sender.Name == _G.BotVars.ClientName then
                    handleCommand(message.Text, sender)
                end
            end
        end
    else
        player.Chatted:Connect(function(msg)
            if player.Name == _G.BotVars.ClientName then
                handleCommand(msg, player)
            end
        end)
    end
end

-- ✅ Apply listener ke semua pemain
for _, plr in ipairs(_G.BotVars.Players:GetPlayers()) do
    setupClient(plr)
end
_G.BotVars.Players.PlayerAdded:Connect(setupClient)

-- ✅ UI
local GroupBox1 = Tabs.Main:AddLeftGroupbox("Bot Options")

GroupBox1:AddInput("BotIdentity", {
    Default = _G.BotVars.BotIdentity,
    Text = "Bot Identity",
    Placeholder = "Auto-detected bot info",
})

GroupBox1:AddToggle("AktifkanBot", {
    Text = "Enable Bot System",
    Default = false,
    Tooltip = "Enable to accept chat commands (!ikuti, !stop, dll)",
    Callback = function(Value)
        _G.BotVars.ToggleAktif = Value
        debugPrint("ToggleAktif set to: " .. tostring(Value))
        Library:Notify("Bot System " .. (Value and "Enabled" or "Disabled"), 3)
    end,
})

-- 🔹 Input untuk spacing & distance
GroupBox1:AddInput("JarakIkutInput", {
    Default = tostring(_G.BotVars.JarakIkut),
    Text = "Follow Distance (VIP)",
    Placeholder = "Example: 5",
    Callback = function(Value)
        local number = tonumber(Value)
        if number then
            _G.BotVars.JarakIkut = number
            debugPrint("Follow distance set to: " .. number)
            Library:Notify("Follow distance set to: " .. number, 3)
        end
    end,
})

GroupBox1:AddInput("FollowSpacingInput", {
    Default = tostring(_G.BotVars.FollowSpacing),
    Text = "Follow Spacing (Antar Bot)",
    Placeholder = "Example: 2",
    Callback = function(Value)
        local number = tonumber(Value)
        if number then
            _G.BotVars.FollowSpacing = number
            debugPrint("Follow spacing set to: " .. number)
            Library:Notify("Follow spacing set to: " .. number, 3)
        end
    end,
})

GroupBox1:AddInput("ShieldDistanceInput", {
    Default = tostring(_G.BotVars.ShieldDistance),
    Text = "Shield Distance (VIP)",
    Placeholder = "Example: 5",
    Callback = function(Value)
        local number = tonumber(Value)
        if number then
            _G.BotVars.ShieldDistance = number
            debugPrint("Shield distance set to: " .. number)
            Library:Notify("Shield distance set to: " .. number, 3)
        end
    end,
})

GroupBox1:AddInput("ShieldSpacingInput", {
    Default = tostring(_G.BotVars.ShieldSpacing),
    Text = "Shield Spacing (Rows)",
    Placeholder = "Example: 4",
    Callback = function(Value)
        local number = tonumber(Value)
        if number then
            _G.BotVars.ShieldSpacing = number
            debugPrint("Shield spacing set to: " .. number)
            Library:Notify("Shield spacing set to: " .. number, 3)
        end
    end,
})

GroupBox1:AddInput("RowSpacingInput", {
    Default = tostring(_G.BotVars.RowSpacing),
    Text = "Row Spacing (Baris)",
    Placeholder = "Example: 4",
    Callback = function(Value)
        local number = tonumber(Value)
        if number then
            _G.BotVars.RowSpacing = number
            debugPrint("Row spacing set to: " .. number)
            Library:Notify("Row spacing set to: " .. number, 3)
        end
    end,
})

GroupBox1:AddInput("SideSpacingInput", {
    Default = tostring(_G.BotVars.SideSpacing),
    Text = "Side Spacing (Kiri-Kanan)",
    Placeholder = "Example: 4",
    Callback = function(Value)
        local number = tonumber(Value)
        if number then
            _G.BotVars.SideSpacing = number
            debugPrint("Side spacing set to: " .. number)
            Library:Notify("Side spacing set to: " .. number, 3)
        end
    end,
})

Library:Notify("Bot System Loaded!", 3)
debugPrint("Bot.lua finished loading")
