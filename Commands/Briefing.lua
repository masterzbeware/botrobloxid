-- Commands/Briefing.lua
-- Admin-only briefing formation system
-- Supports: !briefing / !briefing <username|displayname>
-- Konsep: bot baris di depan VIP/leader dan menghadap ke VIP/leader

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

        -- Jarak barisan dari depan VIP
        local adminFrontDistance = 6
        local defaultBotFrontDistance = 5

        -- Jarak antar bodyguard kiri-kanan
        local spacing = 3

        ----------------------------------------------------------------
        -- BOT ORDER
        ----------------------------------------------------------------
        local botOrder = {
    "11001608049", -- Bot 1
    "11001625681", -- Bot 2
    "11001647769", -- Bot 3
    "11002716767", -- Bot 4
    "11002763516", -- Bot 5
    "11002833908", -- Bot 6
    "11002919499", -- Bot 7
    "11002918670", -- Bot 8
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
        -- SEND CHAT
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
        -- FACE TARGET
        ----------------------------------------------------------------
        local function faceTarget(targetHRP)
            if not myHRP or not targetHRP then return end

            local lookPosition = Vector3.new(
                targetHRP.Position.X,
                myHRP.Position.Y,
                targetHRP.Position.Z
            )

            myHRP.CFrame = CFrame.lookAt(myHRP.Position, lookPosition)
        end

        ----------------------------------------------------------------
        -- STOP BRIEFING
        ----------------------------------------------------------------
        local function stopBriefing()
            positioning = false
            targetPlayer = nil
            hasChatted = false

            if humanoid then
                humanoid.AutoRotate = true
            end

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
-- START BRIEFING
----------------------------------------------------------------
local function startBriefing(player)
    if not player then return end

    stopBriefing()

    positioning = true
    targetPlayer = player

    local activeBotOrder = getActiveBotOrder()

    local myIndex = table.find(activeBotOrder, tostring(LocalPlayer.UserId))
    if not myIndex then
        return
    end

    ----------------------------------------------------------------
    -- BRIEFING GRID SETTINGS
    ----------------------------------------------------------------
    local columns = 3
    local horizontalSpacing = 3
    local rowSpacing = 3

    local zeroIndex = myIndex - 1
    local column = zeroIndex % columns
    local row = math.floor(zeroIndex / columns)

    -- Bot1 kiri, Bot2 tengah, Bot3 kanan
    -- Bot4 kiri, Bot5 tengah, Bot6 kanan
    -- Bot7 kiri, Bot8 tengah, Bot9 kanan
    local horizontalOffset = (column - 1) * horizontalSpacing

    if humanoid then
        humanoid.AutoRotate = false
    end

    followConnection = RunService.Heartbeat:Connect(function()
        if not positioning or not humanoid or not myHRP then return end
        if not targetPlayer.Character then return end

        local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        ----------------------------------------------------------------
        -- DISTANCE
        ----------------------------------------------------------------
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

        ----------------------------------------------------------------
        -- FINAL POSITION
        ----------------------------------------------------------------
        local targetPosition =
            hrp.Position
            + hrp.CFrame.LookVector * (distance + (row * rowSpacing))
            + hrp.CFrame.RightVector * horizontalOffset

        if not hasChatted then
            sendChat("Yes, Sir!")
            hasChatted = true
        end

        humanoid:MoveTo(targetPosition)

        ----------------------------------------------------------------
        -- ROTATE TO FACE VIP
        ----------------------------------------------------------------
        local distanceToPosition = (myHRP.Position - targetPosition).Magnitude

        if distanceToPosition <= 2.5 then
            faceTarget(hrp)
        end
    end)
end

        ----------------------------------------------------------------
        -- COMMAND HANDLER ADMIN ONLY
        ----------------------------------------------------------------
        local function handleCommand(msg, sender)
            if not Admin:IsAdmin(sender) then return end

            local lower = msg:lower()

            -- !briefing
            if lower == "!briefing" then
                startBriefing(sender)
                return
            end

            -- !briefing <name>
            local targetName = lower:match("^!briefing%s+(.+)$")
            if targetName then
                local target = findPlayerByName(targetName)

                if target then
                    startBriefing(target)
                end

                return
            end

            -- stop
            if lower == "!stop" or lower == "!unbriefing" then
                stopBriefing()
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