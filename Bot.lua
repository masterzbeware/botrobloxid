-- Bot.lua
-- MasterZ Beware Bot System (Dispatcher Only)
-- ✅ Versi diperbarui: Tambahan PathfindingService & notifikasi error loader

-- 📂 Repo Path
local repoBase   = "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Commands/"
local gamesRepo  = "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Games/"
local obsidianRepo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

-- 📦 UI Library
local Library = loadstring(game:HttpGet(obsidianRepo .. "Library.lua"))()
local Options = Library.Options

-- 📋 Window Setup
local Window = Library:CreateWindow({
    Title = "Made by MasterZ",
    Footer = "v1.5.0",
    Icon = 0,
    NotifySide = "Right",
    ShowCustomCursor = true,
})
local Tabs = { Main = Window:AddTab("Main", "user") }

-- 🧠 Debug Printer
local function debugPrint(msg)
    print("[DEBUG] " .. tostring(msg))
end

-- 🌍 Global Variables
_G.BotVars = {
    Players = game:GetService("Players"),
    TextChatService = game:GetService("TextChatService"),
    LocalPlayer = game:GetService("Players").LocalPlayer,
    ClientName = "FiestaGuardVip",
    RunService = game:GetService("RunService"),
    PathfindingService = game:GetService("PathfindingService"), -- ✅ Tambahan penting

    ToggleAktif = false,   -- VIP-only commands
    ToggleGames = false,   -- Game commands

    -- Spacing & distance
    JarakIkut = 2,
    FollowSpacing = 3,
    ShieldDistance = 4,
    ShieldSpacing = 3,
    RowSpacing = 2,
    SideSpacing = 4,
}

-- 🤖 Identity Detection
local botMapping = {
    ["8802945328"] = "Bot1 - XBODYGUARDVIP01",
    ["8802949363"] = "Bot2 - XBODYGUARDVIP02",
    ["8802939883"] = "Bot3 - XBODYGUARDVIP03",
    ["8802998147"] = "Bot4 - XBODYGUARDVIP04",
    ["8802991722"] = "Bot5 - XBODYGUARDVIP05", -- ✅ Tambahan Bot5
}

_G.BotVars.BotIdentity = botMapping[tostring(_G.BotVars.LocalPlayer.UserId)] or "Unknown Bot"
debugPrint("Detected identity: " .. _G.BotVars.BotIdentity)

-- 📂 Commands Loader
local VIPCommands = {}
local GameCommands = {}

local commandFiles = {
    "Ikuti.lua",
    "Stop.lua",
    "RoomVIP.lua",
    "Shield.lua",
    "Row.lua",
    "Sync.lua",
    "Pushup.lua",
    "Frontline.lua",
    "AmbilAlih.lua",
    "Reset.lua",
    "Salute.lua",
    "Absen.lua",
    "Bubarbarisan.lua",
    "Location.lua",
    "LogChat.lua",
    "Addtarget.lua",
    "ModeBuaya.lua",
    "Square.lua",
    "Wedge.lua",
    "Barrier.lua",
    "Say.lua",
}

local gameFiles = {
    "Rockpaper.lua",
    "Coinflip.lua",
    "Slot.lua",
}

-- 🧩 Loader untuk Commands folder (VIP only)
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
            else
                debugPrint("Failed executing VIP: " .. fileName)
                Library:Notify("⚠️ Gagal eksekusi " .. fileName, 3)
            end
        end
    else
        debugPrint("Failed HttpGet VIP: " .. fileName)
        Library:Notify("⚠️ Gagal memuat " .. fileName, 3)
    end
end

-- 🎮 Loader untuk Games folder
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
            else
                debugPrint("Failed executing Game: " .. fileName)
                Library:Notify("⚠️ Gagal eksekusi " .. fileName, 3)
            end
        end
    else
        debugPrint("Failed HttpGet Game: " .. fileName)
        Library:Notify("⚠️ Gagal memuat " .. fileName, 3)
    end
end

