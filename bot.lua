-- ✅ Obsidian UI Setup
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()

local Options = Library.Options

local Window = Library:CreateWindow({
    Title = "Made by MasterZ",
    Footer = "v2.0.0",
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
local toggleAktif = false
local followAllowed = false
local currentFormasiTarget = nil
local shieldActive = false

local followConnection = nil
local humanoid = nil
local myRootPart = nil
local client = nil
local moving = false -- flag agar tidak spam MoveTo

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
    debugPrint("Bot references updated")
end

-- ✅ Reset function
local function runStopCommand()
    followAllowed = false
    currentFormasiTarget = nil
    moving = false
    debugPrint("Follow stopped")
    Library:Notify("Bot Follow Stopped", 3)
end

-- ✅ UI - Main Tab
local GroupBox1 = Tabs.Main:AddLeftGroupbox("Main Options")

GroupBox1:AddInput("BotIdentity", {
    Default = botIdentity,
    Text = "Bot Identity",
    Placeholder = "Auto-detected bot info",
    Callback = function(Value) end, -- readonly
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
    Text = "Follow Distance",
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

-- ✅ MoveTo wrapper (biar ga spam tiap frame)
local function moveToPosition(targetPos, lookAtPos)
    if not humanoid or not myRootPart then return end
    if moving then return end -- lagi jalan, skip
    if (myRootPart.Position - targetPos).Magnitude < 2 then return end -- terlalu dekat, skip

    moving = true
    humanoid:MoveTo(targetPos)
    humanoid.MoveToFinished:Wait()
    moving = false

    -- Rotasi ke arah target
    if lookAtPos then
        myRootPart.CFrame = CFrame.new(myRootPart.Position, Vector3.new(lookAtPos.X, myRootPart.Position.Y, lookAtPos.Z))
    end
end

-- ✅ Follow System with Shield
function setupBotFollowSystem()
    updateBotRefs()

    local function handleCommand(msg)
        msg = msg:lower()
        if msg:match("^!ikuti") then
            followAllowed = true
            shieldActive = false
            currentFormasiTarget = client
            Library:Notify("Bot following main client: " .. client.DisplayName, 3)
            debugPrint("Follow started for "..client.DisplayName)
        elseif msg:match("^!stop") then
            runStopCommand()
            shieldActive = false
        elseif msg:match("^!shield") then
            shieldActive = not shieldActive
            followAllowed = false
            Library:Notify("Shield formation " .. (shieldActive and "activated" or "deactivated"), 3)
            debugPrint("ShieldActive: "..tostring(shieldActive))
        end
    end

    local function setupClient(player)
        if player.Name ~= clientName then return end
        client = player
        debugPrint("Client "..player.Name.." setup complete")

        if TextChatService and TextChatService.TextChannels then
            local generalChannel = TextChatService.TextChannels.RBXGeneral
            if generalChannel then
                generalChannel.OnIncomingMessage = function(message)
                    local senderUserId = message.TextSource and message.TextSource.UserId
                    local sender = senderUserId and Players:GetPlayerByUserId(senderUserId)
                    if sender and sender == client then
                        debugPrint("Received chat from "..sender.Name..": "..message.Text)
                        handleCommand(message.Text)
                    end
                end
            end
        else
            followConnection = player.Chatted:Connect(function(msg)
                debugPrint("Received chat from "..player.Name..": "..msg)
                handleCommand(msg)
            end)
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        setupClient(player)
    end
    Players.PlayerAdded:Connect(setupClient)
    localPlayer.CharacterAdded:Connect(updateBotRefs)

    -- Loop cek posisi
    RunService.Heartbeat:Connect(function()
        if toggleAktif and currentFormasiTarget and currentFormasiTarget.Character and humanoid and myRootPart then
            local targetHRP = currentFormasiTarget.Character:FindFirstChild("HumanoidRootPart")
            if targetHRP then
                if shieldActive then
                    local allBots = {}
                    for id, _ in pairs(botMapping) do
                        local p = Players:GetPlayerByUserId(tonumber(id))
                        if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                            table.insert(allBots, p)
                        end
                    end
                    table.sort(allBots, function(a,b) return a.UserId < b.UserId end)

                    local totalBots = #allBots
                    local spacing = 2
                    local index = 1
                    for i, p in ipairs(allBots) do
                        if p == localPlayer then
                            index = i
                            break
                        end
                    end

                    local middle = math.ceil(totalBots/2)
                    local offsetX = (index - middle) * spacing
                    local targetPos = targetHRP.Position + targetHRP.CFrame.RightVector * offsetX - targetHRP.CFrame.LookVector * spacing
                    moveToPosition(targetPos, targetHRP.Position)

                elseif followAllowed then
                    local followPos = targetHRP.Position - targetHRP.CFrame.LookVector * jarakIkut
                    moveToPosition(followPos, targetHRP.Position)
                end
            end
        end
    end)
end
