-- Commands/Follow.lua
-- Admin-only follow system with Pathfinding
-- Supports: !follow / !follow <username|displayname>

return {
    Execute = function()
        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local PathfindingService = game:GetService("PathfindingService")

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

        local currentWaypoints = {}
        local currentWaypointIndex = 2
        local currentTargetPosition = nil
        local lastPathTime = 0

        local lastPosition = nil
        local stuckTime = 0
        local lastUnstuckTime = 0

        ----------------------------------------------------------------
        -- SETTINGS
        ----------------------------------------------------------------
        local adminFollowDistance = 3
        local defaultBotFollowDistance = 2

        local PATH_UPDATE_TIME = 0.8
        local WAYPOINT_REACH_DISTANCE = 3
        local TARGET_REPATH_DISTANCE = 5

        local STUCK_LIMIT = 1.5
        local UNSTUCK_COOLDOWN = 2

        ----------------------------------------------------------------
        -- BOT ORDER
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

        local stairFolders = {
    workspace:FindFirstChild("Detectors")
        and workspace.Detectors:FindFirstChild("Stage"),

    workspace:FindFirstChild("New")
        and workspace.New:FindFirstChild("Salon")
        and workspace.New.Salon:FindFirstChild("scenario"),
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

        LocalPlayer.CharacterAdded:Connect(function()
            task.wait(1)
            updateCharacter()
        end)

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
        -- RESET PATH
        ----------------------------------------------------------------
        local function resetPath()
            currentWaypoints = {}
            currentWaypointIndex = 2
            currentTargetPosition = nil
            lastPathTime = 0
        end

        ----------------------------------------------------------------
        -- STOP FOLLOW
        ----------------------------------------------------------------
        local function stopFollow()
            following = false
            targetPlayer = nil
            resetPath()

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
                local playerName = p.Name:lower()
                local displayName = p.DisplayName:lower()

                if playerName == name or displayName == name then
                    return p
                end

                if playerName:sub(1, #name) == name or displayName:sub(1, #name) == name then
                    return p
                end
            end

            return nil
        end

        ----------------------------------------------------------------
        -- GET FOLLOW TARGET POSITION
        ----------------------------------------------------------------
local function getFollowTargetPosition(hrp, distance, myIndex)
    local offset = hrp.CFrame.LookVector * -(distance * myIndex)
    local targetPosition = hrp.Position + offset

    -- Kalau target/admin lebih tinggi, cari tangga dulu
    if myHRP and hrp.Position.Y - myHRP.Position.Y > 1.5 then
        local stairPart = getNearestStairPart(hrp.Position.Y)

        if stairPart then
            return stairPart.Position + Vector3.new(0, 2, 0)
        end

        -- fallback kalau tangga tidak ketemu
        return hrp.Position
    end

    return targetPosition
end

----------------------------------------------------------------
-- FIND NEAREST STAIR PART
----------------------------------------------------------------
local function getNearestStairPart(targetY)
    if not myHRP then return nil end

    local nearestPart = nil
    local nearestDistance = math.huge

    for _, folder in ipairs(stairFolders) do
        if folder then
            for _, obj in ipairs(folder:GetDescendants()) do
                if obj:IsA("BasePart") and obj.CanCollide == true then
                    -- Ambil part yang posisinya menuju ke atas
                    if obj.Position.Y > myHRP.Position.Y + 0.5
                        and obj.Position.Y <= targetY + 5
                    then
                        local distance = (myHRP.Position - obj.Position).Magnitude

                        if distance < nearestDistance then
                            nearestDistance = distance
                            nearestPart = obj
                        end
                    end
                end
            end
        end
    end

    return nearestPart
end

        ----------------------------------------------------------------
        -- COMPUTE PATH
        ----------------------------------------------------------------
        local function computePath(targetPosition)
            if not humanoid or not myHRP then return false end

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
                currentWaypoints = path:GetWaypoints()
                currentWaypointIndex = 2
                currentTargetPosition = targetPosition
                return true
            end

            currentWaypoints = {}
            currentWaypointIndex = 2
            currentTargetPosition = nil
            return false
        end

        ----------------------------------------------------------------
        -- UNSTUCK MOVE
        ----------------------------------------------------------------
        local function doUnstuckMove()
            if not humanoid or not myHRP then return end

            local now = tick()
            if now - lastUnstuckTime < UNSTUCK_COOLDOWN then return end
            lastUnstuckTime = now

            resetPath()

            local side = myHRP.CFrame.RightVector
            if math.random(1, 2) == 1 then
                side = -side
            end

            local escapePosition =
                myHRP.Position
                + side * 5
                + myHRP.CFrame.LookVector * 3

            humanoid:MoveTo(escapePosition)
        end

        ----------------------------------------------------------------
        -- CHECK STUCK
        ----------------------------------------------------------------
        local function checkStuck(targetPosition)
            if not myHRP then return end

            local distanceToTarget = (myHRP.Position - targetPosition).Magnitude
            if distanceToTarget < 4 then
                stuckTime = 0
                lastPosition = myHRP.Position
                return
            end

            if lastPosition then
                local moved = (myHRP.Position - lastPosition).Magnitude

                if moved < 0.15 then
                    stuckTime += 0.1
                else
                    stuckTime = 0
                end
            end

            lastPosition = myHRP.Position

            if stuckTime >= STUCK_LIMIT then
                stuckTime = 0
                doUnstuckMove()
            end
        end

        ----------------------------------------------------------------
        -- SMART MOVE TO
        ----------------------------------------------------------------
        local function smartMoveTo(targetPosition)
            if not humanoid or not myHRP then return end

            checkStuck(targetPosition)

            local now = tick()
            local needNewPath = false

            if not currentTargetPosition then
                needNewPath = true
            elseif (targetPosition - currentTargetPosition).Magnitude > TARGET_REPATH_DISTANCE then
                needNewPath = true
            elseif now - lastPathTime >= PATH_UPDATE_TIME then
                needNewPath = true
            end

            if needNewPath then
                lastPathTime = now

                local success = computePath(targetPosition)

                if not success then
                    -- Kalau path gagal, jangan lompat-lompat.
                    -- Coba jalan langsung dulu.
                    humanoid:MoveTo(targetPosition)
                    return
                end
            end

            local waypoint = currentWaypoints[currentWaypointIndex]

            if waypoint then
                local distanceToWaypoint = (myHRP.Position - waypoint.Position).Magnitude

                if distanceToWaypoint <= WAYPOINT_REACH_DISTANCE then
                    currentWaypointIndex += 1
                    waypoint = currentWaypoints[currentWaypointIndex]
                end

                if waypoint then
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

            if player == LocalPlayer then
                stopFollow()
                return
            end

            stopFollow()

            following = true
            targetPlayer = player
            resetPath()

            sendChat("Yes, Sir!")

            local myOrder = table.find(botOrder, tostring(LocalPlayer.UserId))
            local targetOrder = table.find(botOrder, tostring(player.UserId))

            local myIndex

            if myOrder and targetOrder then
                myIndex = myOrder - targetOrder
            else
                myIndex = myOrder or 1
            end

            if myIndex <= 0 then
                stopFollow()
                return
            end

            followConnection = RunService.Heartbeat:Connect(function()
                if not following or not humanoid or not myHRP then return end
                if humanoid.Health <= 0 then return end
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

                local targetPosition = getFollowTargetPosition(hrp, distance, myIndex)

                smartMoveTo(targetPosition)
            end)
        end

        ----------------------------------------------------------------
        -- COMMAND HANDLER
        ----------------------------------------------------------------
        local function handleCommand(msg, sender)
            if not Admin:IsAdmin(sender) then return end

            local lower = msg:lower()

            if lower == "!follow" then
                startFollow(sender)
                return
            end

            local targetName = lower:match("^!follow%s+(.+)$")
            if targetName then
                local target = findPlayerByName(targetName)

                if target then
                    startFollow(target)
                end

                return
            end

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