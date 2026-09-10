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

        local circleActive = false
        local circleConnection = nil
        local targetPlayer = nil

        ----------------------------------------------------------------
        -- BOT ORDER
        ----------------------------------------------------------------
        -- BOT 1 - BOT 11 IKUT FORMASI
        -- BOT 12+ TIDAK IKUT
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
        -- FORMATION SETTINGS
        ----------------------------------------------------------------

        local baseDistance = 5

        local stopThreshold = 1.5

        ----------------------------------------------------------------
        -- CIRCLE SETTINGS
        ----------------------------------------------------------------

        -- Jarak bot dari player
        local circleRadius = 8

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

                    pcall(function()

                        channel:SendAsync(
                            message
                        )

                    end)

                    success = true

                end

            end

            ----------------------------------------------------------------
            -- OLD CHAT FALLBACK
            ----------------------------------------------------------------

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
        -- STOP CIRCLE
        ----------------------------------------------------------------
        --
        -- Circle hanya dihentikan apabila fungsi ini dipanggil.
        --
        -- Circle TIDAK lagi bergantung kepada vars.ActiveMode.
        --
        ----------------------------------------------------------------

        local function stopCircle()

            circleActive = false
            targetPlayer = nil

            if circleConnection then

                circleConnection:Disconnect()
                circleConnection = nil

            end

            if humanoid then

                humanoid.AutoRotate = true

            end

            print(
                "[CIRCLE] Circle stopped."
            )

        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        vars.ModeControllers.circle =
            stopCircle

        ----------------------------------------------------------------
        -- BACKWARD COMPATIBILITY
        ----------------------------------------------------------------
        --
        -- Kode lama menggunakan "cricle".
        -- Kita tetap daftarkan supaya controller lama yang
        -- memanggil vars.ModeControllers.cricle() tetap bekerja.
        --
        ----------------------------------------------------------------

        vars.ModeControllers.cricle =
            stopCircle

        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in
                pairs(vars.ModeControllers) do

                if name ~= "circle"
                    and name ~= "cricle"
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

            ----------------------------------------------------------------
            -- EXACT MATCH
            ----------------------------------------------------------------

            for _, player in
                ipairs(Players:GetPlayers()) do

                if player.Name:lower() == name
                    or player.DisplayName:lower() == name then

                    return player

                end

            end

            ----------------------------------------------------------------
            -- PARTIAL MATCH
            ----------------------------------------------------------------

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

        ----------------------------------------------------------------
        -- GET DISTANCE
        ----------------------------------------------------------------

        local function getBotDistance(player)

            local distance = baseDistance

            ----------------------------------------------------------------
            -- ADMIN DISTANCE
            ----------------------------------------------------------------

            if Admin:IsAdmin(player) then

                distance = baseDistance

            end

            ----------------------------------------------------------------
            -- SPECIAL DISTANCE
            ----------------------------------------------------------------

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
        -- GET CIRCLE POSITION
        ----------------------------------------------------------------
        --
        --              B1
        --         B11       B2
        --
        --     B10             B3
        --
        --   B9        PLAYER      B4
        --
        --     B8             B5
        --         B7       B6
        --
        ----------------------------------------------------------------

        local function getCirclePosition(
            myIndex,
            targetHRP,
            distance
        )

            if not myIndex
                or not targetHRP
                or not distance then

                return nil

            end

            ----------------------------------------------------------------
            -- LOCAL AXIS
            ----------------------------------------------------------------

            local forward =
                targetHRP.CFrame.LookVector

            local right =
                targetHRP.CFrame.RightVector

            local origin =
                targetHRP.Position

            ----------------------------------------------------------------
            -- CIRCLE RADIUS
            ----------------------------------------------------------------

            local radius =
                circleRadius

            ----------------------------------------------------------------
            -- TOTAL BOT
            ----------------------------------------------------------------

            local totalBots =
                #botOrder

            ----------------------------------------------------------------
            -- ANGLE
            ----------------------------------------------------------------

            local angle =
                ((myIndex - 1) / totalBots)
                * math.pi
                * 2

            ----------------------------------------------------------------
            -- CIRCLE OFFSET
            ----------------------------------------------------------------

            local forwardOffset =
                math.cos(angle)
                * radius

            local rightOffset =
                math.sin(angle)
                * radius

            ----------------------------------------------------------------
            -- POSITION
            ----------------------------------------------------------------

            return origin
                + forward * forwardOffset
                + right * rightOffset

        end

        ----------------------------------------------------------------
        -- CREATE CIRCLE LOOP
        ----------------------------------------------------------------
        --
        -- Dipisahkan dari startCircle supaya ketika respawn kita
        -- bisa menghidupkan kembali Heartbeat tanpa memanggil
        -- stopOtherModes().
        --
        ----------------------------------------------------------------

        local function connectCircleLoop(myIndex)

            ----------------------------------------------------------------
            -- DISCONNECT OLD LOOP
            ----------------------------------------------------------------

            if circleConnection then

                circleConnection:Disconnect()
                circleConnection = nil

            end

            ----------------------------------------------------------------
            -- CREATE HEARTBEAT
            ----------------------------------------------------------------

            circleConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- IMPORTANT:
                        --
                        -- JANGAN CEK:
                        --
                        -- if vars.ActiveMode ~= "circle" then
                        --     stopCircle()
                        --     return
                        -- end
                        --
                        -- Karena Sync boleh berjalan bersamaan
                        -- dengan Circle.
                        ------------------------------------------------

                        if not circleActive then
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

                        local distance =
                            getBotDistance(
                                targetPlayer
                            )

                        ------------------------------------------------
                        -- CIRCLE POSITION
                        ------------------------------------------------

                        local targetPosition =
                            getCirclePosition(
                                myIndex,
                                targetHRP,
                                distance
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
                                - targetPosition
                            ).Magnitude

                        ------------------------------------------------
                        -- MOVE
                        ------------------------------------------------

                        if distanceToTarget
                            > stopThreshold then

                            humanoid.AutoRotate = true

                            humanoid:MoveTo(
                                targetPosition
                            )

                            return

                        end

                        ------------------------------------------------
                        -- REACHED FORMATION
                        ------------------------------------------------

                        humanoid.AutoRotate = false

                        ------------------------------------------------
                        -- FACE CENTER / PLAYER
                        ------------------------------------------------

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

        ----------------------------------------------------------------
        -- START CIRCLE
        ----------------------------------------------------------------

        local function startCircle(player)

            if not player then
                return
            end

            ----------------------------------------------------------------
            -- STOP MODE LAIN
            ----------------------------------------------------------------

            stopOtherModes()

            ----------------------------------------------------------------
            -- ACTIVE MODE
            ----------------------------------------------------------------
            --
            -- Ini hanya menandakan Circle sebagai mode utama.
            -- Heartbeat tidak lagi bergantung pada nilai ini.
            --
            ----------------------------------------------------------------

            vars.ActiveMode =
                "circle"

            ----------------------------------------------------------------
            -- STATE
            ----------------------------------------------------------------

            circleActive = true
            targetPlayer = player

            ----------------------------------------------------------------
            -- CHAT
            ----------------------------------------------------------------

            sendChat("Yes, Sir!")

            ----------------------------------------------------------------
            -- FIND BOT INDEX
            ----------------------------------------------------------------

            local myIndex =
                table.find(
                    botOrder,
                    tostring(LocalPlayer.UserId)
                )

            ----------------------------------------------------------------
            -- BOT TIDAK TERDAFTAR
            ----------------------------------------------------------------

            if not myIndex then

                print(
                    "[CIRCLE]",
                    "Bot tidak termasuk formasi:",
                    LocalPlayer.Name,
                    LocalPlayer.UserId
                )

                stopCircle()

                return

            end

            ----------------------------------------------------------------
            -- DEBUG
            ----------------------------------------------------------------

            print(
                "[CIRCLE]",
                "Bot Index:",
                myIndex,
                "UserId:",
                LocalPlayer.UserId
            )

            ----------------------------------------------------------------
            -- CONNECT LOOP
            ----------------------------------------------------------------

            connectCircleLoop(
                myIndex
            )

        end

        ----------------------------------------------------------------
        -- HANDLE COMMAND
        ----------------------------------------------------------------

        local function handleCommand(
            message,
            sender
        )

            ----------------------------------------------------------------
            -- ADMIN ONLY
            ----------------------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end

            if not message then
                return
            end

            local lower =
                message:lower()

            ----------------------------------------------------------------
            -- !CIRCLE
            ----------------------------------------------------------------

            if lower == "!circle" then

                startCircle(
                    sender
                )

                return

            end

            ----------------------------------------------------------------
            -- !CIRCLE PLAYER
            ----------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!circle%s+(.+)$"
                )

            if targetName then

                local target =
                    findPlayerByName(
                        targetName
                    )

                if target then

                    startCircle(
                        target
                    )

                else

                    warn(
                        "[CIRCLE] Player tidak ditemukan:",
                        targetName
                    )

                end

                return

            end

            ----------------------------------------------------------------
            -- SUPPORT OLD TYPO COMMAND
            ----------------------------------------------------------------

            if lower == "!cricle" then

                startCircle(
                    sender
                )

                return

            end

            local oldTargetName =
                lower:match(
                    "^!cricle%s+(.+)$"
                )

            if oldTargetName then

                local target =
                    findPlayerByName(
                        oldTargetName
                    )

                if target then

                    startCircle(
                        target
                    )

                else

                    warn(
                        "[CIRCLE] Player tidak ditemukan:",
                        oldTargetName
                    )

                end

                return

            end

            ----------------------------------------------------------------
            -- !STOP
            ----------------------------------------------------------------

            if lower == "!stop" then

                ------------------------------------------------------------
                -- Hanya reset ActiveMode jika Circle adalah mode utama.
                ------------------------------------------------------------

                if vars.ActiveMode ==
                    "circle"
                    or vars.ActiveMode ==
                    "cricle" then

                    vars.ActiveMode = nil

                end

                stopCircle()

                return

            end

            ----------------------------------------------------------------
            -- !UNCIRCLE
            ----------------------------------------------------------------

            if lower == "!uncircle"
                or lower == "!uncricle" then

                ------------------------------------------------------------
                -- Jangan menghapus ActiveMode milik Sync / mode lain.
                ------------------------------------------------------------

                if vars.ActiveMode ==
                    "circle"
                    or vars.ActiveMode ==
                    "cricle" then

                    vars.ActiveMode = nil

                end

                stopCircle()

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

                        if not message then
                            return
                        end

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
        -- OLD CHAT FALLBACK
        ----------------------------------------------------------------

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
        -- RESPAWN
        ----------------------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(
            function()

                task.wait(1)

                updateCharacter()

                ----------------------------------------------------------------
                -- RESTART CIRCLE
                ----------------------------------------------------------------
                --
                -- Jangan menggunakan:
                --
                -- vars.ActiveMode == "circle"
                --
                -- karena ActiveMode bisa saja sudah berubah menjadi
                -- "sync", sementara Circle masih aktif.
                --
                ----------------------------------------------------------------

                if circleActive
                    and targetPlayer then

                    local myIndex =
                        table.find(
                            botOrder,
                            tostring(LocalPlayer.UserId)
                        )

                    if not myIndex then
                        return
                    end

                    ------------------------------------------------------------
                    -- RECONNECT LOOP
                    ------------------------------------------------------------
                    --
                    -- Tidak memanggil startCircle() karena startCircle()
                    -- memanggil stopOtherModes(), yang bisa menghentikan Sync.
                    --
                    ------------------------------------------------------------

                    connectCircleLoop(
                        myIndex
                    )

                end

            end
        )

        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[CIRCLE] Circle.lua aktif!"
        )

    end
}