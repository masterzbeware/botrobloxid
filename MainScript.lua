-- ✅ Obsidian UI Setup
local repo = "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local Options = Library.Options

local Window = Library:CreateWindow({
    Title = "Made by MasterZ",
    Footer = "v11.0.0",
    Icon = 0,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Main = Window:AddTab("Main", "user")
}

-- ✅ Global Variables
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local clientName = "FiestaGuardVip"
local client = nil

-- ✅ State
local State = {
    jarakIkut = 5,
    followSpacing = 2,
    toggleAktif = false,
    followAllowed = false,
    currentFormasiTarget = nil,
    shieldActive = false,
    rowActive = false,
    shieldDistance = 5,
    shieldSpacing = 4,
    rowSpacing = 4,
    sideSpacing = 4,
    moving = false,
    humanoid = nil,
    myRootPart = nil,
}

-- ✅ Bot Mapping
local botMapping = {
    ["8802945328"] = "Bot1 - XBODYGUARDVIP01",
    ["8802949363"] = "Bot2 - XBODYGUARDVIP02",
    ["8802939883"] = "Bot3 - XBODYGUARDVIP03",
    ["8802998147"] = "Bot4 - XBODYGUARDVIP04",
}
local botIdentity = botMapping[tostring(localPlayer.UserId)] or "Unknown Bot"

-- ✅ Helpers
local function debugPrint(msg) print("[DEBUG]", msg) end

local function updateBotRefs()
    local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    State.humanoid = character:WaitForChild("Humanoid")
    State.myRootPart = character:WaitForChild("HumanoidRootPart")
    debugPrint("Bot references updated")
end

local function moveToPosition(targetPos, lookAtPos)
    if not State.humanoid or not State.myRootPart then return end
    if State.moving then return end
    if (State.myRootPart.Position - targetPos).Magnitude < 2 then return end

    State.moving = true
    State.humanoid:MoveTo(targetPos)
    State.humanoid.MoveToFinished:Wait()
    State.moving = false

    if lookAtPos then
        State.myRootPart.CFrame = CFrame.new(State.myRootPart.Position, Vector3.new(lookAtPos.X, State.myRootPart.Position.Y, lookAtPos.Z))
    end
end

-- ✅ UI Setup
local GroupBox1 = Tabs.Main:AddLeftGroupbox("Main Options")
GroupBox1:AddInput("BotIdentity", { Default = botIdentity, Text = "Bot Identity" })

GroupBox1:AddToggle("AktifkanFollow", {
    Text = "Enable Bot Follow",
    Default = false,
    Callback = function(Value)
        State.toggleAktif = Value
        if Value then
            Library:Notify("Bot Follow Enabled", 3)
            updateBotRefs()
        else
            Library:Notify("Bot Follow Disabled", 3)
            State.followAllowed, State.shieldActive, State.rowActive, State.currentFormasiTarget = false, false, false, nil
        end
    end,
})

GroupBox1:AddInput("JarakIkutInput", {
    Default = "5", Text = "Follow Distance (VIP)",
    Callback = function(Value) State.jarakIkut = tonumber(Value) or 5 end
})
GroupBox1:AddInput("FollowSpacingInput", {
    Default = "2", Text = "Follow Spacing",
    Callback = function(Value) State.followSpacing = tonumber(Value) or 2 end
})
GroupBox1:AddInput("ShieldDistanceInput", {
    Default = "5", Text = "Shield Distance",
    Callback = function(Value) State.shieldDistance = tonumber(Value) or 5 end
})
GroupBox1:AddInput("ShieldSpacingInput", {
    Default = "4", Text = "Shield Spacing",
    Callback = function(Value) State.shieldSpacing = tonumber(Value) or 4 end
})
GroupBox1:AddInput("RowSpacingInput", {
    Default = "4", Text = "Row Spacing",
    Callback = function(Value) State.rowSpacing = tonumber(Value) or 4 end
})
GroupBox1:AddInput("SideSpacingInput", {
    Default = "4", Text = "Side Spacing",
    Callback = function(Value) State.sideSpacing = tonumber(Value) or 4 end
})

-- ✅ Commands Loader (from raw GitHub)
local Commands = {}
local commandList = { "ikuti", "row", "shield" }

local function loadCommands()
    for _, cmdName in ipairs(commandList) do
        local ok, result = pcall(function()
            local url = repo .. "Commands/" .. cmdName .. ".lua"
            return loadstring(game:HttpGet(url))()
        end)
        if ok and result then
            Commands[cmdName:lower()] = result
            print("Loaded Command:", cmdName)
        else
            Commands[cmdName:lower()] = {
                execute = function() print(cmdName .. " not available") end
            }
            warn("Failed to load command:", cmdName, result)
        end
    end
end

loadCommands()

-- ✅ Chat Handler
local function handleCommand(msg)
    local split = string.split(msg, " ")
    local cmd = split[1]:sub(2):lower()
    table.remove(split, 1)

    local command = Commands[cmd]
    if command and command.execute then
        command.execute(split, {
            State = State,
            Players = Players,
            Client = client,
            LocalPlayer = localPlayer,
            Library = Library,
            ReplicatedStorage = ReplicatedStorage,
            moveToPosition = moveToPosition,
            botMapping = botMapping,
        })
    end
end

local function setupClient(player)
    if player.Name ~= clientName then return end
    client = player

    if TextChatService and TextChatService.TextChannels then
        local general = TextChatService.TextChannels.RBXGeneral
        if general then
            general.OnIncomingMessage = function(message)
                local senderUserId = message.TextSource and message.TextSource.UserId
                local sender = senderUserId and Players:GetPlayerByUserId(senderUserId)
                if sender and sender == client then
                    handleCommand(message.Text)
                end
            end
        end
    else
        player.Chatted:Connect(function(msg) handleCommand(msg) end)
    end
end

for _, plr in ipairs(Players:GetPlayers()) do setupClient(plr) end
Players.PlayerAdded:Connect(setupClient)
localPlayer.CharacterAdded:Connect(updateBotRefs)

-- ✅ Loop
RunService.Heartbeat:Connect(function()
    if not (State.toggleAktif and State.currentFormasiTarget and State.humanoid and State.myRootPart) then return end
    local targetHRP = State.currentFormasiTarget.Character and State.currentFormasiTarget.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end

    for name, command in pairs(Commands) do
        if command.run then
            command.run(State, localPlayer, targetHRP, moveToPosition, botMapping)
        end
    end
end)
