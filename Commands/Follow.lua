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
        _G.BotVars.ModeControllers = _G.BotVars.ModeControllers or {}

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

        ----------------------------------------------------------------
        -- DISTANCE
        ----------------------------------------------------------------

        local adminFollowDistance = 3
        local defaultBotFollowDistance = 3

        ----------------------------------------------------------------
        -- BOT ORDER
        ----------------------------------------------------------------

local botOrder = {
    "11611503633", -- Bot 1
    "11611567975", -- Bot 2
    "11611562042", -- Bot 3
    "11611591921", -- Bot 4
}

        ----------------------------------------------------------------
        -- UPDATE CHARACTER
        ----------------------------------------------------------------

        local function updateCharacter()

            local character =
                LocalPlayer.Character
                or LocalPlayer.CharacterAdded:Wait()

            humanoid =
                character:WaitForChild("Humanoid")

            myHRP =
                character:WaitForChild("HumanoidRootPart")

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

                    pcall(function()
                        channel:SendAsync(message)
                    end)

                    success = true

                end
            end

            if not success then

                pcall(function()

                    local chatEvents =
                        ReplicatedStorage:FindFirstChild(
                            "DefaultChatSystemChatEvents"
                        )

                    if chatEvents then

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

            name = name:lower()

            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if player.Name:lower() == name
                    or player.DisplayName:lower() == name then

                    return player

                end

            end

            return nil

        end

        ----------------------------------------------------------------
        -- START FOLLOW
        ----------------------------------------------------------------

        local function startFollow(player)

            if not player then
                return
            end

            ------------------------------------------------------------
            -- STOP MODE LAIN
            ------------------------------------------------------------

            stopOtherModes()

            ------------------------------------------------------------
            -- SET ACTIVE MODE
            ------------------------------------------------------------

            _G.BotVars.ActiveMode = "follow"

            ------------------------------------------------------------
            -- STOP CONNECTION LAMA
            ------------------------------------------------------------

            if followConnection then

                followConnection:Disconnect()
                followConnection = nil

            end

            following = true
            targetPlayer = player

            sendChat("Yes, Sir!")

            ------------------------------------------------------------
            -- CARI INDEX BOT
            ------------------------------------------------------------

            local myIndex =
                table.find(
                    botOrder,
                    tostring(LocalPlayer.UserId)
                )

            if not myIndex then

                stopFollow()

                return

            end

            ------------------------------------------------------------
            -- FOLLOW LOOP
            ------------------------------------------------------------

            followConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- JIKA MODE SUDAH BERGANTI
                        ------------------------------------------------

                        if _G.BotVars.ActiveMode ~= "follow" then

                            stopFollow()

                            return

                        end

                        ------------------------------------------------
                        -- VALIDASI
                        ------------------------------------------------

                        if not following then
                            return
                        end

                        if not humanoid
                            or not myHRP then

                            return

                        end

                        if not targetPlayer then
                            return
                        end
                        ------------------------------------------------
                        -- FORMATION TARGET
                        -- Bot 1 mengikuti Admin.
                        -- Bot berikutnya mengikuti bot tepat di depannya.
                        -- Jadi jarak dihitung antar anggota barisan, bukan
                        -- dikalikan dengan index dari posisi Admin.
                        ------------------------------------------------

                        local formationTarget = targetPlayer

                        if myIndex > 1 then

                            local previousBotUserId =
                                tonumber(botOrder[myIndex - 1])

                            if previousBotUserId then

                                local previousBot =
                                    Players:GetPlayerByUserId(
                                        previousBotUserId
                                    )

                                if previousBot then
                                    formationTarget = previousBot
                                end

                            end

                        end

                        local formationCharacter =
                            formationTarget.Character

                        if not formationCharacter then
                            return
                        end

                        local formationHRP =
                            formationCharacter:FindFirstChild(
                                "HumanoidRootPart"
                            )

                        if not formationHRP then
                            return
                        end

                        ------------------------------------------------
                        -- DISTANCE DARI DISTANCE.LUA
                        ------------------------------------------------

                        local distance =
                            defaultBotFollowDistance

                        if myIndex == 1 then

                            distance =
                                adminFollowDistance

                        else

                            local pairDistance =
                                Distance:GetDistance(
                                    tostring(LocalPlayer.UserId),
                                    tostring(formationTarget.UserId)
                                )

                            if pairDistance then
                                distance = pairDistance
                            end

                        end

                        ------------------------------------------------
                        -- POSISI BOT
                        ------------------------------------------------

                        local targetPosition =
                            formationHRP.Position
                            -
                            (
                                formationHRP.CFrame.LookVector
                                * distance
                            )

                        ------------------------------------------------
                        -- JARAK
                        ------------------------------------------------

                        local distanceToTarget =
                            (
                                myHRP.Position
                                -
                                targetPosition
                            ).Magnitude

                        ------------------------------------------------
                        -- JALAN
                        ------------------------------------------------

                        if distanceToTarget > 1.5 then

                            humanoid.AutoRotate = true

                            humanoid:MoveTo(
                                targetPosition
                            )

                            return

                        end

                        ------------------------------------------------
                        -- SUDAH SAMPAI
                        ------------------------------------------------

                        humanoid.AutoRotate = false

                        local formationRotation =
                            formationHRP.CFrame
                            -
                            formationHRP.Position

                        myHRP.CFrame =
                            CFrame.new(
                                myHRP.Position
                            )
                            *
                            formationRotation

                    end
                )

        end

        ----------------------------------------------------------------
        -- COMMAND HANDLER
        ----------------------------------------------------------------

        local function handleCommand(
            message,
            sender
        )

            if not Admin:IsAdmin(sender) then
                return
            end

            local lower =
                message:lower()

            ------------------------------------------------------------
            -- !FOLLOW
            ------------------------------------------------------------

            if lower == "!follow" then

                startFollow(sender)

                return

            end

            ------------------------------------------------------------
            -- !FOLLOW PLAYER
            ------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!follow%s+(.+)$"
                )

            if targetName then

                local target =
                    findPlayerByName(
                        targetName
                    )

                if target then

                    startFollow(target)

                end

                return

            end

            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if lower == "!stop"
                or lower == "!unfollow" then

                _G.BotVars.ActiveMode = nil

                stopFollow()

                return

            end

        end

        ----------------------------------------------------------------
        -- TEXT CHAT
        ----------------------------------------------------------------

        if TextChatService
            and TextChatService.TextChannels then

            local channel =
                TextChatService.TextChannels:FindFirstChild(
                    "RBXGeneral"
                )

            if channel then

                channel.OnIncomingMessage =
                    function(message)

                        local userId =
                            message.TextSource
                            and message.TextSource.UserId

                        local sender =
                            userId
                            and Players:GetPlayerByUserId(
                                userId
                            )

                        if sender then

                            handleCommand(
                                message.Text,
                                sender
                            )

                        end

                    end

            end

        end

        ----------------------------------------------------------------
        -- FALLBACK CHAT
        ----------------------------------------------------------------

        for _, player in ipairs(
            Players:GetPlayers()
        ) do

            player.Chatted:Connect(
                function(message)

                    handleCommand(
                        message,
                        player
                    )

                end
            )

        end

        ----------------------------------------------------------------
        -- PLAYER ADDED
        ----------------------------------------------------------------

        Players.PlayerAdded:Connect(
            function(player)

                player.Chatted:Connect(
                    function(message)

                        handleCommand(
                            message,
                            player
                        )

                    end
                )

            end
        )

        ----------------------------------------------------------------
        -- CHARACTER RESPAWN
        ----------------------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(
            function()

                task.wait(1)

                updateCharacter()

                if _G.BotVars.ActiveMode == "follow"
                    and targetPlayer then

                    startFollow(
                        targetPlayer
                    )

                end

            end
        )

    end
}
