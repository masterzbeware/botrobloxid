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
            "10191476366", -- Bot1
            "10191480511", -- Bot2
            "10191462654", -- Bot3
            "10190853828", -- Bot4
            "10191023081", -- Bot5
            "10191070611", -- Bot6
            "10191489151", -- Bot7
            "10191571531", -- Bot8
            "10192469244", -- Bot9
            "10192474291", -- Bot10
            "10196485340", -- Bot11
            "10196526503", -- Bot12
        }

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

            local myIndex = table.find(botOrder, tostring(LocalPlayer.UserId)) or 1
            local totalBots = #botOrder
            local middleIndex = math.ceil(totalBots / 2)
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
