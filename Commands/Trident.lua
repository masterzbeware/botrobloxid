return {
    Execute = function()

        --------------------------------------------------
        -- SERVICES
        --------------------------------------------------

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            return
        end

        --------------------------------------------------
        -- GLOBAL MODE SYSTEM
        --------------------------------------------------

        _G.BotVars = _G.BotVars or {}

        _G.BotVars.ModeControllers =
            _G.BotVars.ModeControllers or {}

        local vars = _G.BotVars

        --------------------------------------------------
        -- LOAD ADMIN
        --------------------------------------------------

        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        --------------------------------------------------
        -- LOAD DISTANCE
        --------------------------------------------------

        local Distance = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
        ))()

        --------------------------------------------------
        -- CHARACTER
        --------------------------------------------------

        local humanoid
        local myHRP

        --------------------------------------------------
        -- STATE
        --------------------------------------------------

        local tridentActive = false
        local tridentConnection = nil
        local targetPlayer = nil

        --------------------------------------------------
        -- BOT ORDER
        --------------------------------------------------
        --
        -- BOT 1 - BOT 11 IKUT FORMASI
        --
        -- BOT 1-4  = FRONT / SPEARHEAD
        -- BOT 5-7  = CIRCLE KIRI
        -- BOT 8-11 = CIRCLE KANAN
        --
        --------------------------------------------------

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

        --------------------------------------------------
        -- FORMATION SETTINGS
        --------------------------------------------------

        -- Jarak dasar dari Player
        local baseDistance = 5

        -- Jarak antara BOT 1-2 dan BOT 3-4
        local rowSpacing = 3

        -- Lebar formasi depan
        local sideSpacing = 3

        -- Jarak circle dari formasi depan
        local circleDistance = 8

        -- Radius circle
        local circleRadius = 4

        -- Jarak minimum sebelum dianggap sampai
        local stopThreshold = 1.5

        --------------------------------------------------
        -- UPDATE CHARACTER
        --------------------------------------------------

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

        --------------------------------------------------
        -- SEND CHAT
        --------------------------------------------------

        local function sendChat(message)

            if not message then
                return
            end

            local success = false

            --------------------------------------------------
            -- TEXT CHAT
            --------------------------------------------------

            if TextChatService
                and TextChatService.TextChannels then

                local channel =
                    TextChatService.TextChannels
                    :FindFirstChild("RBXGeneral")

                if channel then

                    pcall(function()

                        channel:SendAsync(message)

                    end)

                    success = true

                end

            end

            --------------------------------------------------
            -- OLD CHAT FALLBACK
            --------------------------------------------------

            if not success then

                pcall(function()

                    local chatEvents =
                        ReplicatedStorage
                        :FindFirstChild(
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

        --------------------------------------------------
        -- STOP TRIDENT
        --------------------------------------------------

        local function stopTrident()

            tridentActive = false
            targetPlayer = nil

            if tridentConnection then

                tridentConnection:Disconnect()
                tridentConnection = nil

            end

            if humanoid then

                humanoid.AutoRotate = true

            end

        end

        --------------------------------------------------
        -- REGISTER CONTROLLER
        --------------------------------------------------

        vars.ModeControllers.trident =
            stopTrident

        --------------------------------------------------
        -- STOP OTHER MODES
        --------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in
                pairs(vars.ModeControllers) do

                if name ~= "trident"
                    and type(stopFunction) == "function" then

                    pcall(stopFunction)

                end

            end

        end

        --------------------------------------------------
        -- FIND PLAYER
        --------------------------------------------------

        local function findPlayerByName(name)

            if not name or name == "" then
                return nil
            end

            name = name:lower()

            --------------------------------------------------
            -- EXACT MATCH
            --------------------------------------------------

            for _, player in
                ipairs(Players:GetPlayers()) do

                if player.Name:lower() == name
                    or player.DisplayName:lower() == name then

                    return player

                end

            end

            --------------------------------------------------
            -- PARTIAL MATCH
            --------------------------------------------------

            for _, player in
                ipairs(Players:GetPlayers()) do

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

        --------------------------------------------------
        -- GET DISTANCE
        --------------------------------------------------

        local function getBotDistance(player)

            local distance = baseDistance

            --------------------------------------------------
            -- ADMIN DISTANCE
            --------------------------------------------------

            if Admin:IsAdmin(player) then

                distance = baseDistance

            end

            --------------------------------------------------
            -- SPECIAL DISTANCE
            --------------------------------------------------

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

        --------------------------------------------------
        -- GET TRIDENT POSITION
        --------------------------------------------------
        --
        -- FORMASI:
        --
        --
        --                         PLAYER
        --                           👤
        --
        --                      B1      B2
        --                       🧍    🧍
        --
        --                   B3          B4
        --                    🧍        🧍
        --
        --
        --            CIRCLE KIRI       CIRCLE KANAN
        --
        --                 B5              B8
        --              B6    B7        B9    B10
        --                 B?              B11
        --
        --              TENGAH BELAKANG KOSONG
        --
        --------------------------------------------------

        local function getTridentPosition(
            myIndex,
            targetHRP,
            distance
        )

            if not myIndex
                or not targetHRP
                or not distance then

                return nil

            end

            --------------------------------------------------
            -- LOCAL AXIS
            --------------------------------------------------

            local forward =
                targetHRP.CFrame.LookVector

            local right =
                targetHRP.CFrame.RightVector

            local origin =
                targetHRP.Position

            --------------------------------------------------
            -- BOT 1
            -- DEPAN KIRI
            --------------------------------------------------

            if myIndex == 1 then

                return origin
                    + forward * distance
                    - right * sideSpacing

            end

            --------------------------------------------------
            -- BOT 2
            -- DEPAN KANAN
            --------------------------------------------------

            if myIndex == 2 then

                return origin
                    + forward * distance
                    + right * sideSpacing

            end

            --------------------------------------------------
            -- BOT 3
            -- BARIS KEDUA KIRI
            --------------------------------------------------

            if myIndex == 3 then

                return origin
                    + forward
                    * (distance - rowSpacing)
                    - right
                    * (sideSpacing * 1.8)

            end

            --------------------------------------------------
            -- BOT 4
            -- BARIS KEDUA KANAN
            --------------------------------------------------

            if myIndex == 4 then

                return origin
                    + forward
                    * (distance - rowSpacing)
                    + right
                    * (sideSpacing * 1.8)

            end

            --------------------------------------------------
            -- CIRCLE KIRI
            --------------------------------------------------
            --
            -- BOT 5-7
            --
            -- Posisi berada di sisi kiri.
            --
            --------------------------------------------------

            if myIndex >= 5
                and myIndex <= 7 then

                local circleIndex =
                    myIndex - 5

                local total =
                    3

                local angle =
                    math.rad(
                        135
                        + (
                            90
                            * circleIndex
                            / (total - 1)
                        )
                    )

                local center =
                    origin
                    + forward
                    * (
                        distance
                        - circleDistance
                    )
                    - right
                    * circleDistance

                return center
                    + right
                    * (
                        math.cos(angle)
                        * circleRadius
                    )
                    + forward
                    * (
                        math.sin(angle)
                        * circleRadius
                    )

            end

            --------------------------------------------------
            -- CIRCLE KANAN
            --------------------------------------------------
            --
            -- BOT 8-11
            --
            -- Posisi berada di sisi kanan.
            --
            --------------------------------------------------

            if myIndex >= 8
                and myIndex <= 11 then

                local circleIndex =
                    myIndex - 8

                local total =
                    4

                local angle =
                    math.rad(
                        45
                        + (
                            90
                            * circleIndex
                            / (total - 1)
                        )
                    )

                local center =
                    origin
                    + forward
                    * (
                        distance
                        - circleDistance
                    )
                    + right
                    * circleDistance

                return center
                    + right
                    * (
                        math.cos(angle)
                        * circleRadius
                    )
                    + forward
                    * (
                        math.sin(angle)
                        * circleRadius
                    )

            end

            --------------------------------------------------
            -- INVALID INDEX
            --------------------------------------------------

            return nil

        end

        --------------------------------------------------
        -- START TRIDENT
        --------------------------------------------------

        local function startTrident(player)

            if not player then
                return
            end

            --------------------------------------------------
            -- STOP MODE LAIN
            --------------------------------------------------

            stopOtherModes()

            --------------------------------------------------
            -- ACTIVE MODE
            --------------------------------------------------

            vars.ActiveMode = "trident"

            --------------------------------------------------
            -- DISCONNECT OLD LOOP
            --------------------------------------------------

            if tridentConnection then

                tridentConnection:Disconnect()
                tridentConnection = nil

            end

            --------------------------------------------------
            -- STATE
            --------------------------------------------------

            tridentActive = true
            targetPlayer = player

            --------------------------------------------------
            -- CHAT
            --------------------------------------------------

            sendChat("Yes, Sir!")

            --------------------------------------------------
            -- FIND BOT INDEX
            --------------------------------------------------

            local myIndex =
                table.find(
                    botOrder,
                    tostring(LocalPlayer.UserId)
                )

            --------------------------------------------------
            -- BOT TIDAK TERDAFTAR
            --------------------------------------------------

            if not myIndex then

                print(
                    "[TRIDENT] Bot tidak termasuk formasi:",
                    LocalPlayer.Name,
                    LocalPlayer.UserId
                )

                stopTrident()

                return

            end

            --------------------------------------------------
            -- DEBUG
            --------------------------------------------------

            print(
                "[TRIDENT]",
                "Bot Index:",
                myIndex,
                "UserId:",
                LocalPlayer.UserId
            )

            --------------------------------------------------
            -- HEARTBEAT
            --------------------------------------------------

            tridentConnection =
                RunService.Heartbeat:Connect(
                    function()

                        --------------------------------------------------
                        -- MODE CHANGED
                        --------------------------------------------------

                        if vars.ActiveMode
                            ~= "trident" then

                            stopTrident()

                            return

                        end

                        --------------------------------------------------
                        -- ACTIVE CHECK
                        --------------------------------------------------

                        if not tridentActive then
                            return
                        end

                        --------------------------------------------------
                        -- CHARACTER CHECK
                        --------------------------------------------------

                        if not humanoid
                            or not myHRP then

                            return

                        end

                        --------------------------------------------------
                        -- TARGET CHECK
                        --------------------------------------------------

                        if not targetPlayer then
                            return
                        end

                        --------------------------------------------------
                        -- TARGET CHARACTER
                        --------------------------------------------------

                        local targetCharacter =
                            targetPlayer.Character

                        if not targetCharacter then
                            return
                        end

                        --------------------------------------------------
                        -- TARGET HRP
                        --------------------------------------------------

                        local targetHRP =
                            targetCharacter:FindFirstChild(
                                "HumanoidRootPart"
                            )

                        if not targetHRP then
                            return
                        end

                        --------------------------------------------------
                        -- DISTANCE
                        --------------------------------------------------

                        local distance =
                            getBotDistance(
                                targetPlayer
                            )

                        --------------------------------------------------
                        -- FORMATION POSITION
                        --------------------------------------------------

                        local targetPosition =
                            getTridentPosition(
                                myIndex,
                                targetHRP,
                                distance
                            )

                        if not targetPosition then
                            return
                        end

                        --------------------------------------------------
                        -- DISTANCE TO TARGET POSITION
                        --------------------------------------------------

                        local distanceToTarget =
                            (
                                myHRP.Position
                                - targetPosition
                            ).Magnitude

                        --------------------------------------------------
                        -- MOVE
                        --------------------------------------------------

                        if distanceToTarget
                            > stopThreshold then

                            humanoid.AutoRotate = true

                            humanoid:MoveTo(
                                targetPosition
                            )

                            return

                        end

                        --------------------------------------------------
                        -- REACHED FORMATION
                        --------------------------------------------------

                        humanoid.AutoRotate = false

                        --------------------------------------------------
                        -- COPY PLAYER ROTATION
                        --------------------------------------------------

                        local targetRotation =
                            targetHRP.CFrame
                            - targetHRP.Position

                        myHRP.CFrame =
                            CFrame.new(
                                myHRP.Position
                            )
                            * targetRotation

                    end
                )

        end

        --------------------------------------------------
        -- HANDLE COMMAND
        --------------------------------------------------

        local function handleCommand(
            message,
            sender
        )

            --------------------------------------------------
            -- ADMIN ONLY
            --------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end

            local lower =
                message:lower()

            --------------------------------------------------
            -- !TRIDENT
            --------------------------------------------------

            if lower == "!trident" then

                startTrident(sender)

                return

            end

            --------------------------------------------------
            -- !TRIDENT PLAYER
            --------------------------------------------------

            local targetName =
                lower:match(
                    "^!trident%s+(.+)$"
                )

            if targetName then

                local target =
                    findPlayerByName(
                        targetName
                    )

                if target then

                    startTrident(
                        target
                    )

                end

                return

            end

            --------------------------------------------------
            -- !STOP
            --------------------------------------------------

            if lower == "!stop"
                or lower == "!untrident" then

                vars.ActiveMode = nil

                stopTrident()

                return

            end

        end

        --------------------------------------------------
        -- TEXT CHAT SERVICE
        --------------------------------------------------

        if TextChatService
            and TextChatService.TextChannels then

            local channel =
                TextChatService.TextChannels
                :FindFirstChild("RBXGeneral")

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
        -- OLD CHAT FALLBACK
        --------------------------------------------------

        for _, player in
            ipairs(Players:GetPlayers()) do

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
        -- RESPAWN
        --------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(
            function()

                task.wait(1)

                updateCharacter()

                --------------------------------------------------
                -- RESTART TRIDENT
                --------------------------------------------------

                if vars.ActiveMode
                    == "trident"
                    and targetPlayer then

                    startTrident(
                        targetPlayer
                    )

                end

            end
        )

    end
}