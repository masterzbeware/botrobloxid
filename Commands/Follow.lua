-- Commands/Follow.lua
-- Admin-only follow system (NORMAL MoveTo, straight line formation)

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

        -- UPDATE CHARACTER
        local function updateCharacter()
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            humanoid = char:WaitForChild("Humanoid")
            myHRP = char:WaitForChild("HumanoidRootPart")
        end
        updateCharacter()
        LocalPlayer.CharacterAdded:Connect(updateCharacter)

        -- SEND CHAT (ONCE)
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

        -- STOP FOLLOW
        local function stopFollow()
            following = false
            targetPlayer = nil
            if followConnection then
                followConnection:Disconnect()
                followConnection = nil
            end
        end

        -- START FOLLOW
        local function startFollow(player)
            stopFollow()
            following = true
            targetPlayer = player
            sendChat("Yes, Sir!")

            -- BOT ORDER (FRONT → BACK)
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
            }

            local myIndex = table.find(botOrder, tostring(LocalPlayer.UserId)) or 1

            followConnection = RunService.Heartbeat:Connect(function()
                if not following or not humanoid or not myHRP then return end
                if not targetPlayer.Character then return end

                local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                -- FOLLOW DISTANCE
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

                -- STRAIGHT LINE POSITION (NO CFRAME SET)
                local offset = hrp.CFrame.LookVector * -(distance * myIndex)
                local targetPosition = hrp.Position + offset

                -- MOVE LIKE NORMAL PLAYER
                humanoid:MoveTo(targetPosition)
            end)
        end

        -- COMMAND HANDLER
        local function handleCommand(msg, sender)
            msg = msg:lower()
            if Admin:IsAdmin(sender) then
                if msg == "!follow" then
                    startFollow(sender)
                elseif msg == "!stop" or msg == "!unfollow" then
                    stopFollow()
                end
            end
        end

        -- TEXT CHAT SERVICE
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

        -- FALLBACK CHAT
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
