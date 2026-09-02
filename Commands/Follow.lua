-- Commands/Follow.lua
-- Admin-only follow system (NORMAL MoveTo, straight line formation)
-- Supports: !follow / !follow <username|displayname>

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
        -- START FOLLOW
        ----------------------------------------------------------------
        local function startFollow(player)
            if not player then return end

            stopFollow()
            following = true
            targetPlayer = player
            sendChat("Yes, Sir!")

            -- BOT ORDER (FRONT → BACK)
local botOrder = {
    "11611503633", -- Bot 1
    "11611534165", -- Bot 2
    "11611567975", -- Bot 3
    "11611562042", -- Bot 4
    "11611591921", -- Bot 5
    "11122806815", -- Bot 6
    "11122806817", -- Bot 7
    "11122687468", -- Bot 8
    "11122854402", -- Bot 9
}


            local myIndex = table.find(botOrder, tostring(LocalPlayer.UserId)) or 1
followConnection = RunService.Heartbeat:Connect(function()
    if not following or not humanoid or not myHRP then
        return
    end

    if not targetPlayer.Character then
        return
    end

    local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end

    ------------------------------------------------------------
    -- FOLLOW DISTANCE
    ------------------------------------------------------------

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

    ------------------------------------------------------------
    -- FORMATION POSITION
    -- Bot 1 paling dekat dengan Admin
    -- Bot berikutnya berada di belakangnya
    ------------------------------------------------------------

    local offset = hrp.CFrame.LookVector * -(distance * myIndex)

    local targetPosition = hrp.Position + offset

    ------------------------------------------------------------
    -- MOVE BOT
    ------------------------------------------------------------

    humanoid:MoveTo(targetPosition)

    ------------------------------------------------------------
    -- MENGHADAP SEARAH DENGAN ADMIN
    ------------------------------------------------------------

    humanoid.AutoRotate = false

    local adminLookVector = hrp.CFrame.LookVector

    myHRP.CFrame = CFrame.lookAt(
        myHRP.Position,
        myHRP.Position + adminLookVector
    )
end)

        end

        ----------------------------------------------------------------
        -- COMMAND HANDLER
        ----------------------------------------------------------------
        local function handleCommand(msg, sender)
            if not Admin:IsAdmin(sender) then return end

            local lower = msg:lower()

            -- !follow
            if lower == "!follow" then
                startFollow(sender)
                return
            end

            
            -- !follow <name>
            local targetName = lower:match("^!follow%s+(.+)$")
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
