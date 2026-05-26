-- Commands/Follow.lua
-- Admin-only follow system (NORMAL MoveTo, straight line formation)
-- Supports: !follow / !follow <username|displayname>

return {
    Execute = function()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local TextChatService = game:GetService("TextChatService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local PathfindingService = game:GetService("PathfindingService")

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

local lastMoveTime = 0
local UPDATE_TIME = 0.15

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
-- SIMPLE PATHFINDING MOVE
----------------------------------------------------------------
local function smartMoveTo(targetPosition)
    if not humanoid or not myHRP then return end

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentCanClimb = true,
        WaypointSpacing = 3,
    })

    local success = pcall(function()
        path:ComputeAsync(myHRP.Position, targetPosition)
    end)

    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()

        if waypoints[2] then
            if waypoints[2].Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end

            humanoid:MoveTo(waypoints[2].Position)
        else
            humanoid:MoveTo(targetPosition)
        end
    else
        humanoid:MoveTo(targetPosition)
    end
end

        ----------------------------------------------------------------
        -- START FOLLOW
        ----------------------------------------------------------------
        local function startFollow(player)
            if not player then return end

            -- Jangan follow diri sendiri
            if player == LocalPlayer then
                stopFollow()
                return
            end

            stopFollow()

            following = true
            targetPlayer = player

            sendChat("Yes, Sir!")

            -- BOT ORDER dari depan ke belakang
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

            local myOrder = table.find(botOrder, tostring(LocalPlayer.UserId))
            local targetOrder = table.find(botOrder, tostring(player.UserId))

            local myIndex

            if myOrder and targetOrder then
                myIndex = myOrder - targetOrder
            else
                myIndex = myOrder or 1
            end

            -- Kalau posisi bot ini sebelum target, jangan follow
            if myIndex <= 0 then
                stopFollow()
                return
            end

            followConnection = RunService.Heartbeat:Connect(function()
                if not following or not humanoid or not myHRP then return end
                if not targetPlayer then return end
                if not targetPlayer.Character then return end

                local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

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

                -- Posisi lurus ke belakang target
local offset = hrp.CFrame.LookVector * -(distance * myIndex)
local targetPosition = hrp.Position + offset

local now = tick()

if now - lastMoveTime >= UPDATE_TIME then
    lastMoveTime = now
    smartMoveTo(targetPosition)
end
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

            -- !follow <name/displayname>
            local targetName = lower:match("^!follow%s+(.+)$")
            if targetName then
                local target = findPlayerByName(targetName)

                if target then
                    startFollow(target)
                end

                return
            end

            -- !stop / !unfollow
            if lower == "!stop" or lower == "!unfollow" then
                stopFollow()
                return
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