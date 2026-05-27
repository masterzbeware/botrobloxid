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

        local adminFollowDistance = 3
        local defaultBotFollowDistance = 2
        local sideSpacing = 3

        ----------------------------------------------------------------
        -- BOT ORDER (TINGGAL TAMBAH ID)
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
        -- START DIAMOND FOLLOW
        ----------------------------------------------------------------
local function startFollow(player)

    if not player then
        return
    end

    ------------------------------------------------------------
    -- JANGAN FOLLOW DIRI SENDIRI
    ------------------------------------------------------------
    if player == LocalPlayer then
        stopFollow()
        return
    end

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
-- DIAMOND FORMATION
----------------------------------------------------------------
local forward = hrp.CFrame.LookVector
local right = hrp.CFrame.RightVector

local frontDistance = distance + 1
local diagonalFrontDistance = distance * 0.7
local backDistance = distance
local backCenterDistance = distance * 1.7

if myIndex == 1 then
    -- Bot 1: tepat di depan Admin
    targetPosition =
        hrp.Position
        + forward * frontDistance

elseif myIndex == 2 then
    -- Bot 2: kanan depan
    targetPosition =
        hrp.Position
        + forward * diagonalFrontDistance
        + right * sideSpacing

elseif myIndex == 3 then
    -- Bot 3: kiri depan
    targetPosition =
        hrp.Position
        + forward * diagonalFrontDistance
        - right * sideSpacing

elseif myIndex == 4 then
    -- Bot 4: kanan belakang
    targetPosition =
        hrp.Position
        - forward * backDistance
        + right * sideSpacing

elseif myIndex == 5 then
    -- Bot 5: kiri belakang
    targetPosition =
        hrp.Position
        - forward * backDistance
        - right * sideSpacing

elseif myIndex == 6 then
    -- Bot 6: tepat di belakang Admin
    targetPosition =
        hrp.Position
        - forward * backCenterDistance

else
    ----------------------------------------------------------------
    -- BOT 7+ lanjut di belakang dalam 2 baris
    ----------------------------------------------------------------
    local extraIndex = myIndex - 6
    local isLeft = extraIndex % 2 == 1
    local lineIndex = math.ceil(extraIndex / 2)

    local sideDir =
        isLeft and -right or right

    targetPosition =
        hrp.Position
        - forward * (backCenterDistance + distance * lineIndex)
        + sideDir * sideSpacing
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
