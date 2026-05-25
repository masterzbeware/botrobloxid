-- Commands/Frontline.lua
-- Admin-only frontline system
-- Supports: !frontline / !frontline <username|displayname>

return {
    Execute = function()
        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer
        if not LocalPlayer then return end

        ----------------------------------------------------------------
        -- LOAD MODULES
        ----------------------------------------------------------------
        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        local Distance = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
        ))()

        ----------------------------------------------------------------
        -- STATE
        ----------------------------------------------------------------
        local positioning = false
        local targetPlayer
        local followConnection
        local humanoid, myHRP
        local hasChatted = false

        local adminFrontDistance = 3
        local defaultBotFrontDistance = 2
        local spacing = 3

        ----------------------------------------------------------------
        -- BOT ORDER (TINGGAL TAMBAH ID)
        ----------------------------------------------------------------
        local botOrder = {
    "11001607521", -- Bot 1
    "11001608049", -- Bot 2
    "11001625681", -- Bot 3
    "11001647769", -- Bot 4
    "11002716767", -- Bot 5
    "11002763516", -- Bot 6
    "11002833908", -- Bot 7
    "11002919499", -- Bot 8
    "11002918670", -- Bot 9
        }

        local function getActiveBotOrder()
    local activeBots = {}

    for _, userId in ipairs(botOrder) do
        local player = Players:GetPlayerByUserId(tonumber(userId))

        if player then
            table.insert(activeBots, userId)
        end
    end

    return activeBots
end

        ----------------------------------------------------------------
        -- UPDATE CHARACTER
        ----------------------------------------------------------------
        local function updateCharacter()
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            humanoid = char:WaitForChild("Humanoid")
            myHRP = char:WaitForChild("HumanoidRootPart")
        end
        updateCharacter()
        LocalPlayer.CharacterAdded:Connect(updateCharacter)

        ----------------------------------------------------------------
        -- SEND CHAT (ONCE)
        ----------------------------------------------------------------
        local function sendChat(msg)
            pcall(function()
                if TextChatService and TextChatService.TextChannels then
                    local ch = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
                    if ch then
                        ch:SendAsync(msg)
                        return
                    end
                end
                ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest
                    :FireServer(msg, "All")
            end)
        end

        ----------------------------------------------------------------
        -- STOP FRONTLINE
        ----------------------------------------------------------------
        local function stopFrontline()
            positioning = false
            targetPlayer = nil
            hasChatted = false

            if followConnection then
                followConnection:Disconnect()
                followConnection = nil
            end
        end

        ----------------------------------------------------------------
        -- FIND PLAYER BY NAME / DISPLAY NAME
        ----------------------------------------------------------------
        local function findPlayerByName(name)
            name = name:lower()
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Name:lower() == name or p.DisplayName:lower() == name then
                    return p
                end
            end
            return nil
        end

        ----------------------------------------------------------------
        -- START FRONTLINE
        ----------------------------------------------------------------
local function startFrontline(player)
    if not player then return end

    stopFrontline()
    positioning = true
    targetPlayer = player

    local activeBotOrder = getActiveBotOrder()

    local myIndex = table.find(activeBotOrder, tostring(LocalPlayer.UserId))
    if not myIndex then
        return
    end

    local totalBots = #activeBotOrder
    local middleIndex = (totalBots + 1) / 2
    local horizontalOffset = (myIndex - middleIndex) * spacing

    followConnection = RunService.Heartbeat:Connect(function()
        if not positioning or not humanoid or not myHRP then return end
        if not targetPlayer.Character then return end

        local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        -- DISTANCE
        local distance = defaultBotFrontDistance

        if Admin:IsAdmin(targetPlayer) then
            distance = adminFrontDistance
        end

        local special = Distance:GetDistance(
            tostring(LocalPlayer.UserId),
            tostring(targetPlayer.UserId)
        )

        if special then
            distance = special
        end

        -- FINAL POSITION
        local targetPosition =
            hrp.Position
            + hrp.CFrame.LookVector * distance
            + hrp.CFrame.RightVector * horizontalOffset

        if not hasChatted then
            sendChat("Yes, Sir!")
            hasChatted = true
        end

        humanoid:MoveTo(targetPosition)
    end)
end

        ----------------------------------------------------------------
        -- COMMAND HANDLER (ADMIN ONLY)
        ----------------------------------------------------------------
        local function handleCommand(msg, sender)
            if not Admin:IsAdmin(sender) then return end

            local lower = msg:lower()

            -- !frontline
            if lower == "!frontline" then
                startFrontline(sender)
                return
            end

            -- !frontline <name>
            local targetName = lower:match("^!frontline%s+(.+)$")
            if targetName then
                local target = findPlayerByName(targetName)
                if target then
                    startFrontline(target)
                end
                return
            end

            -- stop
            if lower == "!stop" or lower == "!unfrontline" then
                stopFrontline()
            end
        end

        ----------------------------------------------------------------
        -- TEXT CHAT SERVICE
        ----------------------------------------------------------------
        if TextChatService and TextChatService.TextChannels then
            local ch = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if ch then
                ch.OnIncomingMessage = function(message)
                    local uid = message.TextSource and message.TextSource.UserId
                    local sender = uid and Players:GetPlayerByUserId(uid)
                    if sender then
                        handleCommand(message.Text, sender)
                    end
                end
            end
        end

        ----------------------------------------------------------------
        -- FALLBACK CHAT
        ----------------------------------------------------------------
        for _, p in ipairs(Players:GetPlayers()) do
            p.Chatted:Connect(function(msg)
                handleCommand(msg, p)
            end)
        end

        Players.PlayerAdded:Connect(function(p)
            p.Chatted:Connect(function(msg)
                handleCommand(msg, p)
            end)
        end)
    end
}
