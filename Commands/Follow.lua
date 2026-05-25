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

        local waypoints = {}
local waypointIndex = 1
local lastPathTime = 0

local PATH_RECALC_TIME = 0.6
local WAYPOINT_DISTANCE = 4

local lastPosition = nil
local stuckTime = 0
local STUCK_LIMIT = 1.2

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
-- CHECK WALL BETWEEN BOT AND TARGET POSITION
----------------------------------------------------------------
local function hasWallBetween(targetPosition)
    if not myHRP then return false end

    -- Biar raycast tidak nembak ke lantai, kita samakan tinggi Y
    local startPos = myHRP.Position + Vector3.new(0, 2, 0)
    local endPos = Vector3.new(
        targetPosition.X,
        myHRP.Position.Y + 2,
        targetPosition.Z
    )

    local direction = endPos - startPos

    if direction.Magnitude <= 1 then
        return false
    end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local ignoreList = {}

    if LocalPlayer.Character then
        table.insert(ignoreList, LocalPlayer.Character)
    end

    if targetPlayer and targetPlayer.Character then
        table.insert(ignoreList, targetPlayer.Character)
    end

    rayParams.FilterDescendantsInstances = ignoreList

    local result = workspace:Raycast(startPos, direction, rayParams)

    if result and result.Instance then
        -- Kalau part tidak bisa ditabrak, jangan dianggap tembok
        if result.Instance:IsA("BasePart") and result.Instance.CanCollide == false then
            return false
        end

        -- Kalau yang kena terlalu dekat ke bawah, kemungkinan lantai
        if result.Position.Y < myHRP.Position.Y + 0.5 then
            return false
        end

        return true
    end

    return false
end

local function doUnstuckMove(targetPosition)
    if not humanoid or not myHRP then return end

    humanoid.Jump = true

    local right = myHRP.CFrame.RightVector
    local forward = myHRP.CFrame.LookVector

    local sideDirection

    if math.random(1, 2) == 1 then
        sideDirection = right
    else
        sideDirection = -right
    end

    local escapePosition =
        myHRP.Position
        + sideDirection * 6
        + forward * 3

    humanoid:MoveTo(escapePosition)

    task.delay(0.4, function()
        if humanoid and myHRP then
            humanoid:MoveTo(targetPosition)
        end
    end)
end

----------------------------------------------------------------
-- SMART MOVE WITH PATHFINDING
----------------------------------------------------------------
local function smartMoveTo(targetPosition)
    if not humanoid or not myHRP then return end

    ----------------------------------------------------------------
    -- CEK STUCK
    ----------------------------------------------------------------
    if lastPosition then
        local movedDistance = (myHRP.Position - lastPosition).Magnitude

        if movedDistance < 0.25 then
            stuckTime += RunService.Heartbeat:Wait()
        else
            stuckTime = 0
        end
    end

    lastPosition = myHRP.Position

    if stuckTime >= STUCK_LIMIT then
        stuckTime = 0
        waypoints = {}
        waypointIndex = 1
        doUnstuckMove(targetPosition)
        return
    end

    ----------------------------------------------------------------
    -- KALAU TARGET LEBIH TINGGI, COBA LOMPAT
    ----------------------------------------------------------------
    if targetPosition.Y - myHRP.Position.Y > 1.5 then
        humanoid.Jump = true
    end

    ----------------------------------------------------------------
    -- KALAU TIDAK ADA TEMBOK, JALAN LANGSUNG
    ----------------------------------------------------------------
    if not hasWallBetween(targetPosition) then
        waypoints = {}
        waypointIndex = 1
        humanoid:MoveTo(targetPosition)
        return
    end

    ----------------------------------------------------------------
    -- KALAU ADA TEMBOK, PAKAI PATHFINDING
    ----------------------------------------------------------------
    local now = tick()

    if now - lastPathTime >= PATH_RECALC_TIME then
        lastPathTime = now

        local path = PathfindingService:CreatePath({
            AgentRadius = 2,
            AgentHeight = 5,
            AgentCanJump = true,
            AgentCanClimb = true,
            WaypointSpacing = 4,
        })

        local success = pcall(function()
            path:ComputeAsync(myHRP.Position, targetPosition)
        end)

        if success and path.Status == Enum.PathStatus.Success then
            waypoints = path:GetWaypoints()
            waypointIndex = 2
        else
            -- Kalau path gagal, paksa keluar dari posisi stuck
            doUnstuckMove(targetPosition)
            return
        end
    end

    ----------------------------------------------------------------
    -- IKUTI WAYPOINT
    ----------------------------------------------------------------
    local waypoint = waypoints[waypointIndex]

    if waypoint then
        if (myHRP.Position - waypoint.Position).Magnitude <= WAYPOINT_DISTANCE then
            waypointIndex += 1
            waypoint = waypoints[waypointIndex]
        end

        if waypoint then
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end

            humanoid:MoveTo(waypoint.Position)
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

                smartMoveTo(targetPosition)
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