
-- Follow.lua
-- MasterZ HUB
-- Follow system dengan respons awal lebih cepat.
-- Mendukung Admin, AdminTarget, pasangan bot, dan respawn.

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

        if not LocalPlayer then
            return
        end

        ----------------------------------------------------------------
        -- GLOBAL MODE SYSTEM
        ----------------------------------------------------------------

        _G.BotVars = _G.BotVars or {}
        _G.BotVars.ModeControllers =
            _G.BotVars.ModeControllers or {}

        ----------------------------------------------------------------
        -- LOAD ADMIN
        ----------------------------------------------------------------

        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        ----------------------------------------------------------------
        -- LOAD DISTANCE
        ----------------------------------------------------------------

        local Distance = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
        ))()

        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local humanoid
        local myHRP

        local following = false
        local targetPlayer = nil
        local followConnection = nil

        -- Mencegah listener CharacterAdded dibuat berulang.
        local respawnConnection

        ----------------------------------------------------------------
        -- DISTANCE
        ----------------------------------------------------------------

        local adminFollowDistance = 3
        local defaultBotFollowDistance = 2

        ----------------------------------------------------------------
        -- BOT ORDER
        ----------------------------------------------------------------

        local botOrder = {
            "11611503633", -- Bot 1
            "11611591921", -- Bot 2
            "11611597741", -- Bot 3
            "11672413029", -- Bot 4
            "11122806815", -- Bot 5
            "11122806817", -- Bot 6
            "11122687468", -- Bot 7
            "11122854402", -- Bot 8
            "11774472805", -- Bot 9
            "11774494628", -- Bot 10
        }

        ----------------------------------------------------------------
        -- UPDATE CHARACTER
        ----------------------------------------------------------------

        local function updateCharacter()
            local character =
                LocalPlayer.Character
                or LocalPlayer.CharacterAdded:Wait()

            local newHumanoid =
                character:WaitForChild("Humanoid")

            local newHRP =
                character:WaitForChild("HumanoidRootPart")

            humanoid = newHumanoid
            myHRP = newHRP

            humanoid.AutoRotate = true
        end

        updateCharacter()

        ----------------------------------------------------------------
        -- SEND CHAT
        ----------------------------------------------------------------

        local function sendChat(message)
            local success = false

            if TextChatService
                and TextChatService.TextChannels then

                local channel =
                    TextChatService.TextChannels:FindFirstChild(
                        "RBXGeneral"
                    )

                if channel then
                    success = pcall(function()
                        channel:SendAsync(message)
                    end)
                end
            end

            if not success then
                pcall(function()
                    local chatEvents =
                        ReplicatedStorage:FindFirstChild(
                            "DefaultChatSystemChatEvents"
                        )

                    if not chatEvents then
                        return
                    end

                    local sayMessageRequest =
                        chatEvents:FindFirstChild(
                            "SayMessageRequest"
                        )

                    if sayMessageRequest then
                        sayMessageRequest:FireServer(
                            message,
                            "All"
                        )
                    end
                end)
            end
        end

        ----------------------------------------------------------------
        -- STOP FOLLOW
        ----------------------------------------------------------------

        local function stopFollow()
            following = false
            targetPlayer = nil

            -- CommandTarget sengaja tidak dihapus di sini.
            -- CommandTarget hanya dihapus oleh !stop / !unfollow.

            if followConnection then
                followConnection:Disconnect()
                followConnection = nil
            end

            if humanoid then
                humanoid.AutoRotate = true
            end
        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.follow = stopFollow

        ----------------------------------------------------------------
        -- STOP SEMUA MODE LAIN
        ----------------------------------------------------------------

        local function stopOtherModes()
            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do
                if name ~= "follow"
                    and type(stopFunction) == "function" then

                    pcall(stopFunction)
                end
            end
        end

        ----------------------------------------------------------------
        -- FIND PLAYER
        ----------------------------------------------------------------

        local function findPlayerByName(name)
            if not name or name == "" then
                return nil
            end

            name = name:lower()

            -- Exact username / display name
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Name:lower() == name
                    or player.DisplayName:lower() == name then

                    return player
                end
            end

            -- Username prefix
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Name:lower():sub(
                    1,
                    #name
                ) == name then

                    return player
                end
            end

            -- Display name prefix
            for _, player in ipairs(Players:GetPlayers()) do
                if player.DisplayName:lower():sub(
                    1,
                    #name
                ) == name then

                    return player
                end
            end

            return nil
        end

        ----------------------------------------------------------------
        -- MOVE TO TARGET
        ----------------------------------------------------------------

        local function moveToTarget(myIndex)
            if not following
                or _G.BotVars.ActiveMode ~= "follow"
                or not humanoid
                or not myHRP
                or not targetPlayer then

                return
            end

            local targetCharacter = targetPlayer.Character

            if not targetCharacter then
                return
            end

            local targetHRP =
                targetCharacter:FindFirstChild(
                    "HumanoidRootPart"
                )

            if not targetHRP then
                return
            end

            ------------------------------------------------------------
            -- FOLLOW DISTANCE
            ------------------------------------------------------------

            local distance = defaultBotFollowDistance

            if Admin:IsAdmin(targetPlayer) then
                distance = adminFollowDistance
            end

            local specialDistance = Distance:GetDistance(
                tostring(LocalPlayer.UserId),
                tostring(targetPlayer.UserId)
            )

            if specialDistance then
                distance = specialDistance
            end

            ------------------------------------------------------------
            -- TARGET POSITION
            ------------------------------------------------------------

            local targetPosition =
                targetHRP.Position
                - (
                    targetHRP.CFrame.LookVector
                    * (distance * myIndex)
                )

            ------------------------------------------------------------
            -- DISTANCE CHECK
            ------------------------------------------------------------

            local distanceToTarget =
                (myHRP.Position - targetPosition).Magnitude

            ------------------------------------------------------------
            -- MOVE
            ------------------------------------------------------------

            if distanceToTarget > 1.5 then
                humanoid.AutoRotate = true

                humanoid:MoveTo(targetPosition)

                return
            end

            ------------------------------------------------------------
            -- ARRIVED
            ------------------------------------------------------------

            humanoid.AutoRotate = false

            local targetRotation =
                targetHRP.CFrame - targetHRP.Position

            myHRP.CFrame =
                CFrame.new(myHRP.Position)
                * targetRotation
        end

        ----------------------------------------------------------------
        -- START FOLLOW
        ----------------------------------------------------------------

        local function startFollow(player)
            if not player then
                return
            end

            ------------------------------------------------------------
            -- FIND BOT INDEX BEFORE STARTING
            ------------------------------------------------------------

            local myIndex = table.find(
                botOrder,
                tostring(LocalPlayer.UserId)
            )

            if not myIndex then
                warn(
                    "[Follow] UserId bot tidak ditemukan di botOrder:",
                    LocalPlayer.UserId
                )

                stopFollow()
                return
            end

            ------------------------------------------------------------
            -- STOP OTHER MODES
            ------------------------------------------------------------

            stopOtherModes()

            ------------------------------------------------------------
            -- REPLACE OLD CONNECTION
            ------------------------------------------------------------

            if followConnection then
                followConnection:Disconnect()
                followConnection = nil
            end

            ------------------------------------------------------------
            -- SET FOLLOW STATE
            ------------------------------------------------------------

            following = true
            targetPlayer = player

            _G.BotVars.ActiveMode = "follow"
            _G.BotVars.CommandTarget = player

            ------------------------------------------------------------
            -- START MOVEMENT IMMEDIATELY
            ------------------------------------------------------------

            moveToTarget(myIndex)

            ------------------------------------------------------------
            -- CONTINUE UPDATING EVERY FRAME
            ------------------------------------------------------------

            followConnection =
                RunService.Heartbeat:Connect(function()

                    if not following
                        or _G.BotVars.ActiveMode ~= "follow" then

                        stopFollow()
                        return
                    end

                    moveToTarget(myIndex)
                end)

            ------------------------------------------------------------
            -- CONFIRMATION CHAT WITHOUT BLOCKING MOVEMENT
            ------------------------------------------------------------

            task.spawn(function()
                sendChat("Yes, Sir!")
            end)
        end

        ----------------------------------------------------------------
        -- COMMAND HANDLER
        ----------------------------------------------------------------

        local function handleCommand(message, sender)
            if not sender or type(message) ~= "string" then
                return
            end

            ------------------------------------------------------------
            -- ADMIN CHECK
            ------------------------------------------------------------

            local isAdmin = false

            pcall(function()
                isAdmin = Admin:IsAdmin(sender)
            end)

            ------------------------------------------------------------
            -- COMMAND TARGET CHECK
            ------------------------------------------------------------

            local isCommandTarget =
                _G.BotVars.CommandTarget == sender

            ------------------------------------------------------------
            -- CLEAN MESSAGE
            ------------------------------------------------------------

            local lower =
                message:lower()
                :gsub("^%s+", "")
                :gsub("%s+$", "")

            ------------------------------------------------------------
            -- !STOP / !UNFOLLOW
            -- ONLY ADMIN
            ------------------------------------------------------------

            if lower == "!stop"
                or lower == "!unfollow" then

                if not isAdmin then
                    return
                end

                _G.BotVars.ActiveMode = nil
                _G.BotVars.CommandTarget = nil

                for _, stopFunction in pairs(
                    _G.BotVars.ModeControllers
                ) do
                    if type(stopFunction) == "function" then
                        pcall(stopFunction)
                    end
                end

                return
            end

            ------------------------------------------------------------
            -- !FOLLOW
            -- ADMIN OR CURRENT COMMAND TARGET
            ------------------------------------------------------------

            if lower == "!follow" then
                if not isAdmin and not isCommandTarget then
                    return
                end

                startFollow(sender)
                return
            end

            ------------------------------------------------------------
            -- !FOLLOW PLAYER
            -- ONLY ADMIN CAN SELECT A NEW TARGET
            ------------------------------------------------------------

            local targetName =
                lower:match("^!follow%s+(.+)$")

            if targetName then
                if not isAdmin then
                    return
                end

                local target =
                    findPlayerByName(targetName)

                if not target then
                    warn(
                        "[Follow] Target tidak ditemukan:",
                        targetName
                    )

                    return
                end

                startFollow(target)
                return
            end
        end

        ----------------------------------------------------------------
        -- CHAT LISTENER
        -- USE ONE CHAT PATH TO AVOID DUPLICATE COMMANDS
        ----------------------------------------------------------------

        local chatConnected = false

        if TextChatService
            and TextChatService.TextChannels then

            local channel =
                TextChatService.TextChannels:FindFirstChild(
                    "RBXGeneral"
                )

            if channel then
                channel.MessageReceived:Connect(function(message)
                    local userId =
                        message.TextSource
                        and message.TextSource.UserId

                    if not userId then
                        return
                    end

                    local sender =
                        Players:GetPlayerByUserId(userId)

                    if sender then
                        handleCommand(message.Text, sender)
                    end
                end)

                chatConnected = true
            end
        end

        ----------------------------------------------------------------
        -- FALLBACK CHAT
        -- ONLY IF RBXGENERAL IS NOT AVAILABLE AT INITIALIZATION
        ----------------------------------------------------------------

        if not chatConnected then
            local function connectPlayerChat(player)
                player.Chatted:Connect(function(message)
                    handleCommand(message, player)
                end)
            end

            for _, player in ipairs(Players:GetPlayers()) do
                connectPlayerChat(player)
            end

            Players.PlayerAdded:Connect(connectPlayerChat)
        end

        ----------------------------------------------------------------
        -- CHARACTER RESPAWN
        ----------------------------------------------------------------

        if respawnConnection then
            respawnConnection:Disconnect()
        end

        respawnConnection =
            LocalPlayer.CharacterAdded:Connect(function()

                -- Save the target before refreshing character references.
                local previousTarget = targetPlayer
                local shouldResume =
                    _G.BotVars.ActiveMode == "follow"
                    and following
                    and previousTarget ~= nil

                -- Stop the old movement connection during respawn.
                if followConnection then
                    followConnection:Disconnect()
                    followConnection = nil
                end

                task.spawn(function()
                    updateCharacter()

                    if shouldResume
                        and previousTarget
                        and _G.BotVars.ActiveMode == "follow" then

                        startFollow(previousTarget)
                    end
                end)
            end)

        ----------------------------------------------------------------
        -- FINISHED
        ----------------------------------------------------------------

        print("[Follow] Follow system berhasil dimuat.")
    end
}
