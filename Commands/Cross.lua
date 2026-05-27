-- Commands/Cross.lua
-- Admin-only follow system (CROSS FORMATION)
-- Supports: !cross / !cross <username|displayname>

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

        local adminFollowDistance = 3
        local defaultBotFollowDistance = 2

        -- Jarak antar bot dalam formasi cross
        local crossSpacing = 3

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
            "11007692539", -- Bot 9
            "11008102483", -- Bot 10
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
        -- SEND CHAT ONCE
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

        local username =
            p.Name:lower()

        local displayname =
            p.DisplayName:lower()

        ------------------------------------------------------------
        -- EXACT MATCH
        ------------------------------------------------------------
        if username == name
        or displayname == name then

            return p
        end

        ------------------------------------------------------------
        -- PARTIAL MATCH
        ------------------------------------------------------------
        if username:find(name, 1, true)
        or displayname:find(name, 1, true) then

            return p
        end
    end

    return nil
end

        ----------------------------------------------------------------
        -- START CROSS FOLLOW
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

                ----------------------------------------------------------------
                -- DISTANCE
                ----------------------------------------------------------------
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

                ----------------------------------------------------------------
                -- CROSS FORMATION
                ----------------------------------------------------------------
                local forward = hrp.CFrame.LookVector
                local right = hrp.CFrame.RightVector

                local targetPosition

                -- Urutan:
                -- Bot1  = depan VIP
                -- Bot2  = kiri VIP
                -- Bot3  = kanan VIP
                -- Bot4  = belakang VIP
                -- Bot5  = depan Bot1
                -- Bot6  = kiri Bot2
                -- Bot7  = kanan Bot3
                -- Bot8  = belakang Bot4
                -- Bot9  = depan Bot5
                -- Bot10 = kiri Bot6

                local directionIndex = ((myIndex - 1) % 4) + 1
                local layer = math.ceil(myIndex / 4)

                local offsetDistance = distance + (crossSpacing * (layer - 1))

                if directionIndex == 1 then
                    -- Depan
                    targetPosition =
                        hrp.Position
                        + forward * offsetDistance

                elseif directionIndex == 2 then
                    -- Kiri
                    targetPosition =
                        hrp.Position
                        - right * offsetDistance

                elseif directionIndex == 3 then
                    -- Kanan
                    targetPosition =
                        hrp.Position
                        + right * offsetDistance

                elseif directionIndex == 4 then
                    -- Belakang
                    targetPosition =
                        hrp.Position
                        - forward * offsetDistance
                end

                humanoid:MoveTo(targetPosition)
            end)
        end

        ----------------------------------------------------------------
        -- COMMAND HANDLER ADMIN ONLY
        ----------------------------------------------------------------
        local function handleCommand(msg, sender)
            if not Admin:IsAdmin(sender) then return end

            local lower = msg:lower()

            -- !cross
            if lower == "!cross" then
                startFollow(sender)
                return
            end

            -- !cross <name>
            local targetName = lower:match("^!cross%s+(.+)$")
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