-- ⚡ Handle Commands
local function handleCommand(msg, client, cmdTable)
    msg = msg:lower()
    for name, cmd in pairs(cmdTable) do
        if msg:match("^!" .. name) and cmd.Execute then
            debugPrint("Executing command: " .. name .. " by " .. client.Name)
            cmd.Execute(msg, client)
        end
    end
end

-- 👂 Setup Client Listener
local function setupClient(player)
    local function processMessage(msg, sender)
        msg = msg:lower()

        -- VIP-only commands
        if sender.Name == _G.BotVars.ClientName and _G.BotVars.ToggleAktif then
            handleCommand(msg, sender, VIPCommands)
        end

        -- Games-only commands
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

-- 🔁 Apply listener ke semua pemain
for _, plr in ipairs(_G.BotVars.Players:GetPlayers()) do
    setupClient(plr)
end
_G.BotVars.Players.PlayerAdded:Connect(setupClient)

-- 🖥️ UI Setup
local GroupBox1 = Tabs.Main:AddLeftGroupbox("Bot Options")

GroupBox1:AddInput("BotIdentity", {
    Default = _G.BotVars.BotIdentity,
    Text = "Bot Identity",
    Placeholder = "Auto-detected bot info",
})

GroupBox1:AddToggle("AktifkanBot", {
    Text = "Enable Bot System (VIP only)",
    Default = false,
    Tooltip = "Enable to accept VIP chat commands (!ikuti, !stop, dll)",
    Callback = function(Value)
        _G.BotVars.ToggleAktif = Value
        debugPrint("ToggleAktif set to: " .. tostring(Value))
        Library:Notify("Bot System " .. (Value and "Enabled" or "Disabled"), 3)
    end,
})

GroupBox1:AddToggle("AktifkanGames", {
    Text = "Enable Game Commands",
    Default = false,
    Tooltip = "Enable to accept game-specific chat commands (!rockpaper, dll)",
    Callback = function(Value)
        _G.BotVars.ToggleGames = Value
        debugPrint("ToggleGames set to: " .. tostring(Value))
        Library:Notify("Game Commands " .. (Value and "Enabled" or "Disabled"), 3)
    end,
})

GroupBox1:AddInput("JarakIkutInput", {
    Default = tostring(_G.BotVars.JarakIkut),
    Text = "Follow Distance (VIP)",
    Placeholder = "Example: 5",
    Callback = function(Value) _G.BotVars.JarakIkut = tonumber(Value) end
})
GroupBox1:AddInput("FollowSpacingInput", {
    Default = tostring(_G.BotVars.FollowSpacing),
    Text = "Follow Spacing (Antar Bot)",
    Placeholder = "Example: 2",
    Callback = function(Value) _G.BotVars.FollowSpacing = tonumber(Value) end
})
GroupBox1:AddInput("ShieldDistanceInput", {
    Default = tostring(_G.BotVars.ShieldDistance),
    Text = "Shield Distance (VIP)",
    Placeholder = "Example: 5",
    Callback = function(Value) _G.BotVars.ShieldDistance = tonumber(Value) end
})
GroupBox1:AddInput("ShieldSpacingInput", {
    Default = tostring(_G.BotVars.ShieldSpacing),
    Text = "Shield Spacing (Rows)",
    Placeholder = "Example: 4",
    Callback = function(Value) _G.BotVars.ShieldSpacing = tonumber(Value) end
})
GroupBox1:AddInput("RowSpacingInput", {
    Default = tostring(_G.BotVars.RowSpacing),
    Text = "Row Spacing (Baris)",
    Placeholder = "Example: 4",
    Callback = function(Value) _G.BotVars.RowSpacing = tonumber(Value) end
})
GroupBox1:AddInput("SideSpacingInput", {
    Default = tostring(_G.BotVars.SideSpacing),
    Text = "Side Spacing (Kiri-Kanan)",
    Placeholder = "Example: 4",
    Callback = function(Value) _G.BotVars.SideSpacing = tonumber(Value) end
})

Library:Notify("✅ Bot System Loaded!", 3)
debugPrint("Bot.lua finished loading successfully")
