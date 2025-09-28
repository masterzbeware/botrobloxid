-- Bot.lua
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local Options = Library.Options

local Window = Library:CreateWindow({
    Title = "Made by MasterZ",
    Footer = "v16.0.0",
    Icon = 0,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = { Main = Window:AddTab("Main", "user") }

-- ✅ Global Variables
_G.BotVars = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    TextChatService = game:GetService("TextChatService"),
    LocalPlayer = game:GetService("Players").LocalPlayer,
    ClientName = "FiestaGuardVip",

    -- State
    JarakIkut = 5,
    FollowSpacing = 2,
    ShieldDistance = 5,
    ShieldSpacing = 4,
    RowSpacing = 4,
    SideSpacing = 4,

    ToggleAktif = false,
    FollowAllowed = false,
    ShieldActive = false,
    RowActive = false,
    CurrentFormasiTarget = nil,
}

-- ✅ Commands Loader
local Commands = {}
local commandFiles = { "Ikuti", "Stop", "Shield", "Row", "Sync" }

for _, file in ipairs(commandFiles) do
    local success, cmd = pcall(function()
        return loadfile("Commands/" .. file .. ".lua")()
    end)
    if success and type(cmd) == "table" then
        Commands[file:lower()] = cmd
    end
end

-- ✅ Handle Chat Commands
local function handleCommand(msg, client)
    msg = msg:lower()
    for name, cmd in pairs(Commands) do
        if msg:match("^!" .. name) and cmd.Execute then
            cmd.Execute(msg, client)
        end
    end
end

-- ✅ Setup client
local function setupClient(player)
    if player.Name ~= _G.BotVars.ClientName then return end
    local client = player

    if _G.BotVars.TextChatService and _G.BotVars.TextChatService.TextChannels then
        local generalChannel = _G.BotVars.TextChatService.TextChannels.RBXGeneral
        if generalChannel then
            generalChannel.OnIncomingMessage = function(message)
                local senderUserId = message.TextSource and message.TextSource.UserId
                local sender = senderUserId and _G.BotVars.Players:GetPlayerByUserId(senderUserId)
                if sender and sender == client then
                    handleCommand(message.Text, client)
                end
            end
        end
    else
        player.Chatted:Connect(function(msg)
            handleCommand(msg, client)
        end)
    end
end

for _, player in ipairs(_G.BotVars.Players:GetPlayers()) do
    setupClient(player)
end
_G.BotVars.Players.PlayerAdded:Connect(setupClient)

Library:Notify("Bot System Loaded!", 3)
