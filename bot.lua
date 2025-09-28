-- ✅ Obsidian UI Setup
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local Options = Library.Options

local Window = Library:CreateWindow({
    Title = "Made by MasterZ",
    Footer = "v13.0.0",
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

local localPlayer = Players.LocalPlayer
local clientName = "FiestaGuardVip"

local jarakIkut = 5
local followSpacing = 2
local shieldActive = false
local rowActive = false
local toggleAktif = false
local followAllowed = false
local currentFormasiTarget = nil

-- Shield/Row Config
local shieldDistance = 6
local shieldSpacing = 4
local shieldRowSpacing = 3

local rowFrontDistance = 6
local rowSpacing = 3
local rowSideSpacing = 4

local humanoid = nil
local myRootPart = nil
local client = nil
local followConnection = nil
local loopTask = nil

-- ✅ Bot Mapping
local botMapping = {
    ["8802945328"] = "Bot1 - XBODYGUARDVIP01",
    ["8802949363"] = "Bot2 - XBODYGUARDVIP02",
    ["8802939883"] = "Bot3 - XBODYGUARDVIP03",
    ["8802998147"] = "Bot4 - XBODYGUARDVIP04",
}
local botIdentity = botMapping[tostring(localPlayer.UserId)] or "Unknown Bot"

-- ✅ Helper Functions
local function debugPrint(msg)
    print("[DEBUG]", msg)
end

local function updateBotRefs()
    local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    humanoid = character:WaitForChild("Humanoid")
    myRootPart = character:WaitForChild("HumanoidRootPart")
    humanoid.AutoRotate = true -- biar otomatis menghadap target
    debugPrint("Bot references updated")
end

local function runStopCommand()
    followAllowed = false
    currentFormasiTarget = nil
    debugPrint("Follow stopped")
    Library:Notify("Bot Follow Stopped", 3)
end

-- ✅ FIX: Anti-stuck moveTo
local function moveToPosition(targetPos)
    if humanoid and myRootPart and targetPos then
        local dist = (myRootPart.Position - targetPos).Magnitude
        if dist > 2 then
            humanoid:MoveTo(targetPos)
        end
    end
end

-- ✅ UI - Main Tab
local GroupBox1 = Tabs.Main:AddLeftGroupbox("Main Options")

GroupBox1:AddInput("BotIdentity", {
    Default = botIdentity,
    Text = "Bot Identity",
    Placeholder = "Auto-detected bot info",
    Callback = function() end,
})

GroupBox1:AddToggle("AktifkanFollow", {
    Text = "Enable Bot Follow",
    Default = false,
    Tooltip = "Enable to accept !ikuti commands",
    Callback = function(Value)
        toggleAktif = Value
        if Value then
            Library:Notify("Bot Follow Enabled", 3)
            if followConnection then followConnection:Disconnect() end
            if loopTask then loopTask:Disconnect() end
            setupBotFollowSystem()
        else
            Library:Notify("Bot Follow Disabled", 3)
            runStopCommand()
            if loopTask then loopTask:Disconnect() end
            if followConnection then followConnection:Disconnect() end
        end
    end,
})

-- Inputs
GroupBox1:AddInput("JarakIkutInput", {
    Default = "5",
    Text = "Follow Distance",
    Placeholder = "Example: 5",
    Callback = function(Value)
        local number = tonumber(Value)
        if number then
            jarakIkut = number
            Library:Notify("Follow distance set to: "..number, 3)
        end
    end,
})

GroupBox1:AddInput("FollowSpacingInput", {
    Default = "2",
    Text = "Follow Spacing (Antar Bot)",
    Placeholder = "Example: 2",
    Callback = function(Value)
        local number = tonumber(Value)
        if number then
            followSpacing = number
            Library:Notify("Follow spacing set to: "..number, 3)
        end
    end,
})

-- Shield settings
GroupBox1:AddInput("ShieldDistanceInput", {
    Default = "6",
    Text = "Shield Distance",
    Callback = function(Value)
        local num = tonumber(Value)
        if num then shieldDistance = num end
    end,
})

GroupBox1:AddInput("ShieldSpacingInput", {
    Default = "4",
    Text = "Shield Side Spacing",
    Callback = function(Value)
        local num = tonumber(Value)
        if num then shieldSpacing = num end
    end,
})

GroupBox1:AddInput("ShieldRowSpacingInput", {
    Default = "3",
    Text = "Shield Row Spacing",
    Callback = function(Value)
        local num = tonumber(Value)
        if num then shieldRowSpacing = num end
    end,
})

-- Row settings
GroupBox1:AddInput("RowFrontDistanceInput", {
    Default = "6",
    Text = "Row Front Distance",
    Callback = function(Value)
        local num = tonumber(Value)
        if num then rowFrontDistance = num end
    end,
})

GroupBox1:AddInput("RowSpacingInput", {
    Default = "3",
    Text = "Row Spacing",
    Callback = function(Value)
        local num = tonumber(Value)
        if num then rowSpacing = num end
    end,
})

GroupBox1:AddInput("RowSideSpacingInput", {
    Default = "4",
    Text = "Row Side Spacing",
    Callback = function(Value)
        local num = tonumber(Value)
        if num then rowSideSpacing = num end
    end,
})

-- ✅ Follow System with Modes
function setupBotFollowSystem()
    updateBotRefs()

    local function handleCommand(msg)
        msg = msg:lower()
        if msg:match("^!ikuti") then
            followAllowed = true
            shieldActive = false
            rowActive = false
            currentFormasiTarget = client
            Library:Notify("Bot following main client: " .. client.DisplayName, 3)

        elseif msg:match("^!stop") then
            runStopCommand()
            shieldActive = false
            rowActive = false

        elseif msg:match("^!shield") then
            shieldActive = not shieldActive
            followAllowed = false
            rowActive = false
            Library:Notify("Shield formation " .. (shieldActive and "activated" or "deactivated"), 3)

        elseif msg:match("^!row") then
            rowActive = not rowActive
            followAllowed = false
            shieldActive = false
            Library:Notify("Row formation " .. (rowActive and "activated" or "deactivated"), 3)

        elseif msg:match("^!sync") then
            local args = {client}
            local rs = game:GetService("ReplicatedStorage")
            if rs:FindFirstChild("Events") and rs.Events:FindFirstChild("RequestSync") then
                rs.Events.RequestSync:FireServer(unpack(args))
                Library:Notify("RequestSync sent to: " .. client.DisplayName, 3)
            end
        end
    end

    local function setupClient(player)
        if player.Name ~= clientName then return end
        client = player
        if TextChatService and TextChatService.TextChannels then
            local generalChannel = TextChatService.TextChannels.RBXGeneral
            if generalChannel then
                generalChannel.OnIncomingMessage = function(message)
                    local senderUserId = message.TextSource and message.TextSource.UserId
                    local sender = senderUserId and Players:GetPlayerByUserId(senderUserId)
                    if sender and sender == client then
                        handleCommand(message.Text)
                    end
                end
            end
        else
            followConnection = player.Chatted:Connect(function(msg)
                handleCommand(msg)
            end)
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        setupClient(player)
    end
    Players.PlayerAdded:Connect(setupClient)
    localPlayer.CharacterAdded:Connect(updateBotRefs)

    loopTask = RunService.Heartbeat:Connect(function()
        if toggleAktif and currentFormasiTarget and currentFormasiTarget.Character and humanoid and myRootPart then
            local targetHRP = currentFormasiTarget.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                if shieldActive then
                    -- Shield Formation
                    local allBots = {}
                    for id, _ in pairs(botMapping) do
                        local p = Players:GetPlayerByUserId(tonumber(id))
                        if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                            table.insert(allBots, p)
                        end
                    end
                    table.sort(allBots, function(a,b) return a.UserId < b.UserId end)

                    local index = 1
                    for i, p in ipairs(allBots) do
                        if p == localPlayer then index = i break end
                    end

                    local middle = math.ceil(#allBots/2)
                    local offsetX = (index - middle) * shieldSpacing
                    local rowOffset = math.floor((index-1)/2) * shieldRowSpacing
                    local targetPos = targetHRP.Position + targetHRP.CFrame.RightVector * offsetX + targetHRP.CFrame.LookVector * (shieldDistance - rowOffset)
                    moveToPosition(targetPos)

                elseif rowActive then
                    -- Row Formation
                    local index
                    local ids = {}
                    for id,_ in pairs(botMapping) do table.insert(ids, tonumber(id)) end
                    table.sort(ids)
                    for i,id in ipairs(ids) do if id == localPlayer.UserId then index=i break end end

                    local targetPos
                    if index == 1 then
                        targetPos = targetHRP.Position + targetHRP.CFrame.RightVector * -rowSideSpacing + targetHRP.CFrame.LookVector * rowFrontDistance
                    elseif index == 2 then
                        targetPos = targetHRP.Position + targetHRP.CFrame.RightVector * rowSideSpacing + targetHRP.CFrame.LookVector * rowFrontDistance
                    elseif index == 3 then
                        targetPos = targetHRP.Position + targetHRP.CFrame.RightVector * -rowSideSpacing + targetHRP.CFrame.LookVector * (rowFrontDistance - rowSpacing)
                    elseif index == 4 then
                        targetPos = targetHRP.Position + targetHRP.CFrame.RightVector * rowSideSpacing + targetHRP.CFrame.LookVector * (rowFrontDistance - rowSpacing)
                    end
                    if targetPos then moveToPosition(targetPos) end

                elseif followAllowed then
                    -- Follow Formation
                    local botIds = {}
                    for id, _ in pairs(botMapping) do
                        table.insert(botIds, tonumber(id))
                    end
                    table.sort(botIds)

                    local index = 1
                    for i, id in ipairs(botIds) do
                        if id == localPlayer.UserId then index = i break end
                    end

                    local followPos = targetHRP.Position - targetHRP.CFrame.LookVector * (jarakIkut + (index-1)*followSpacing)
                    moveToPosition(followPos)
                end
            end
        end
    end)
end
