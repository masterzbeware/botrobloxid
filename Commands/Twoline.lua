-- Commands/Twoline.lua
-- Admin-only follow system (TWO LINE formation)
-- Supports: !twoline / !twoline <username|displayname>

return {
    Execute = function()
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer
        if not LocalPlayer then return end

        -- LOAD ADMIN MODULE
        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        -- LOAD DISTANCE MODULE
        local Distance = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
        ))()

        local humanoid, myHRP
        local following = false
        local targetPlayer
        local followConnection

        local adminFollowDistance = 3
        local defaultBotFollowDistance = 2
        local sideSpacing = 2.5

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
            local ok = false
            if TextChatService and TextChatService.TextChannels then
                local ch = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
                if ch then
                    pcall(function()
                        ch:SendAsync(msg)
                    end)
                    ok = true
                end
            end
            if not ok then
                pcall(function()
                    ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest
                        :FireServer(msg, "All")
                end)
            end
        end

        ----------------------------------------------------------------
        -- STOP FOLLOW
        ----------------------------------------------------------------
        local function stopFollow()
            following = false
            targetPlayer = nil
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
        -- START TWOLINE FOLLOW
        ----------------------------------------------------------------
        local function startFollow(player)
            if not player then return end

            stopFollow()
            following = true
            targetPlayer = player
            sendChat("Yes, Sir!")

            -- BOT ORDER
            local botOrder = {
                "10191476366",
                "10191480511",
                "10191462654",
                "10190853828",
                "10191023081",
                "10191070611",
                "10191489151",
                "10191571531",
                "10192469244",
                "10192474291",
                "10196485340",
                "10196526503",
            }

            local myIndex = table.find(botOrder, tostring(LocalPlayer.UserId))
            if not myIndex then return end

            followConnection = RunService.Heartbeat:Connect(function()
                if not following or not humanoid or not myHRP then return end
                if not targetPlayer.Character then return end

                local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                -- DISTANCE
                local distance = defaultBotFollowDistance
                if Admin:IsAdmin(targetPlayer) then
                    distance = adminFollowDistance
                end

                local special = Distance:GetDistance(
                    tostring(LocalPlayer.UserId),
                    tostring(targetPlayer.UserId)
                )
                if special then
                    distance = special
                end

                -- FORMATION (LEFT / RIGHT)
                local half = math.ceil(#botOrder / 2)
                local isLeft = myIndex <= half
                local lineIndex = isLeft and myIndex or (myIndex - half)

                local backOffset = hrp.CFrame.LookVector * -(distance * lineIndex)
                local sideDir = isLeft and -hrp.CFrame.RightVector or hrp.CFrame.RightVector
                local sideOffset = sideDir * sideSpacing

                local targetPosition = hrp.Position + backOffset + sideOffset
                humanoid:MoveTo(targetPosition)
            end)
        end

        ----------------------------------------------------------------
        -- COMMAND HANDLER (ADMIN ONLY)
        ----------------------------------------------------------------
        local function handleCommand(msg, sender)
            if not Admin:IsAdmin(sender) then return end

            local lower = msg:lower()

            -- !twoline
            if lower == "!twoline" then
                startFollow(sender)
                return
            end

            -- !twoline <name>
            local targetName = lower:match("^!twoline%s+(.+)$")
            if targetName then
                local target = findPlayerByName(targetName)
                if target then
                    startFollow(target)
                else
                    sendChat("Target not found.")
                end
                return
            end

            -- stop
            if lower == "!stop" or lower == "!unfollow" then
                stopFollow()
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
