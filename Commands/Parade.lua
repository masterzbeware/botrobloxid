-- Parade.lua
-- Formasi parade 3x3 untuk 9 bot

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
        -- GLOBAL
        ----------------------------------------------------------------

        _G.BotVars = _G.BotVars or {}
        _G.BotVars.ModeControllers = _G.BotVars.ModeControllers or {}

        ----------------------------------------------------------------
        -- ADMIN
        ----------------------------------------------------------------

        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        ----------------------------------------------------------------
        -- BOT ORDER
        ----------------------------------------------------------------

        local botOrder = {

            "11611503633", -- Bot 1
            "11611534165", -- Bot 2
            "11611567975", -- Bot 3
            "11611562042", -- Bot 4
            "11611591921", -- Bot 5
            "11122806815", -- Bot 6
            "11122806817", -- Bot 7
            "11122687468", -- Bot 8
            "11122854402", -- Bot 9

        }

        ----------------------------------------------------------------
        -- FORMATION SETTINGS
        ----------------------------------------------------------------

        -- Jarak antar bot kiri/kanan
        local columnSpacing = 4

        -- Jarak antar baris depan/belakang
        local rowSpacing = 4

        -- Jarak formasi dari admin
        local formationDistance = 2

        -- Jarak perjalanan parade
        local paradeDistance = 10

        -- Kecepatan bot
        local moveThreshold = 1

        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local paradeConnection = nil

        local paradeActive = false

        -- 1 = maju
        -- -1 = kembali
        local paradeDirection = 1

        -- kiri/kanan
        local paradeSide = 0

        ----------------------------------------------------------------
        -- CHARACTER
        ----------------------------------------------------------------

        local humanoid
        local myHRP

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
        -- CHAT
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
        -- GET BOT INDEX
        ----------------------------------------------------------------

        local function getBotIndex()

            return table.find(
                botOrder,
                tostring(LocalPlayer.UserId)
            )

        end

        ----------------------------------------------------------------
        -- FORMATION POSITION
        ----------------------------------------------------------------
        --
        -- Contoh:
        --
        --       ADMIN
        --
        --    1     2     3
        --    4     5     6
        --    7     8     9
        --
        ----------------------------------------------------------------

        local function getFormationOffset(index)

            if not index then
                return Vector3.zero
            end

            local row =
                math.floor((index - 1) / 3)

            local column =
                (index - 1) % 3

            local x =
                (column - 1) * columnSpacing

            local z =
                row * rowSpacing

            return Vector3.new(
                x,
                0,
                z
            )

        end

        ----------------------------------------------------------------
        -- STOP PARADE
        ----------------------------------------------------------------

        local function stopParade()

            paradeActive = false

            if paradeConnection then

                paradeConnection:Disconnect()
                paradeConnection = nil

            end

            if humanoid then
                humanoid.AutoRotate = true
            end

        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.parade = stopParade

        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "parade"
                    and type(stopFunction) == "function" then

                    pcall(stopFunction)

                end

            end

        end

        ----------------------------------------------------------------
        -- CALCULATE PARADE TARGET
        ----------------------------------------------------------------

        local function getParadeTarget(
            adminHRP,
            botIndex
        )

            if not adminHRP then
                return nil
            end

            local formationOffset =
                getFormationOffset(botIndex)

            ------------------------------------------------------------
            -- POSISI DASAR FORMASI
            ------------------------------------------------------------

            local basePosition =
                adminHRP.Position
                -
                (
                    adminHRP.CFrame.LookVector
                    *
                    formationDistance
                )

            ------------------------------------------------------------
            -- ARAH PARADE
            ------------------------------------------------------------

            local movementOffset =
                adminHRP.CFrame.LookVector
                *
                (
                    paradeDistance
                    * paradeDirection
                )

            ------------------------------------------------------------
            -- SIDE
            ------------------------------------------------------------

            local sideOffset =
                adminHRP.CFrame.RightVector
                *
                (
                    paradeSide * 8
                )

            ------------------------------------------------------------
            -- FORMATION
            ------------------------------------------------------------

            local rightOffset =
                adminHRP.CFrame.RightVector
                *
                formationOffset.X

            local backwardOffset =
                adminHRP.CFrame.LookVector
                *
                formationOffset.Z

            return
                basePosition
                +
                movementOffset
                +
                rightOffset
                -
                backwardOffset
                +
                sideOffset

        end

        ----------------------------------------------------------------
        -- START PARADE
        ----------------------------------------------------------------

        local function startParade(adminPlayer)

            if not adminPlayer then
                return
            end

            ------------------------------------------------------------
            -- ADMIN CHECK
            ------------------------------------------------------------

            if not Admin:IsAdmin(adminPlayer) then
                return
            end

            ------------------------------------------------------------
            -- STOP MODE LAIN
            ------------------------------------------------------------

            stopOtherModes()

            ------------------------------------------------------------
            -- ACTIVE MODE
            ------------------------------------------------------------

            _G.BotVars.ActiveMode = "parade"

            ------------------------------------------------------------
            -- RESET CONNECTION
            ------------------------------------------------------------

            if paradeConnection then

                paradeConnection:Disconnect()
                paradeConnection = nil

            end

            paradeActive = true
            paradeDirection = 1
            paradeSide = 0

            sendChat("Yes, Sir!")

            ------------------------------------------------------------
            -- BOT INDEX
            ------------------------------------------------------------

            local myIndex =
                getBotIndex()

            if not myIndex then

                stopParade()

                return

            end

            ------------------------------------------------------------
            -- PARADE LOOP
            ------------------------------------------------------------

            paradeConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- MODE CHECK
                        ------------------------------------------------

                        if _G.BotVars.ActiveMode ~= "parade" then

                            stopParade()

                            return

                        end

                        if not paradeActive then
                            return
                        end

                        ------------------------------------------------
                        -- CHARACTER CHECK
                        ------------------------------------------------

                        if not humanoid
                            or not myHRP then

                            return

                        end

                        ------------------------------------------------
                        -- ADMIN CHARACTER
                        ------------------------------------------------

                        local adminCharacter =
                            adminPlayer.Character

                        if not adminCharacter then
                            return
                        end

                        local adminHRP =
                            adminCharacter:FindFirstChild(
                                "HumanoidRootPart"
                            )

                        if not adminHRP then
                            return
                        end

                        ------------------------------------------------
                        -- TARGET
                        ------------------------------------------------

                        local targetPosition =
                            getParadeTarget(
                                adminHRP,
                                myIndex
                            )

                        if not targetPosition then
                            return
                        end

                        ------------------------------------------------
                        -- DISTANCE
                        ------------------------------------------------

                        local distance =
                            (
                                myHRP.Position
                                -
                                targetPosition
                            ).Magnitude

                        ------------------------------------------------
                        -- MOVE
                        ------------------------------------------------

                        if distance > moveThreshold then

                            humanoid.AutoRotate = true

                            humanoid:MoveTo(
                                targetPosition
                            )

                            return

                        end

                        ------------------------------------------------
                        -- FORMATION LOCK
                        ------------------------------------------------

                        humanoid.AutoRotate = false

                        ------------------------------------------------
                        -- MENGHADAP ARAH ADMIN
                        ------------------------------------------------

                        local lookDirection =
                            adminHRP.CFrame.LookVector

                        myHRP.CFrame =
                            CFrame.lookAt(
                                myHRP.Position,
                                myHRP.Position
                                +
                                lookDirection
                            )

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

            ------------------------------------------------------------
            -- ADMIN ONLY
            ------------------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end

            local lower =
                message:lower()

            ------------------------------------------------------------
            -- !PARADE
            ------------------------------------------------------------

            if lower == "!parade" then

                startParade(sender)

                return

            end

            ------------------------------------------------------------
            -- !PARADE STOP
            ------------------------------------------------------------

            if lower == "!parade stop"
                or lower == "!parade off" then

                _G.BotVars.ActiveMode = nil

                stopParade()

                return

            end

            ------------------------------------------------------------
            -- !PARADE LEFT
            ------------------------------------------------------------

            if lower == "!parade left" then

                if paradeActive then

                    paradeSide = -1

                end

                return

            end

            ------------------------------------------------------------
            -- !PARADE RIGHT
            ------------------------------------------------------------

            if lower == "!parade right" then

                if paradeActive then

                    paradeSide = 1

                end

                return

            end

            ------------------------------------------------------------
            -- !PARADE FORWARD
            ------------------------------------------------------------

            if lower == "!parade forward" then

                if paradeActive then

                    paradeDirection = 1

                end

                return

            end

            ------------------------------------------------------------
            -- !PARADE BACK
            ------------------------------------------------------------

            if lower == "!parade back" then

                if paradeActive then

                    paradeDirection = -1

                end

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

                if _G.BotVars.ActiveMode == "parade" then

                    local adminPlayer = nil

                    for _, player in ipairs(
                        Players:GetPlayers()
                    ) do

                        if Admin:IsAdmin(player) then

                            adminPlayer = player
                            break

                        end

                    end

                    if adminPlayer then

                        startParade(
                            adminPlayer
                        )

                    end

                end

            end
        )

        print("✅ Parade.lua loaded")

    end
}