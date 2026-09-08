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

        local frontlining = false
        local targetPlayer = nil
        local frontlineConnection = nil

        ----------------------------------------------------------------
        -- FORMATION CONFIG
        ----------------------------------------------------------------

        -- Jarak formasi dari target
        local formationDistance = 5

        -- Jarak antar Bot kiri-kanan
        local formationSpacing = 3

        -- Tinggi tambahan posisi Bot
        local formationHeight = 0

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
            "11001607521", -- Bot 12
            "11001608049", -- Bot 13
            "11001625681", -- Bot 14,

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
        -- STOP FRONTLINE
        ----------------------------------------------------------------

        local function stopFrontline()

            frontlining = false
            targetPlayer = nil

            if frontlineConnection then

                frontlineConnection:Disconnect()
                frontlineConnection = nil

            end

            if humanoid then

                humanoid.AutoRotate = true

            end

        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.frontline =
            stopFrontline

        ----------------------------------------------------------------
        -- STOP SEMUA MODE LAIN
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "frontline"
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
        -- GET BOT INDEX
        ----------------------------------------------------------------

        local function getBotIndex()

            return table.find(
                botOrder,
                tostring(LocalPlayer.UserId)
            )

        end

        ----------------------------------------------------------------
        -- CALCULATE FORMATION POSITION
        ----------------------------------------------------------------

        local function getFormationPosition(
            targetHRP,
            botIndex
        )

            local totalBots =
                #botOrder

            ------------------------------------------------------------
            -- JUMLAH POSISI
            ------------------------------------------------------------

            if totalBots <= 0 then
                return targetHRP.Position
            end

            ------------------------------------------------------------
            -- POSISI TENGAH
            ------------------------------------------------------------

            local center =
                (totalBots + 1) / 2

            ------------------------------------------------------------
            -- OFFSET KIRI / KANAN
            ------------------------------------------------------------

            local horizontalOffset =
                (botIndex - center)
                * formationSpacing

            ------------------------------------------------------------
            -- DEPAN TARGET
            --
            -- LookVector = arah yang sedang dilihat target
            --
            -- + LookVector = depan
            ------------------------------------------------------------

            local frontPosition =
                targetHRP.Position
                +
                (
                    targetHRP.CFrame.LookVector
                    * formationDistance
                )

            ------------------------------------------------------------
            -- KANAN TARGET
            --
            -- RightVector:
            -- Bot dengan offset positif berada di kanan
            -- Bot dengan offset negatif berada di kiri
            ------------------------------------------------------------

            local sideOffset =
                targetHRP.CFrame.RightVector
                * horizontalOffset

            ------------------------------------------------------------
            -- FINAL POSITION
            ------------------------------------------------------------

            local finalPosition =
                frontPosition
                +
                sideOffset
                +
                Vector3.new(
                    0,
                    formationHeight,
                    0
                )

            return finalPosition

        end

        ----------------------------------------------------------------
        -- START FRONTLINE
        ----------------------------------------------------------------

        local function startFrontline(player)

            if not player then
                return
            end

            ------------------------------------------------------------
            -- STOP MODE LAIN
            ------------------------------------------------------------

            stopOtherModes()

            ------------------------------------------------------------
            -- ACTIVE MODE
            ------------------------------------------------------------

            _G.BotVars.ActiveMode =
                "frontline"

            ------------------------------------------------------------
            -- STOP CONNECTION LAMA
            ------------------------------------------------------------

            if frontlineConnection then

                frontlineConnection:Disconnect()
                frontlineConnection = nil

            end

            ------------------------------------------------------------
            -- BOT INDEX
            ------------------------------------------------------------

            local myIndex =
                getBotIndex()

            if not myIndex then

                stopFrontline()

                return

            end

            ------------------------------------------------------------
            -- SET TARGET
            ------------------------------------------------------------

            frontlining = true
            targetPlayer = player

            ------------------------------------------------------------
            -- CHAT
            ------------------------------------------------------------

            sendChat("Yes, Sir!")

            ------------------------------------------------------------
            -- FRONTLINE LOOP
            ------------------------------------------------------------

            frontlineConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- MODE CHECK
                        ------------------------------------------------

                        if _G.BotVars.ActiveMode
                            ~= "frontline" then

                            stopFrontline()

                            return

                        end

                        ------------------------------------------------
                        -- VALIDASI
                        ------------------------------------------------

                        if not frontlining then
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
                        -- FORMATION POSITION
                        ------------------------------------------------

                        local targetPosition =
                            getFormationPosition(
                                targetHRP,
                                myIndex
                            )

                        ------------------------------------------------
                        -- DISTANCE CHECK
                        ------------------------------------------------

                        local distanceToTarget =
                            (
                                myHRP.Position
                                -
                                targetPosition
                            ).Magnitude

                        ------------------------------------------------
                        -- GERAK MENUJU FORMASI
                        ------------------------------------------------

                        if distanceToTarget > 1.5 then

                            humanoid.AutoRotate = true

                            humanoid:MoveTo(
                                targetPosition
                            )

                            return

                        end

                        ------------------------------------------------
                        -- SUDAH DI POSISI
                        ------------------------------------------------

                        humanoid.AutoRotate = false

                        ------------------------------------------------
                        -- HADAP KE TARGET
                        ------------------------------------------------

                        local direction =
                            targetHRP.Position
                            -
                            myHRP.Position

                        ------------------------------------------------
                        -- HILANGKAN KOMPONEN Y
                        -- Supaya Bot tidak menengadah/menunduk
                        ------------------------------------------------

                        direction =
                            Vector3.new(
                                direction.X,
                                0,
                                direction.Z
                            )

                        if direction.Magnitude > 0.01 then

                            direction =
                                direction.Unit

                            myHRP.CFrame =
                                CFrame.lookAt(
                                    myHRP.Position,
                                    myHRP.Position
                                    + direction
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
            -- ADMIN CHECK
            ------------------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end

            local lower =
                message:lower()

            ------------------------------------------------------------
            -- !FRONTLINE
            --
            -- Formasi di depan Admin
            ------------------------------------------------------------

            if lower == "!frontline" then

                startFrontline(sender)

                return

            end

            ------------------------------------------------------------
            -- !FRONTLINE PLAYER
            --
            -- Formasi di depan Player tertentu
            ------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!frontline%s+(.+)$"
                )

            if targetName then

                local target =
                    findPlayerByName(
                        targetName
                    )

                if target then

                    startFrontline(target)

                end

                return

            end

            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if lower == "!stop"
                or lower == "!unfrontline" then

                _G.BotVars.ActiveMode = nil

                stopFrontline()

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

                --------------------------------------------------------
                -- KEMBALI KE FRONTLINE
                --------------------------------------------------------

                if _G.BotVars.ActiveMode
                    == "frontline"
                    and targetPlayer then

                    startFrontline(
                        targetPlayer
                    )

                end

            end
        )

    end
}