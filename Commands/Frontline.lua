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

        local vars = _G.BotVars

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
        -- CHARACTER
        ----------------------------------------------------------------

        local humanoid
        local myHRP

        ----------------------------------------------------------------
        -- STATE
        ----------------------------------------------------------------

        local frontlineActive = false
        local frontlineConnection = nil
        local targetPlayer = nil

        ----------------------------------------------------------------
        -- FORMATION SETTINGS
        ----------------------------------------------------------------

        -- Jarak Bot dari Player
        local formationDistance = 5

        -- Jarak antar Bot kiri / kanan
        local formationSpacing = 3

        -- Jarak minimum sebelum dianggap sudah sampai
        local stopThreshold = 1.5

        -- Tinggi posisi formasi
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
            "11001625681", -- Bot 14

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
                character:WaitForChild(
                    "HumanoidRootPart"
                )

            humanoid.AutoRotate = true

        end

        updateCharacter()

        ----------------------------------------------------------------
        -- SEND CHAT
        ----------------------------------------------------------------

        local function sendChat(message)

            if not message then
                return
            end

            local success = false

            ------------------------------------------------------------
            -- TEXT CHAT
            ------------------------------------------------------------

            if TextChatService
                and TextChatService.TextChannels then

                local channel =
                    TextChatService.TextChannels:FindFirstChild(
                        "RBXGeneral"
                    )

                if channel then

                    pcall(function()

                        channel:SendAsync(
                            message
                        )

                    end)

                    success = true

                end

            end

            ------------------------------------------------------------
            -- OLD CHAT FALLBACK
            ------------------------------------------------------------

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
        -- STOP FRONTLINE
        ----------------------------------------------------------------

        local function stopFrontline()

            frontlineActive = false
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

        vars.ModeControllers.frontline =
            stopFrontline

        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                vars.ModeControllers
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

            if not name or name == "" then
                return nil
            end

            name = name:lower()

            ------------------------------------------------------------
            -- EXACT MATCH
            ------------------------------------------------------------

            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if player.Name:lower() == name
                    or player.DisplayName:lower() == name then

                    return player

                end

            end

            ------------------------------------------------------------
            -- PARTIAL MATCH
            ------------------------------------------------------------

            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if player.Name:lower():find(
                    name,
                    1,
                    true
                )
                    or player.DisplayName:lower():find(
                        name,
                        1,
                        true
                    ) then

                    return player

                end

            end

            return nil

        end

        ----------------------------------------------------------------
        -- GET BOT DISTANCE
        ----------------------------------------------------------------

        local function getBotDistance(player)

            local distance = 1

            ------------------------------------------------------------
            -- ADMIN DEFAULT
            ------------------------------------------------------------

            if Admin:IsAdmin(player) then

                distance = 1

            end

            ------------------------------------------------------------
            -- SPECIAL DISTANCE
            ------------------------------------------------------------

            local specialDistance =
                Distance:GetDistance(
                    tostring(LocalPlayer.UserId),
                    tostring(player.UserId)
                )

            if specialDistance then

                distance = specialDistance

            end

            return distance

        end

        ----------------------------------------------------------------
        -- GET FRONTLINE POSITION
        ----------------------------------------------------------------
        --
        -- FORMASI:
        --
        -- B1   B2   B3   B4   B5   B6 ... B14
        --
        --                 👤
        --               PLAYER
        --
        -- Semua Bot berada di DEPAN Player.
        --
        ----------------------------------------------------------------

        local function getFrontlinePosition(
            myIndex,
            targetHRP,
            distance
        )

            if not myIndex
                or not targetHRP
                or not distance then

                return nil

            end

            ------------------------------------------------------------
            -- POSISI TENGAH
            ------------------------------------------------------------

            local totalBots =
                #botOrder

            local center =
                (totalBots + 1) / 2

            ------------------------------------------------------------
            -- OFFSET KIRI / KANAN
            ------------------------------------------------------------

            local horizontalOffset =
                (myIndex - center)
                * formationSpacing

            ------------------------------------------------------------
            -- DEPAN PLAYER
            ------------------------------------------------------------

            local frontPosition =
                targetHRP.Position
                +
                (
                    targetHRP.CFrame.LookVector
                    * (
                        formationDistance
                        + distance
                    )
                )

            ------------------------------------------------------------
            -- KIRI / KANAN
            ------------------------------------------------------------

            local sidePosition =
                targetHRP.CFrame.RightVector
                * horizontalOffset

            ------------------------------------------------------------
            -- FINAL POSITION
            ------------------------------------------------------------

            return frontPosition
                + sidePosition
                + Vector3.new(
                    0,
                    formationHeight,
                    0
                )

        end

        ----------------------------------------------------------------
        -- COPY TARGET ROTATION
        ----------------------------------------------------------------
        --
        -- INI BAGIAN PENTING.
        --
        -- Bot akan memiliki rotasi yang SAMA PERSIS dengan target.
        --
        ----------------------------------------------------------------

        local function copyTargetRotation(
            targetHRP
        )

            if not targetHRP
                or not myHRP then

                return

            end

            local targetRotation =
                targetHRP.CFrame
                - targetHRP.Position

            myHRP.CFrame =
                CFrame.new(
                    myHRP.Position
                )
                * targetRotation

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

            vars.ActiveMode =
                "frontline"

            ------------------------------------------------------------
            -- DISCONNECT LOOP LAMA
            ------------------------------------------------------------

            if frontlineConnection then

                frontlineConnection:Disconnect()
                frontlineConnection = nil

            end

            ------------------------------------------------------------
            -- STATE
            ------------------------------------------------------------

            frontlineActive = true
            targetPlayer = player

            ------------------------------------------------------------
            -- CHAT
            ------------------------------------------------------------

            sendChat("Yes, Sir!")

            ------------------------------------------------------------
            -- FIND BOT INDEX
            ------------------------------------------------------------

            local myIndex =
                table.find(
                    botOrder,
                    tostring(LocalPlayer.UserId)
                )

            if not myIndex then

                stopFrontline()

                return

            end

            ------------------------------------------------------------
            -- DEBUG
            ------------------------------------------------------------

            print(
                "[FRONTLINE]",
                "Bot Index:",
                myIndex,
                "UserId:",
                LocalPlayer.UserId
            )

            ------------------------------------------------------------
            -- HEARTBEAT
            ------------------------------------------------------------

            frontlineConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- MODE CHECK
                        ------------------------------------------------

                        if vars.ActiveMode
                            ~= "frontline" then

                            stopFrontline()

                            return

                        end

                        ------------------------------------------------
                        -- ACTIVE CHECK
                        ------------------------------------------------

                        if not frontlineActive then
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
                        -- TARGET CHECK
                        ------------------------------------------------

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

                        ------------------------------------------------
                        -- TARGET HRP
                        ------------------------------------------------

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

                        local botDistance =
                            getBotDistance(
                                targetPlayer
                            )

                        ------------------------------------------------
                        -- POSITION
                        ------------------------------------------------

                        local targetPosition =
                            getFrontlinePosition(
                                myIndex,
                                targetHRP,
                                botDistance
                            )

                        if not targetPosition then
                            return
                        end

                        ------------------------------------------------
                        -- DISTANCE TO FORMATION
                        ------------------------------------------------

                        local distanceToTarget =
                            (
                                myHRP.Position
                                -
                                targetPosition
                            ).Magnitude

                        ------------------------------------------------
                        -- MOVE
                        ------------------------------------------------

                        if distanceToTarget
                            > stopThreshold then

                            ------------------------------------------------
                            -- BIARKAN ROBLOX MEMUTAR SAAT BERJALAN
                            ------------------------------------------------

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
                        -- COPY ROTATION TARGET
                        ------------------------------------------------
                        --
                        -- BUKAN LOOKAT.
                        --
                        -- COPY CFrame rotation langsung.
                        --
                        ------------------------------------------------

                        copyTargetRotation(
                            targetHRP
                        )

                    end
                )

        end

        ----------------------------------------------------------------
        -- HANDLE COMMAND
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
            -- !FRONTLINE
            ------------------------------------------------------------

            if lower == "!frontline" then

                startFrontline(sender)

                return

            end

            ------------------------------------------------------------
            -- !FRONTLINE PLAYER
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

                    startFrontline(
                        target
                    )

                end

                return

            end

            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if lower == "!stop"
                or lower == "!unfrontline" then

                vars.ActiveMode = nil

                stopFrontline()

                return

            end

        end

        ----------------------------------------------------------------
        -- TEXT CHAT SERVICE
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
        -- OLD CHAT
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
        -- NEW PLAYER
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
        -- RESPAWN
        ----------------------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(
            function()

                task.wait(1)

                updateCharacter()

                --------------------------------------------------------
                -- RESTART FRONTLINE
                --------------------------------------------------------

                if vars.ActiveMode
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