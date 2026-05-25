-- Commands/Diamond.lua
-- Admin-only diamond bodyguard system + auto push
-- Supports: !diamond / !diamond <username|displayname>
-- !diamond otomatis aktifkan formasi + auto push

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
        -- REMOTES
        ----------------------------------------------------------------
        local connections = ReplicatedStorage:WaitForChild("Connections")
        local dataProviders = connections:WaitForChild("dataProviders")
        local playerReplication = dataProviders:WaitForChild("playerReplication")

        ----------------------------------------------------------------
        -- STATE
        ----------------------------------------------------------------
        local humanoid, myHRP
        local following = false
        local targetPlayer
        local followConnection
        local hasChatted = false

        local isPushing = false
        local lastPushTime = 0

        ----------------------------------------------------------------
        -- SETTINGS
        ----------------------------------------------------------------
        local adminFollowDistance = 3
        local defaultBotFollowDistance = 2
        local sideSpacing = 3

        local PUSH_RADIUS = 5
        local PUSH_COOLDOWN = 0.8
        local CHARGE_TIME = 0.3

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
        }

        local BOT_USERS = {}
        for _, userId in ipairs(botOrder) do
            BOT_USERS[tonumber(userId)] = true
        end

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
        -- STOP DIAMOND
        ----------------------------------------------------------------
        local function stopFollow()
            following = false
            targetPlayer = nil
            hasChatted = false
            isPushing = false

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
        -- CHECK TARGET VALID FOR PUSH
        ----------------------------------------------------------------
        local function isValidPushTarget(player)
            if not player then return false end
            if player == LocalPlayer then return false end
            if player == targetPlayer then return false end

            -- Jangan push admin
            if Admin:IsAdmin(player) then return false end

            -- Jangan push sesama bot
            if BOT_USERS[player.UserId] then return false end

            local character = player.Character
            if not character then return false end

            local hrp = character:FindFirstChild("HumanoidRootPart")
            local hum = character:FindFirstChild("Humanoid")

            if not hrp then return false end
            if not hum then return false end
            if hum.Health <= 0 then return false end

            return true
        end

        ----------------------------------------------------------------
        -- CEK APAKAH BOT INI PALING DEKAT KE TARGET
        ----------------------------------------------------------------
        local function isClosestBotToTarget(targetHRP)
            if not myHRP then return false end
            if not targetHRP then return false end

            local myDistance = (myHRP.Position - targetHRP.Position).Magnitude

            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and BOT_USERS[player.UserId] then
                    local character = player.Character
                    local botHRP = character and character:FindFirstChild("HumanoidRootPart")
                    local botHum = character and character:FindFirstChild("Humanoid")

                    if botHRP and botHum and botHum.Health > 0 then
                        local botDistance = (botHRP.Position - targetHRP.Position).Magnitude

                        if botDistance < myDistance then
                            return false
                        end
                    end
                end
            end

            return true
        end

        ----------------------------------------------------------------
        -- FIND NEAREST PUSH TARGET
        ----------------------------------------------------------------
        local function getNearestPushTarget()
            if not myHRP then return nil end

            local nearestPlayer = nil
            local nearestDistance = PUSH_RADIUS

            for _, player in ipairs(Players:GetPlayers()) do
                if isValidPushTarget(player) then
                    local character = player.Character
                    local targetHRP = character and character:FindFirstChild("HumanoidRootPart")

                    if targetHRP then
                        local distance = (myHRP.Position - targetHRP.Position).Magnitude

                        if distance <= nearestDistance and isClosestBotToTarget(targetHRP) then
                            nearestDistance = distance
                            nearestPlayer = player
                        end
                    end
                end
            end

            return nearestPlayer
        end

        ----------------------------------------------------------------
        -- DO PUSH
        ----------------------------------------------------------------
        local function doPush()
            if isPushing then return end

            local now = tick()
            if now - lastPushTime < PUSH_COOLDOWN then return end

            isPushing = true
            lastPushTime = now

            task.spawn(function()
                pcall(function()
                    playerReplication:FireServer("beginPushHold")
                end)

                task.wait(0.05)

                pcall(function()
                    playerReplication:FireServer("beginChargedPushAnimation", CHARGE_TIME)
                end)

                task.wait(CHARGE_TIME)

                pcall(function()
                    playerReplication:FireServer("push", "charged", CHARGE_TIME)
                end)

                task.wait(0.1)
                isPushing = false
            end)
        end

        ----------------------------------------------------------------
        -- START DIAMOND
        ----------------------------------------------------------------
        local function startFollow(player)
            if not player then return end

            stopFollow()

            following = true
            targetPlayer = player

            local myIndex = table.find(botOrder, tostring(LocalPlayer.UserId))
            if not myIndex then
                stopFollow()
                return
            end

            followConnection = RunService.Heartbeat:Connect(function()
                if not following then return end
                if not humanoid or not myHRP then return end
                if humanoid.Health <= 0 then return end
                if not targetPlayer then return end
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
                -- DIAMOND FORMATION
                ----------------------------------------------------------------
                local forward = hrp.CFrame.LookVector
                local right = hrp.CFrame.RightVector

                local frontDistance = distance + 1
                local diagonalFrontDistance = distance * 0.7
                local backDistance = distance
                local backCenterDistance = distance * 1.7

                local targetPosition

                if myIndex == 1 then
                    -- Bot 1: depan target/admin
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
                    -- Bot 6: belakang tengah
                    targetPosition =
                        hrp.Position
                        - forward * backCenterDistance

                else
                    -- Bot 7+ lanjut belakang dua baris
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

                if not hasChatted then
                    sendChat("Yes, Sir!")
                    hasChatted = true
                end

                humanoid:MoveTo(targetPosition)

                ----------------------------------------------------------------
                -- AUTO PUSH SAAT DIAMOND AKTIF
                ----------------------------------------------------------------
                local pushTarget = getNearestPushTarget()

                if pushTarget then
                    doPush()
                end
            end)
        end

        ----------------------------------------------------------------
        -- COMMAND HANDLER
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
            if lower == "!stop" or lower == "!unfollow" or lower == "!undiamond" then
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