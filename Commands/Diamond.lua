-- Commands/Diamond.lua
-- Admin-only follow system (DIAMOND + TWOLINE)
-- Supports: !diamond / !diamond <username|displayname>

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
        local humanoid, myHRP
        local following = false
        local targetPlayer
        local followConnection
        local hasChatted = false

        local adminFollowDistance = 3
        local defaultBotFollowDistance = 2
        local sideSpacing = 3

        ----------------------------------------------------------------
        -- BOT ORDER (TINGGAL TAMBAH ID)
        ----------------------------------------------------------------
        local botOrder = {
            "10191476366", -- Bot1 (Front)
            "10191480511", -- Bot2 (Right)
            "10191462654", -- Bot3 (Left)
            "10190853828", -- Bot4 (Back)
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
        -- STOP FOLLOW
        ----------------------------------------------------------------
        local function stopFollow()
            following = false
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
        -- START DIAMOND FOLLOW
        ----------------------------------------------------------------
        local function startFollow(player)
            if not player then return end

            stopFollow()
            following = true
            targetPlayer = player

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

                local targetPosition

                ----------------------------------------------------------------
                -- DIAMOND CORE (BOT 1–4)
                ----------------------------------------------------------------
                if myIndex == 1 then
                    -- FRONT
                    targetPosition = hrp.Position + hrp.CFrame.LookVector * distance

                elseif myIndex == 2 then
                    -- RIGHT
                    targetPosition = hrp.Position + hrp.CFrame.RightVector * sideSpacing

                elseif myIndex == 3 then
                    -- LEFT
                    targetPosition = hrp.Position - hrp.CFrame.RightVector * sideSpacing

                elseif myIndex == 4 then
                    -- BACK
                    targetPosition = hrp.Position - hrp.CFrame.LookVector * distance

                else
                    ----------------------------------------------------------------
                    -- TWOLINE BACK (BOT 5+)
                    ----------------------------------------------------------------
                    local twolineIndex = myIndex - 4
                    local isLeft = twolineIndex % 2 == 1
                    local lineIndex = math.ceil(twolineIndex / 2)

                    local backOffset =
                        hrp.CFrame.LookVector * -(distance * (lineIndex + 1))

                    local sideDir =
                        isLeft and -hrp.CFrame.RightVector or hrp.CFrame.RightVector

                    local sideOffset = sideDir * sideSpacing

                    targetPosition = hrp.Position + backOffset + sideOffset
                end

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

            -- !diamond
            if lower == "!diamond" then
                startFollow(sender)
                return
            end

            -- !diamond <name>
            local targetName = lower:match("^!diamond%s+(.+)$")
            if targetName then
                local target = findPlayerByName(targetName)
                if target then
                    startFollow(target)
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
