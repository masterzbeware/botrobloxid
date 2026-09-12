return {
    Execute = function()

        --------------------------------------------------
        -- SERVICES
        --------------------------------------------------

        local Players =
            game:GetService("Players")

        local RunService =
            game:GetService("RunService")

        local TextChatService =
            game:GetService("TextChatService")

        local ReplicatedStorage =
            game:GetService("ReplicatedStorage")

        local LocalPlayer =
            Players.LocalPlayer

        if not LocalPlayer then
            return
        end

        --------------------------------------------------
        -- GLOBAL MODE SYSTEM
        --------------------------------------------------

        _G.BotVars = _G.BotVars or {}

        _G.BotVars.ModeControllers =
            _G.BotVars.ModeControllers or {}

        --------------------------------------------------
        -- LOAD ADMIN
        --------------------------------------------------

        local Admin = loadstring(
            game:HttpGet(
                "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
            )
        )()

        --------------------------------------------------
        -- LOAD DISTANCE
        --------------------------------------------------

        local Distance = loadstring(
            game:HttpGet(
                "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
            )
        )()

        --------------------------------------------------
        -- BOT LIST
        --------------------------------------------------

        local botIds = {

            "11611503633", -- B1
            "11611534165", -- B2
            "11611567975", -- B3
            "11611562042", -- B4
            "11611591921", -- B5
            "11122806815", -- B6
            "11122806817", -- B7
            "11122687468", -- B8
            "11122854402", -- B9
            "11641280895", -- B10
            "11641342530", -- B11

        }

        --------------------------------------------------
        -- CONFIG
        --------------------------------------------------

        local sideSpacing = 2.5

        local stopThreshold = 1.5

        --------------------------------------------------
        -- ACTIVE CONNECTION
        --------------------------------------------------

        local twoWingsConnection = nil

        --------------------------------------------------
        -- GET CHARACTER
        --------------------------------------------------

        local function getCharacter()

            local character =
                LocalPlayer.Character

            if not character then
                return nil
            end

            local humanoid =
                character:FindFirstChildOfClass(
                    "Humanoid"
                )

            local hrp =
                character:FindFirstChild(
                    "HumanoidRootPart"
                )

            if not humanoid or not hrp then
                return nil
            end

            return character, humanoid, hrp

        end

        --------------------------------------------------
        -- GET FOLLOW DISTANCE
        --------------------------------------------------

        local function getFollowDistance(
            botUserId,
            targetUserId
        )

            local defaultDistance = 2

            --------------------------------------------------
            -- ADMIN DISTANCE
            --------------------------------------------------

            if Admin
                and Admin.IsAdmin then

                local targetPlayer =
                    Players:GetPlayerByUserId(
                        tonumber(targetUserId)
                    )

                if targetPlayer then

                    local success, result =
                        pcall(function()

                            return Admin:IsAdmin(
                                targetPlayer
                            )

                        end)

                    if success and result then

                        defaultDistance = 3

                    end

                end

            end

            --------------------------------------------------
            -- DISTANCE MODULE
            --------------------------------------------------

            if Distance then

                local success, result =
                    pcall(function()

                        return Distance:GetDistance(
                            tostring(botUserId),
                            tostring(targetUserId)
                        )

                    end)

                if success
                    and typeof(result) == "number" then

                    return result

                end

            end

            return defaultDistance

        end

        --------------------------------------------------
        -- FORMATION
        --------------------------------------------------

        local function getFormationOffset(
            index,
            distance
        )

            --------------------------------------------------
            -- B1
            --------------------------------------------------

            if index == 1 then

                return Vector3.new(
                    0,
                    0,
                    -distance
                )

            --------------------------------------------------
            -- B2
            --------------------------------------------------

            elseif index == 2 then

                return Vector3.new(
                    -sideSpacing,
                    0,
                    -(distance * 2)
                )

            --------------------------------------------------
            -- B3
            --------------------------------------------------

            elseif index == 3 then

                return Vector3.new(
                    sideSpacing,
                    0,
                    -(distance * 2)
                )

            --------------------------------------------------
            -- B4
            --------------------------------------------------

            elseif index == 4 then

                return Vector3.new(
                    -sideSpacing,
                    0,
                    -(distance * 3)
                )

            --------------------------------------------------
            -- B5
            --------------------------------------------------

            elseif index == 5 then

                return Vector3.new(
                    sideSpacing,
                    0,
                    -(distance * 3)
                )

            --------------------------------------------------
            -- B6
            --------------------------------------------------

            elseif index == 6 then

                return Vector3.new(
                    -sideSpacing,
                    0,
                    -(distance * 4)
                )

            --------------------------------------------------
            -- B7
            --------------------------------------------------

            elseif index == 7 then

                return Vector3.new(
                    -(sideSpacing * 2),
                    0,
                    -(distance * 4)
                )

            --------------------------------------------------
            -- B8
            --------------------------------------------------

            elseif index == 8 then

                return Vector3.new(
                    -(sideSpacing * 3),
                    0,
                    -(distance * 4)
                )

            --------------------------------------------------
            -- B9
            --------------------------------------------------

            elseif index == 9 then

                return Vector3.new(
                    sideSpacing,
                    0,
                    -(distance * 4)
                )

            --------------------------------------------------
            -- B10
            --------------------------------------------------

            elseif index == 10 then

                return Vector3.new(
                    sideSpacing * 2,
                    0,
                    -(distance * 4)
                )

            --------------------------------------------------
            -- B11
            --------------------------------------------------

            elseif index == 11 then

                return Vector3.new(
                    sideSpacing * 3,
                    0,
                    -(distance * 4)
                )

            end

            return Vector3.zero

        end

        --------------------------------------------------
        -- GET BOT PLAYER
        --------------------------------------------------

        local function getBotPlayer(
            userId
        )

            local targetId =
                tonumber(userId)

            if not targetId then
                return nil
            end

            return Players:GetPlayerByUserId(
                targetId
            )

        end

        --------------------------------------------------
        -- MOVE BOT
        --------------------------------------------------

        local function moveBot(
            botPlayer,
            targetHRP,
            index
        )

            if not botPlayer then
                return
            end

            --------------------------------------------------
            -- CHARACTER
            --------------------------------------------------

            local character =
                botPlayer.Character

            if not character then
                return
            end

            --------------------------------------------------
            -- HUMANOID
            --------------------------------------------------

            local humanoid =
                character:FindFirstChildOfClass(
                    "Humanoid"
                )

            --------------------------------------------------
            -- HRP
            --------------------------------------------------

            local hrp =
                character:FindFirstChild(
                    "HumanoidRootPart"
                )

            if not humanoid or not hrp then
                return
            end

            --------------------------------------------------
            -- HEALTH
            --------------------------------------------------

            if humanoid.Health <= 0 then
                return
            end

            --------------------------------------------------
            -- DISTANCE
            --------------------------------------------------

            local distance =
                getFollowDistance(
                    botPlayer.UserId,
                    LocalPlayer.UserId
                )

            --------------------------------------------------
            -- FORMATION OFFSET
            --------------------------------------------------

            local offset =
                getFormationOffset(
                    index,
                    distance
                )

            --------------------------------------------------
            -- WORLD POSITION
            --------------------------------------------------

            local targetPosition =
                targetHRP.Position

                + targetHRP.CFrame.RightVector
                * offset.X

                + targetHRP.CFrame.UpVector
                * offset.Y

                + targetHRP.CFrame.LookVector
                * offset.Z

            --------------------------------------------------
            -- DIFFERENCE
            --------------------------------------------------

            local difference =
                targetPosition
                - hrp.Position

            local magnitude =
                difference.Magnitude

            --------------------------------------------------
            -- STOP
            --------------------------------------------------

            if magnitude <= stopThreshold then

                humanoid:Move(
                    Vector3.zero
                )

                return

            end

            --------------------------------------------------
            -- MOVE
            --------------------------------------------------

            local direction =
                difference.Unit

            humanoid:Move(
                direction
            )

        end

        --------------------------------------------------
        -- STOP TWO WINGS
        --------------------------------------------------

        local function stopTwoWings()

            --------------------------------------------------
            -- STOP MODE
            --------------------------------------------------

            if _G.BotVars.ActiveMode
                == "twowings" then

                _G.BotVars.ActiveMode = nil

            end

            --------------------------------------------------
            -- DISCONNECT
            --------------------------------------------------

            if twoWingsConnection then

                twoWingsConnection:Disconnect()

                twoWingsConnection = nil

            end

            --------------------------------------------------
            -- REMOVE CONTROLLER
            --------------------------------------------------

            _G.BotVars.ModeControllers.twowings =
                nil

        end

        --------------------------------------------------
        -- START TWO WINGS
        --------------------------------------------------

        local function startTwoWings()

            --------------------------------------------------
            -- ALREADY ACTIVE
            --------------------------------------------------

            if _G.BotVars.ActiveMode
                == "twowings" then

                return

            end

            --------------------------------------------------
            -- STOP OTHER MODES
            --------------------------------------------------

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "twowings"
                    and type(stopFunction)
                    == "function" then

                    pcall(
                        stopFunction
                    )

                end

            end

            --------------------------------------------------
            -- SET ACTIVE MODE
            --------------------------------------------------

            _G.BotVars.ActiveMode =
                "twowings"

            --------------------------------------------------
            -- REGISTER CONTROLLER
            --------------------------------------------------

            _G.BotVars.ModeControllers.twowings =
                stopTwoWings

            --------------------------------------------------
            -- REMOVE OLD CONNECTION
            --------------------------------------------------

            if twoWingsConnection then

                twoWingsConnection:Disconnect()

                twoWingsConnection = nil

            end

            --------------------------------------------------
            -- HEARTBEAT
            --------------------------------------------------

            twoWingsConnection =
                RunService.Heartbeat:Connect(
                    function()

                        --------------------------------------------------
                        -- CHECK ACTIVE MODE
                        --------------------------------------------------

                        if _G.BotVars.ActiveMode
                            ~= "twowings" then

                            stopTwoWings()

                            return

                        end

                        --------------------------------------------------
                        -- GET LOCAL CHARACTER
                        --------------------------------------------------

                        local character,
                            humanoid,
                            targetHRP =
                            getCharacter()

                        if not character
                            or not humanoid
                            or not targetHRP then

                            return

                        end

                        --------------------------------------------------
                        -- HEALTH
                        --------------------------------------------------

                        if humanoid.Health <= 0 then
                            return
                        end

                        --------------------------------------------------
                        -- MOVE ALL BOTS
                        --------------------------------------------------

                        for index, userId in ipairs(
                            botIds
                        ) do

                            local botPlayer =
                                getBotPlayer(
                                    userId
                                )

                            if botPlayer then

                                moveBot(
                                    botPlayer,
                                    targetHRP,
                                    index
                                )

                            end

                        end

                    end
                )

        end

        --------------------------------------------------
        -- COMMAND HANDLER
        --------------------------------------------------

        local function handleCommand(
            message,
            sender
        )

            --------------------------------------------------
            -- VALIDATE SENDER
            --------------------------------------------------

            if not sender then
                return
            end

            --------------------------------------------------
            -- ADMIN ONLY
            --------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end

            --------------------------------------------------
            -- LOWERCASE
            --------------------------------------------------

            local command =
                message:lower()

            --------------------------------------------------
            -- TWO WINGS
            --------------------------------------------------

            if command == "!twowings" then

                startTwoWings()

                return

            end

            --------------------------------------------------
            -- STOP TWO WINGS
            --------------------------------------------------

            if command
                == "!stoptwowings" then

                stopTwoWings()

                return

            end

        end

        --------------------------------------------------
        -- TEXT CHAT
        --------------------------------------------------

        if TextChatService
            and TextChatService.TextChannels then

            local channel =
                TextChatService.TextChannels:
                FindFirstChild(
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

        --------------------------------------------------
        -- FALLBACK CHAT
        --------------------------------------------------

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

        --------------------------------------------------
        -- PLAYER ADDED
        --------------------------------------------------

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

        --------------------------------------------------
        -- CHARACTER RESPAWN
        --------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(
            function()

                task.wait(1)

                if _G.BotVars.ActiveMode
                    == "twowings" then

                    -- Heartbeat akan otomatis
                    -- menggunakan character baru

                end

            end
        )

    end
}