-- ✅ Obsidian UI Setup
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
local toggleAktif = false
local followAllowed = false
local currentFormasiTarget = nil
local shieldActive = false
local rowActive = false

-- Tambahan variabel shield & row
local shieldDistance = 5   -- jarak bot dengan VIP
local shieldSpacing = 4    -- jarak antar bot (samping)
local rowSpacing = 4       -- jarak antar baris
local sideSpacing = 4      -- jarak antar bot kiri-kanan

local followConnection = nil
local humanoid = nil
local myRootPart = nil
local client = nil
local moving = false

-- ✅ Bot Mapping
local botMapping = {
    ["8802945328"] = "Bot1 - XBODYGUARDVIP01",
    ["8802949363"] = "Bot2 - XBODYGUARDVIP02",
    ["8802939883"] = "Bot3 - XBODYGUARDVIP03",
    ["8802998147"] = "Bot4 - XBODYGUARDVIP04",
}
local botIdentity = botMapping[tostring(localPlayer.UserId)] or "Unknown Bot"

-- ✅ Helper Functions
local function debugPrint(msg) print("[DEBUG]", msg) end

local function updateBotRefs()
    local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    humanoid = character:WaitForChild("Humanoid")
    myRootPart = character:WaitForChild("HumanoidRootPart")
    debugPrint("Bot references updated")
end

local function runStopCommand()
    followAllowed = false
    shieldActive = false
    rowActive = false
    currentFormasiTarget = nil
    moving = false
    debugPrint("Follow stopped")
    Library:Notify("Bot Follow Stopped", 3)
end

-- ✅ UI
local GroupBox1 = Tabs.Main:AddLeftGroupbox("Main Options")

GroupBox1:AddInput("BotIdentity", {
    Default = botIdentity,
    Text = "Bot Identity",
    Placeholder = "Auto-detected bot info",
})

GroupBox1:AddToggle("AktifkanFollow", {
    Text = "Enable Bot Follow",
    Default = false,
    Tooltip = "Enable to accept !ikuti commands",
    Callback = function(Value)
        toggleAktif = Value
        debugPrint("ToggleAktif set to: "..tostring(Value))
        if Value then
            Library:Notify("Bot Follow Enabled", 3)
            if followConnection then followConnection:Disconnect() end
            setupBotFollowSystem()
        else
            Library:Notify("Bot Follow Disabled", 3)
            runStopCommand()
            if followConnection then followConnection:Disconnect() end
        end
    end,
})

GroupBox1:AddInput("JarakIkutInput", {
    Default = "5",
    Text = "Follow Distance (VIP)",
    Placeholder = "Example: 5",
    Callback = function(Value)
        local number = tonumber(Value)
        if number then
            jarakIkut = number
            debugPrint("Follow distance set to: "..number)
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
            debugPrint("Follow spacing set to: "..number)
            Library:Notify("Follow spacing set to: "..number, 3)
        end
    end,
})

GroupBox1:AddInput("ShieldDistanceInput", {
    Default = "5",
    Text = "Shield Distance (VIP)",
    Placeholder = "Example: 5",
    Callback = function(Value)
        local number = tonumber(Value)
        if number then
            shieldDistance = number
            debugPrint("Shield distance set to: "..number)
            Library:Notify("Shield distance set to: "..number, 3)
        end
    end,
})

GroupBox1:AddInput("ShieldSpacingInput", {
    Default = "4",
    Text = "Shield Spacing (Rows)",
    Placeholder = "Example: 4",
    Callback = function(Value)
        local number = tonumber(Value)
        if number then
            shieldSpacing = number
            debugPrint("Shield spacing set to: "..number)
            Library:Notify("Shield spacing set to: "..number, 3)
        end
    end,
})

GroupBox1:AddInput("RowSpacingInput", {
    Default = "4",
    Text = "Row Spacing (Baris)",
    Placeholder = "Example: 4",
    Callback = function(Value)
        local number = tonumber(Value)
        if number then
            rowSpacing = number
            debugPrint("Row spacing set to: "..number)
            Library:Notify("Row spacing set to: "..number, 3)
        end
    end,
})

GroupBox1:AddInput("SideSpacingInput", {
    Default = "4",
    Text = "Side Spacing (Kiri-Kanan)",
    Placeholder = "Example: 4",
    Callback = function(Value)
        local number = tonumber(Value)
        if number then
            sideSpacing = number
            debugPrint("Side spacing set to: "..number)
            Library:Notify("Side spacing set to: "..number, 3)
        end
    end,
})

