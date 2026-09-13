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

        local forming = false
        local targetPlayer = nil
        local formationConnection = nil

        ----------------------------------------------------------------
        -- FORMATION SETTINGS
        ----------------------------------------------------------------

        -- Jarak garis bot dari Player/Admin
        local adminFormationDistance = 6
        local defaultBotFormationDistance = 5

        -- Jarak antar bot
        local formationSpacing = 4

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
            "11641280895", -- Bot 10
            "11641342530", -- Bot 11
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
        -- STOP FORMATION
        ----------------------------------------------------------------

        local function stopFormation()

            forming = false
            targetPlayer = nil

            if formationConnection then

                formationConnection:Disconnect()
                formationConnection = nil

            end

            if humanoid then
                humanoid.AutoRotate = true
            end

        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.formation =
            stopFormation

        ----------------------------------------------------------------
        -- STOP SEMUA MODE LAIN
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "formation"
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
        -- GET HORIZONTAL OFFSET
        ----------------------------------------------------------------
        --
        -- FORMASI:
        --
        -- BOT 1   BOT 2   BOT 3   BOT 4   ...   BOT 11
        --   ↓       ↓       ↓       ↓              ↓
        --                  PLAYER
        --
        -- Semua bot berada pada SATU GARIS.
        --
        ----------------------------------------------------------------

        local function getHorizontalOffset(myIndex)

            local totalBots =
                #botOrder

            local center =
                (totalBots + 1) / 2

            return (
                myIndex - center
            ) * formationSpacing

        end

        ----------------------------------------------------------------
        -- START FORMATION
        ----------------------------------------------------------------

        local function startFormation(player)

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

            _G.BotVars.ActiveMode =
                "formation"

            ------------------------------------------------------------
            -- STOP CONNECTION LAMA
            ------------------------------------------------------------

            if formationConnection then

                formationConnection:Disconnect()
                formationConnection = nil

            end

            ------------------------------------------------------------
            -- CARI INDEX BOT
            ------------------------------------------------------------

            local myIndex =
                table.find(
                    botOrder,
                    tostring(LocalPlayer.UserId)
                )

            if not myIndex then

                stopFormation()

                return

            end

            ------------------------------------------------------------
            -- AKTIFKAN FORMATION
            ------------------------------------------------------------

            forming = true
            targetPlayer = player

            sendChat("Formation!")

            ------------------------------------------------------------
            -- FORMATION LOOP
            ------------------------------------------------------------

            formationConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- MODE BERUBAH
                        ------------------------------------------------

                        if _G.BotVars.ActiveMode
                            ~= "formation" then

                            stopFormation()

                            return

                        end

                        ------------------------------------------------
                        -- VALIDASI
                        ------------------------------------------------

                        if not forming then
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
                        -- TARGET CHARACTER
                        ------------------------------------------------

                        local targetCharacter =
                            targetPlayer.Character

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

                        ------------------------------------------------
                        -- DISTANCE
                        ------------------------------------------------

                        local distance =
                            defaultBotFormationDistance

                        if Admin:IsAdmin(targetPlayer) then

                            distance =
                                adminFormationDistance

                        end

                        ------------------------------------------------
                        -- SPECIAL DISTANCE
                        ------------------------------------------------

                        local specialDistance =
                            Distance:GetDistance(
                                tostring(LocalPlayer.UserId),
                                tostring(targetPlayer.UserId)
                            )

                        if specialDistance then

                            distance =
                                specialDistance

                        end

                        ------------------------------------------------
                        -- HORIZONTAL OFFSET
                        ------------------------------------------------

                        local horizontalOffset =
                            getHorizontalOffset(
                                myIndex
                            )

                        ------------------------------------------------
                        -- TARGET DIRECTION
                        ------------------------------------------------

                        local lookVector =
                            targetHRP.CFrame.LookVector

                        local rightVector =
                            targetHRP.CFrame.RightVector

                        ------------------------------------------------
                        -- POSISI DEPAN TARGET
                        ------------------------------------------------
                        --
                        -- LookVector = arah depan Player
                        --
                        -- Bot berada di depan Player
                        --

                        local frontPosition =
                            targetHRP.Position
                            +
                            (
                                lookVector
                                *
                                distance
                            )

                        ------------------------------------------------
                        -- POSISI FINAL BOT
                        ------------------------------------------------
                        --
                        -- RightVector digunakan untuk membuat
                        -- garis kiri -> kanan.
                        --

                        local targetPosition =
                            frontPosition
                            +
                            (
                                rightVector
                                *
                                horizontalOffset
                            )

                        ------------------------------------------------
                        -- CEK JARAK
                        ------------------------------------------------

                        local distanceToTarget =
                            (
                                myHRP.Position
                                -
                                targetPosition
                            ).Magnitude

                        ------------------------------------------------
                        -- MENUJU POSISI
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

                        ------------------------------------------------
                        -- MENGHADAP PLAYER / ADMIN
                        ------------------------------------------------

                        local direction =
                            targetHRP.Position
                            -
                            myHRP.Position

                        if direction.Magnitude > 0.01 then

                            myHRP.CFrame =
                                CFrame.lookAt(
                                    myHRP.Position,
                                    myHRP.Position
                                    +
                                    direction.Unit
                                )

                        end

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
            -- HANYA ADMIN
            ------------------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end

            local lower =
                message:lower()

            ------------------------------------------------------------
            -- !FORMATION
            ------------------------------------------------------------

            if lower == "!formation" then

                startFormation(sender)

                return

            end

            ------------------------------------------------------------
            -- !FORMATION PLAYER
            ------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!formation%s+(.+)$"
                )

            if targetName then

                local target =
                    findPlayerByName(
                        targetName
                    )

                if target then

                    startFormation(target)

                end

                return

            end

            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if lower == "!stop" then

                _G.BotVars.ActiveMode = nil

                stopFormation()

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

                if _G.BotVars.ActiveMode
                    == "formation"
                    and targetPlayer then

                    startFormation(
                        targetPlayer
                    )

                end

            end
        )

    end
}