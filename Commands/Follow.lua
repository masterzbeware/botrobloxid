gimana caranya kode ini agar jika ada tembok maka akan menghindar
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
-- PATHFINDING
----------------------------------------------------------------
local currentPathId = 0
local lastPathTime = 0
local lastTargetPosition

local function moveWithPath(targetPosition)
    if not humanoid or not myHRP then return end

    -- Jangan terlalu sering hitung path biar tidak lag
    if tick() - lastPathTime < 0.8 then
        return
    end

    -- Kalau target belum banyak berubah, jangan hitung ulang
    if lastTargetPosition and (lastTargetPosition - targetPosition).Magnitude < 3 then
        return
    end

    lastPathTime = tick()
    lastTargetPosition = targetPosition
    currentPathId += 1

    local thisPathId = currentPathId

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentCanClimb = true,
        WaypointSpacing = 4,
    })

    local success, err = pcall(function()
        path:ComputeAsync(myHRP.Position, targetPosition)
    end)

    if not success or path.Status ~= Enum.PathStatus.Success then
        humanoid:MoveTo(targetPosition)
        return
    end

    local waypoints = path:GetWaypoints()

    task.spawn(function()
        for _, waypoint in ipairs(waypoints) do
            if not following then return end
            if thisPathId ~= currentPathId then return end
            if not humanoid or not myHRP then return end

            if waypoint.Action == Enum.PathWaypointAction.Jump then
                humanoid.Jump = true
            end

            humanoid:MoveTo(waypoint.Position)

            local reached = humanoid.MoveToFinished:Wait()

            if not reached then
                break
            end
        end
    end)
end

        ----------------------------------------------------------------
        -- START FOLLOW
        ----------------------------------------------------------------
        local function startFollow(player)
            if not player then return end

            -- Jangan follow diri sendiri
if player == LocalPlayer then
    warn("[FOLLOW DEBUG] Tidak bisa follow diri sendiri:", LocalPlayer.Name, LocalPlayer.UserId)
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
    warn("[FOLLOW DEBUG] Bot tidak follow karena myIndex <= 0")
    warn("[FOLLOW DEBUG] LocalPlayer:", LocalPlayer.Name, LocalPlayer.UserId)
    warn("[FOLLOW DEBUG] Target:", player.Name, player.UserId)
    warn("[FOLLOW DEBUG] myOrder:", myOrder, "targetOrder:", targetOrder, "myIndex:", myIndex)
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

moveWithPath(targetPosition)
            end)
        end

----------------------------------------------------------------
-- COMMAND HANDLER
----------------------------------------------------------------
local function handleCommand(msg, sender)
    warn("[FOLLOW DEBUG] Chat dari:", sender.Name, sender.UserId, "Pesan:", msg)

    if not Admin:IsAdmin(sender) then
        warn("[FOLLOW DEBUG] Ditolak, bukan admin:", sender.Name, sender.UserId)
        return
    end

    warn("[FOLLOW DEBUG] Admin valid:", sender.Name)

    local lower = msg:lower()

    if lower == "!follow" then
        warn("[FOLLOW DEBUG] Command !follow diterima")
        startFollow(sender)
        return
    end

    local targetName = lower:match("^!follow%s+(.+)$")
    if targetName then
        local target = findPlayerByName(targetName)

        if target then
            warn("[FOLLOW DEBUG] Follow target:", target.Name)
            startFollow(target)
        else
            warn("[FOLLOW DEBUG] Target tidak ditemukan:", targetName)
        end

        return
    end

    if lower == "!stop" or lower == "!unfollow" then
        warn("[FOLLOW DEBUG] Stop follow")
        stopFollow()
        return
    end
end

----------------------------------------------------------------
-- TEXT CHAT SERVICE FIX UNTUK EXECUTOR
----------------------------------------------------------------
task.spawn(function()
    local textChannels = TextChatService:WaitForChild("TextChannels", 10)
    if not textChannels then
        warn("[FOLLOW] TextChannels tidak ditemukan")
        return
    end

    local ch = textChannels:FindFirstChild("RBXGeneral") or textChannels:WaitForChild("RBXGeneral", 10)

    if not ch then
        warn("[FOLLOW] RBXGeneral tidak ditemukan")
        return
    end

    ch.MessageReceived:Connect(function(message)
        local uid = message.TextSource and message.TextSource.UserId
        local sender = uid and Players:GetPlayerByUserId(uid)

        if sender then
            handleCommand(message.Text, sender)
        end
    end)

    warn("[FOLLOW] TextChat listener aktif")
end)

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