-- ✅ MoveTo wrapper
local function moveToPosition(targetPos, lookAtPos)
    if not humanoid or not myRootPart then return end
    if moving then return end
    if (myRootPart.Position - targetPos).Magnitude < 2 then return end

    moving = true
    humanoid:MoveTo(targetPos)
    humanoid.MoveToFinished:Wait()
    moving = false

    if lookAtPos then
        myRootPart.CFrame = CFrame.new(myRootPart.Position, Vector3.new(lookAtPos.X, myRootPart.Position.Y, lookAtPos.Z))
    end
end

-- ✅ Follow System with Shield & Row & Sync
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
            local targetName = msg:match("^!sync%s+(.+)")
            if targetName then
                local found = nil
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr.DisplayName:lower() == targetName or plr.Name:lower() == targetName then
                        found = plr
                        break
                    end
                end
                if found then
                    local args = { found }
                    game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("RequestSync"):FireServer(unpack(args))
                    Library:Notify("Synced with " .. found.DisplayName, 3)
                else
                    Library:Notify("Player not found: " .. targetName, 3)
                end
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

    -- Loop
    RunService.Heartbeat:Connect(function()
        if toggleAktif and currentFormasiTarget and currentFormasiTarget.Character and humanoid and myRootPart then
            local targetHRP = currentFormasiTarget.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                -- Shield Mode
                if shieldActive then
                    local botIds = {}
                    for id, _ in pairs(botMapping) do
                        table.insert(botIds, tonumber(id))
                    end
                    table.sort(botIds)

                    local index = 1
                    for i, id in ipairs(botIds) do
                        if id == localPlayer.UserId then index = i break end
                    end

                    local targetPos
                    if index == 1 then
                        targetPos = targetHRP.Position + targetHRP.CFrame.LookVector * shieldDistance
                    elseif index == 2 then
                        targetPos = targetHRP.Position - targetHRP.CFrame.RightVector * shieldDistance
                    elseif index == 3 then
                        targetPos = targetHRP.Position + targetHRP.CFrame.RightVector * shieldDistance
                    elseif index == 4 then
                        targetPos = targetHRP.Position - targetHRP.CFrame.LookVector * shieldDistance
                    end

                    if targetPos then
                        moveToPosition(targetPos, targetHRP.Position + targetHRP.CFrame.LookVector * 50)
                    end

                -- Row Mode
                elseif rowActive then
                    local botIds = {}
                    for id, _ in pairs(botMapping) do
                        table.insert(botIds, tonumber(id))
                    end
                    table.sort(botIds)

                    local index = 1
                    for i, id in ipairs(botIds) do
                        if id == localPlayer.UserId then index = i break end
                    end

                    local targetPos
                    if index == 1 then
                        targetPos = targetHRP.Position - targetHRP.CFrame.LookVector * jarakIkut 
                                    - targetHRP.CFrame.RightVector * sideSpacing
                    elseif index == 2 then
                        targetPos = targetHRP.Position - targetHRP.CFrame.LookVector * jarakIkut 
                                    + targetHRP.CFrame.RightVector * sideSpacing
                    elseif index == 3 then
                        targetPos = targetHRP.Position - targetHRP.CFrame.LookVector * (jarakIkut + rowSpacing) 
                                    - targetHRP.CFrame.RightVector * sideSpacing
                    elseif index == 4 then
                        targetPos = targetHRP.Position - targetHRP.CFrame.LookVector * (jarakIkut + rowSpacing) 
                                    + targetHRP.CFrame.RightVector * sideSpacing
                    end

                    if targetPos then
                        moveToPosition(targetPos, targetHRP.Position) -- menghadap VIP
                    end

                -- Follow Mode
                elseif followAllowed then
                    local botIds = {}
                    for id, _ in pairs(botMapping) do
                        table.insert(botIds, tonumber(id))
                    end
                    table.sort(botIds)

                    local index = 1
                    for i, id in ipairs(botIds) do
                        if id == localPlayer.UserId then
                            index = i
                            break
                        end
                    end

                    local followPos = targetHRP.Position - targetHRP.CFrame.LookVector * (jarakIkut + (index - 1) * followSpacing)
                    moveToPosition(followPos, targetHRP.Position)
                end
            end
        end
    end)
end
