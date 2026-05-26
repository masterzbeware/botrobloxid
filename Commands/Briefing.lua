-- Commands/Briefing.lua
-- Admin-only briefing system (NORMAL MoveTo, straight line formation)
-- Supports: !briefing / !briefing <username|displayname>
-- Konsep: bot berdiri di depan VIP/leader dan menghadap ke VIP/leader

return {
    Execute = function()
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
        -- LOAD DISTANCE MODULE
        ----------------------------------------------------------------
        local Distance = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
        ))()

        local humanoid, myHRP
        local briefing = false
        local targetPlayer
        local followConnection

        local adminBriefingDistance = 3
        local defaultBotBriefingDistance = 2

        ----------------------------------------------------------------
        -- BOT ORDER DARI DEPAN KE DEPAN LAGI
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
        -- FACE TARGET
        ----------------------------------------------------------------
        local function faceTarget(targetHRP)
            if not myHRP or not targetHRP then return end

            local lookPosition = Vector3.new(
                targetHRP.Position.X,
                myHRP.Position.Y,
                targetHRP.Position.Z
            )

            myHRP.CFrame = CFrame.lookAt(myHRP.Position, lookPosition)
        end

        ----------------------------------------------------------------
        -- STOP BRIEFING
        ----------------------------------------------------------------
        local function stopBriefing()
            briefing = false
            targetPlayer = nil

            if humanoid then
                humanoid.AutoRotate = true
            end

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
        -- START BRIEFING
        ----------------------------------------------------------------
        local function startBriefing(player)
            if not player then return end

            -- Jangan briefing diri sendiri
            if player == LocalPlayer then
                stopBriefing()
                return
            end

            stopBriefing()

            briefing = true
            targetPlayer = player

            sendChat("Yes, Sir!")

            local myOrder = table.find(botOrder, tostring(LocalPlayer.UserId))
            local targetOrder = table.find(botOrder, tostring(player.UserId))

            local myIndex

            if myOrder and targetOrder then
                myIndex = myOrder - targetOrder
            else
                myIndex = myOrder or 1
            end

            -- Kalau posisi bot ini sebelum/sama dengan target, jangan briefing
            if myIndex <= 0 then
                stopBriefing()
                return
            end

            if humanoid then
                humanoid.AutoRotate = false
            end

            followConnection = RunService.Heartbeat:Connect(function()
                if not briefing or not humanoid or not myHRP then return end
                if not targetPlayer then return end
                if not targetPlayer.Character then return end

                local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local distance = defaultBotBriefingDistance

                if Admin:IsAdmin(targetPlayer) then
                    distance = adminBriefingDistance
                end

                local special = Distance:GetDistance(
                    tostring(LocalPlayer.UserId),
                    tostring(targetPlayer.UserId)
                )

                if special then
                    distance = special
                end

                ----------------------------------------------------------------
                -- POSISI DI DEPAN TARGET
                --
                -- Follow.lua:
                -- belakang = hrp.CFrame.LookVector * -(distance * myIndex)
                --
                -- Briefing.lua:
                -- depan = hrp.CFrame.LookVector * (distance * myIndex)
                ----------------------------------------------------------------
                local offset = hrp.CFrame.LookVector * (distance * myIndex)
                local targetPosition = hrp.Position + offset

                humanoid:MoveTo(targetPosition)

                ----------------------------------------------------------------
                -- MENGHADAP KE VIP / LEADER
                ----------------------------------------------------------------
                local distanceToPosition = (myHRP.Position - targetPosition).Magnitude

                if distanceToPosition <= 2.5 then
                    faceTarget(hrp)
                end
            end)
        end

        ----------------------------------------------------------------
        -- COMMAND HANDLER
        ----------------------------------------------------------------
        local function handleCommand(msg, sender)
            if not Admin:IsAdmin(sender) then return end

            local lower = msg:lower()

            -- !briefing
            if lower == "!briefing" then
                startBriefing(sender)
                return
            end

            -- !briefing <name/displayname>
            local targetName = lower:match("^!briefing%s+(.+)$")
            if targetName then
                local target = findPlayerByName(targetName)

                if target then
                    startBriefing(target)
                end

                return
            end

            -- !stop / !unbriefing
            if lower == "!stop" or lower == "!unbriefing" then
                stopBriefing()
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