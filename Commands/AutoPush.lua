-- Commands/AutoPush.lua
-- Admin-only auto push guard
-- Supports: !autopush / !stopautopush / !stop
-- Tidak toggle: !autopush selalu aktif, !stopautopush selalu mati

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
        -- LOAD ADMIN MODULE
        ----------------------------------------------------------------
        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        ----------------------------------------------------------------
        -- REMOTES
        ----------------------------------------------------------------
        local connections = ReplicatedStorage:WaitForChild("Connections")
        local dataProviders = connections:WaitForChild("dataProviders")
        local playerReplication = dataProviders:WaitForChild("playerReplication")

        ----------------------------------------------------------------
        -- SETTINGS
        ----------------------------------------------------------------
        local PUSH_RADIUS = 5
        local PUSH_COOLDOWN = 0.8
        local CHARGE_TIME = 0.3

        ----------------------------------------------------------------
        -- BOT LIST
        ----------------------------------------------------------------
        local BOT_USERS = {
            [11001607521] = true, -- Bot 1 / Admin
            [11001608049] = true, -- Bot 2
            [11001625681] = true, -- Bot 3
            [11001647769] = true, -- Bot 4
            [11002716767] = true, -- Bot 5
            [11002763516] = true, -- Bot 6
            [11002833908] = true, -- Bot 7
            [11002919499] = true, -- Bot 8
            [11002918670] = true, -- Bot 9
        }

        ----------------------------------------------------------------
        -- STATE
        ----------------------------------------------------------------
        local autoPushing = false
        local pushConnection = nil
        local lastPushTime = 0
        local isPushing = false

        local humanoid, myHRP

        ----------------------------------------------------------------
        -- UPDATE CHARACTER
        ----------------------------------------------------------------
        local function updateCharacter()
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            humanoid = character:WaitForChild("Humanoid")
            myHRP = character:WaitForChild("HumanoidRootPart")
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
        -- STOP AUTO PUSH
        ----------------------------------------------------------------
        local function stopAutoPush()
            autoPushing = false
            isPushing = false

            if pushConnection then
                pushConnection:Disconnect()
                pushConnection = nil
            end
        end

        ----------------------------------------------------------------
        -- CHECK TARGET VALID
        ----------------------------------------------------------------
        local function isValidTarget(player)
            if not player then return false end
            if player == LocalPlayer then return false end

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
        -- CEK BOT TERDEKAT KE TARGET
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

                        -- Kalau bot lain lebih dekat, bot ini jangan push
                        if botDistance < myDistance then
                            return false
                        end
                    end
                end
            end

            return true
        end

        ----------------------------------------------------------------
        -- FIND NEAREST PLAYER
        ----------------------------------------------------------------
        local function getNearestPlayer()
            if not myHRP then return nil end

            local nearestPlayer = nil
            local nearestDistance = PUSH_RADIUS

            for _, player in ipairs(Players:GetPlayers()) do
                if isValidTarget(player) then
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

            if now - lastPushTime < PUSH_COOLDOWN then
                return
            end

            isPushing = true
            lastPushTime = now

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
        end

        ----------------------------------------------------------------
        -- START AUTO PUSH
        ----------------------------------------------------------------
        local function startAutoPush()
            -- Kalau sudah aktif, jangan dibuat ulang
            if autoPushing then
                return
            end

            stopAutoPush()

            autoPushing = true
            sendChat("Auto push enabled!")

            pushConnection = RunService.Heartbeat:Connect(function()
                if not autoPushing then return end
                if not humanoid then return end
                if not myHRP then return end
                if humanoid.Health <= 0 then return end

                local target = getNearestPlayer()

                if target then
                    doPush()
                end
            end)
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
        -- COMMAND HANDLER
        ----------------------------------------------------------------
        local function handleCommand(msg, sender)
            if not Admin:IsAdmin(sender) then return end

            local lower = msg:lower()

            -- !autopush
            if lower == "!autopush" then
                startAutoPush()
                return
            end

            -- !stop / !stopautopush
            if lower == "!stop" or lower == "!stopautopush" then
                stopAutoPush()
                sendChat("Auto push disabled!")
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