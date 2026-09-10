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

        local squareActive = false
        local squareConnection = nil
        local targetPlayer = nil

        --------------------------------------------------
        -- BOT ORDER
        --------------------------------------------------
        -- BOT 1 - BOT 11 IKUT FORMASI
        -- BOT 12+ TIDAK IKUT
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

        local baseDistance = 5

        local stopThreshold = 1.5

        --------------------------------------------------
        -- SQUARE SETTINGS
        --------------------------------------------------

        -- Jarak antar bot
        local squareSpacing = 4

        -- Jarak kotak dari player
        local squareDistance = 6

        -- Tinggi formasi
        local formationHeight = 0

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
                character:WaitForChild(
                    "HumanoidRootPart"
                )

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
        -- STOP SQUARE
        --------------------------------------------------

        local function stopSquare()

            squareActive = false
            targetPlayer = nil

            if squareConnection then

                squareConnection:Disconnect()
                squareConnection = nil

            end

            if humanoid then

                humanoid.AutoRotate = true

            end

            --------------------------------------------------
            -- JANGAN HAPUS MODE LAIN
            --------------------------------------------------

            if vars.ActiveMode == "square" then
                vars.ActiveMode = nil
            end

        end

        --------------------------------------------------
        -- REGISTER CONTROLLER
        --------------------------------------------------

        vars.ModeControllers.square =
            stopSquare

        --------------------------------------------------
        -- STOP OTHER MODES
        --------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in
                pairs(vars.ModeControllers) do

                if name ~= "square"
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
        -- GET SQUARE POSITION
        --------------------------------------------------
        --
        -- FORMASI:
        --
        -- B1 -------- B2 -------- B3 -------- B4
        -- |                                      |
        -- |                                      B5
        -- |                                      |
        -- B11                                   B6
        -- |                                      |
        -- B10                                   B7
        -- |                                      |
        -- B9 -------- B8 -------- B7 -------- B6
        --
        -- Dengan 11 bot:
        --
        -- B1  B2  B3  B4
        -- B11         B5
        -- B10         B6
        -- B9  B8  B7
        --
        --------------------------------------------------

        local function getSquarePosition(
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
            -- JARAK DARI PLAYER
            --------------------------------------------------

            local offset =
                squareDistance + distance

            --------------------------------------------------
            -- UKURAN KOTAK
            --------------------------------------------------

            local spacing =
                squareSpacing

            --------------------------------------------------
            -- POSISI BOT
            --------------------------------------------------

            local localOffset

            --------------------------------------------------
            -- BARIS ATAS
            --------------------------------------------------
            --
            -- B1 B2 B3 B4
            --
            --------------------------------------------------

            if myIndex == 1 then

                localOffset =
                    forward * offset
                    - right * (spacing * 1.5)

            elseif myIndex == 2 then

                localOffset =
                    forward * offset
                    - right * (spacing * 0.5)

            elseif myIndex == 3 then

                localOffset =
                    forward * offset
                    + right * (spacing * 0.5)

            elseif myIndex == 4 then

                localOffset =
                    forward * offset
                    + right * (spacing * 1.5)

            --------------------------------------------------
            -- SISI KANAN
            --------------------------------------------------
            --
            -- B5
            -- B6
            -- B7
            --
            --------------------------------------------------

            elseif myIndex == 5 then

                localOffset =
                    forward * (spacing * 0.5)
                    + right * (spacing * 1.5)

            elseif myIndex == 6 then

                localOffset =
                    right * (spacing * 1.5)

            elseif myIndex == 7 then

                localOffset =
                    -forward * offset
                    + right * (spacing * 1.5)

            --------------------------------------------------
            -- BAWAH
            --------------------------------------------------
            --
            -- B9 B8 B7
            --
            --------------------------------------------------

            elseif myIndex == 8 then

                localOffset =
                    -forward * offset
                    + right * (spacing * 0.5)

            elseif myIndex == 9 then

                localOffset =
                    -forward * offset
                    - right * (spacing * 0.5)

            --------------------------------------------------
            -- SISI KIRI
            --------------------------------------------------
            --
            -- B10
            -- B11
            --
            --------------------------------------------------

            elseif myIndex == 10 then

                localOffset =
                    -forward * (spacing * 0.5)
                    - right * (spacing * 1.5)

            elseif myIndex == 11 then

                localOffset =
                    forward * (spacing * 0.5)
                    - right * (spacing * 1.5)

            end

            if not localOffset then
                return nil
            end

            --------------------------------------------------
            -- FINAL POSITION
            --------------------------------------------------

            return origin
                + localOffset
                + Vector3.new(
                    0,
                    formationHeight,
                    0
                )

        end

        --------------------------------------------------
        -- CONNECT SQUARE LOOP
        --------------------------------------------------
        --
        -- Dipisahkan dari startSquare()
        -- supaya respawn tidak memanggil startSquare().
        --
        -- Dengan begitu stopOtherModes() tidak dipanggil
        -- ulang dan Sync tetap berjalan.
        --
        --------------------------------------------------

        local function connectSquareLoop(myIndex)

            --------------------------------------------------
            -- DISCONNECT LOOP LAMA
            --------------------------------------------------

            if squareConnection then

                squareConnection:Disconnect()
                squareConnection = nil

            end

            if not myIndex then
                return
            end

            --------------------------------------------------
            -- HEARTBEAT
            --------------------------------------------------

            squareConnection =
                RunService.Heartbeat:Connect(
                    function()

                        --------------------------------------------------
                        -- ACTIVE CHECK
                        --------------------------------------------------
                        --
                        -- JANGAN menggunakan vars.ActiveMode
                        -- di sini.
                        --
                        -- Sync dapat mengubah:
                        --
                        -- vars.ActiveMode = "sync"
                        --
                        -- tetapi Square tetap harus berjalan.
                        --
                        --------------------------------------------------

                        if not squareActive then
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
                        -- SQUARE POSITION
                        --------------------------------------------------

                        local targetPosition =
                            getSquarePosition(
                                myIndex,
                                targetHRP,
                                distance
                            )

                        if not targetPosition then
                            return
                        end

                        --------------------------------------------------
                        -- DISTANCE TO FORMATION
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
                        -- FACE CENTER / PLAYER
                        --------------------------------------------------

                        local lookPosition =
                            targetHRP.Position

                        myHRP.CFrame =
                            CFrame.lookAt(
                                myHRP.Position,
                                Vector3.new(
                                    lookPosition.X,
                                    myHRP.Position.Y,
                                    lookPosition.Z
                                )
                            )

                    end
                )

        end

        --------------------------------------------------
        -- START SQUARE
        --------------------------------------------------

        local function startSquare(player)

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

            vars.ActiveMode =
                "square"

            --------------------------------------------------
            -- DISCONNECT OLD LOOP
            --------------------------------------------------

            if squareConnection then

                squareConnection:Disconnect()
                squareConnection = nil

            end

            --------------------------------------------------
            -- STATE
            --------------------------------------------------

            squareActive = true
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
                    "[SQUARE]",
                    "Bot tidak termasuk formasi:",
                    LocalPlayer.Name,
                    LocalPlayer.UserId
                )

                stopSquare()

                return

            end

            --------------------------------------------------
            -- DEBUG
            --------------------------------------------------

            print(
                "[SQUARE]",
                "Bot Index:",
                myIndex,
                "UserId:",
                LocalPlayer.UserId
            )

            --------------------------------------------------
            -- START LOOP
            --------------------------------------------------

            connectSquareLoop(
                myIndex
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
            -- !SQUARE
            --------------------------------------------------

            if lower == "!square" then

                startSquare(
                    sender
                )

                return

            end

            --------------------------------------------------
            -- !SQUARE PLAYER
            --------------------------------------------------

            local targetName =
                lower:match(
                    "^!square%s+(.+)$"
                )

            if targetName then

                local target =
                    findPlayerByName(
                        targetName
                    )

                if target then

                    startSquare(
                        target
                    )

                end

                return

            end

            --------------------------------------------------
            -- !STOP
            --------------------------------------------------

            if lower == "!stop"
                or lower == "!unsquare" then

                stopSquare()

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
                -- RECONNECT SQUARE
                --------------------------------------------------
                --
                -- Jangan panggil startSquare().
                --
                -- startSquare() akan menjalankan
                -- stopOtherModes() dan dapat mematikan Sync.
                --
                --------------------------------------------------

                if squareActive
                    and targetPlayer then

                    local myIndex =
                        table.find(
                            botOrder,
                            tostring(LocalPlayer.UserId)
                        )

                    if myIndex then

                        connectSquareLoop(
                            myIndex
                        )

                    end

                end

            end
        )

        --------------------------------------------------
        -- READY
        --------------------------------------------------

        print(
            "[SQUARE] Square.lua aktif!"
        )

    end
}