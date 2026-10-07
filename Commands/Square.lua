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

        local squaring = false
        local targetPlayer = nil
        local squareConnection = nil

        ----------------------------------------------------------------
        -- FORMATION SETTINGS
        ----------------------------------------------------------------

        -- Jarak horizontal antar bot.
        local botSpacing = 3

        -- Jarak dari Admin/player ke baris bot.
        local rowSpacing = 3

        -- Jarak tambahan jika target adalah Admin.
        -- Dipakai sebagai jarak dasar dari pusat.
        local adminSquareDistance = 6
        local defaultBotSquareDistance = 6

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
        -- STOP SQUARE
        ----------------------------------------------------------------

        local function stopSquare()

            squaring = false
            targetPlayer = nil

            if squareConnection then

                squareConnection:Disconnect()
                squareConnection = nil

            end

            if humanoid then

                humanoid.AutoRotate = true

            end

        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.square =
            stopSquare

        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "square"
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
        -- GET FORMATION OFFSET
        ----------------------------------------------------------------
        --
        -- FORMASI:
        --
        -- B1   B2   B3   B4
        --
        -- B5        A        B6
        --
        -- B7   B8   B9   B10
        --
        -- A = Admin / Player
        --
        ----------------------------------------------------------------

        local function getSquareOffset(index, distance)

            ----------------------------------------------------------------
            -- BARIS ATAS
            ----------------------------------------------------------------
            --
            -- B1 B2 B3 B4
            --
            -- Posisi X:
            -- -4.5, -1.5, +1.5, +4.5
            --
            -- Jika botSpacing = 3
            ----------------------------------------------------------------

            if index >= 1 and index <= 4 then

                local column = index - 1

                local x =
                    (column - 1.5)
                    * botSpacing

                local z =
                    distance

                return Vector3.new(
                    x,
                    0,
                    z
                )

            end

            ----------------------------------------------------------------
            -- BARIS TENGAH
            ----------------------------------------------------------------
            --
            -- B5       A       B6
            ----------------------------------------------------------------

            if index == 5 then

                return Vector3.new(
                    -botSpacing * 2,
                    0,
                    0
                )

            end

            if index == 6 then

                return Vector3.new(
                    botSpacing * 2,
                    0,
                    0
                )

            end

            ----------------------------------------------------------------
            -- BARIS BAWAH
            ----------------------------------------------------------------
            --
            -- B7 B8 B9 B10
            ----------------------------------------------------------------

            if index >= 7 and index <= 10 then

                local column =
                    index - 7

                local x =
                    (column - 1.5)
                    * botSpacing

                local z =
                    -distance

                return Vector3.new(
                    x,
                    0,
                    z
                )

            end

            ----------------------------------------------------------------
            -- FALLBACK
            ----------------------------------------------------------------

            return Vector3.zero

        end

        ----------------------------------------------------------------
        -- START SQUARE
        ----------------------------------------------------------------

        local function startSquare(player)

            if not player then
                return
            end

            ----------------------------------------------------------------
            -- STOP MODE LAIN
            ----------------------------------------------------------------

            stopOtherModes()

            ----------------------------------------------------------------
            -- SET ACTIVE MODE
            ----------------------------------------------------------------

            _G.BotVars.ActiveMode = "square"

            ----------------------------------------------------------------
            -- STOP CONNECTION LAMA
            ----------------------------------------------------------------

            if squareConnection then

                squareConnection:Disconnect()
                squareConnection = nil

            end

            squaring = true
            targetPlayer = player

            _G.BotVars.CommandTarget = player

            sendChat("Yes, Sir!")

            ----------------------------------------------------------------
            -- CARI INDEX BOT
            ----------------------------------------------------------------

            local myIndex =
                table.find(
                    botOrder,
                    tostring(LocalPlayer.UserId)
                )

            if not myIndex then

                stopSquare()

                return

            end

            ----------------------------------------------------------------
            -- SQUARE LOOP
            ----------------------------------------------------------------

            squareConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ----------------------------------------------------------------
                        -- JIKA MODE SUDAH BERGANTI
                        ----------------------------------------------------------------

                        if _G.BotVars.ActiveMode ~= "square" then

                            stopSquare()

                            return

                        end

                        ----------------------------------------------------------------
                        -- VALIDASI
                        ----------------------------------------------------------------

                        if not squaring then
                            return
                        end

                        if not humanoid
                            or not myHRP then

                            return

                        end

                        if not targetPlayer then
                            return
                        end

                        ----------------------------------------------------------------
                        -- TARGET CHARACTER
                        ----------------------------------------------------------------

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

                        ----------------------------------------------------------------
                        -- DISTANCE
                        ----------------------------------------------------------------

                        local distance =
                            defaultBotSquareDistance

                        if Admin:IsAdmin(targetPlayer) then

                            distance =
                                adminSquareDistance

                        end

                        ----------------------------------------------------------------
                        -- SPECIAL DISTANCE
                        ----------------------------------------------------------------

                        local specialDistance =
                            Distance:GetDistance(
                                tostring(LocalPlayer.UserId),
                                tostring(targetPlayer.UserId)
                            )

                        if specialDistance then

                            distance =
                                specialDistance

                        end

                        ----------------------------------------------------------------
                        -- FORMATION OFFSET
                        ----------------------------------------------------------------

                        local squareOffset =
                            getSquareOffset(
                                myIndex,
                                distance
                            )

                        ----------------------------------------------------------------
                        -- CONVERT LOCAL OFFSET
                        -- KE POSISI WORLD
                        ----------------------------------------------------------------

                        local right =
                            targetHRP.CFrame.RightVector

                        local forward =
                            targetHRP.CFrame.LookVector

                        local targetPosition =
                            targetHRP.Position
                            +
                            (right * squareOffset.X)
                            +
                            (forward * squareOffset.Z)

                        ----------------------------------------------------------------
                        -- JARAK KE POSISI
                        ----------------------------------------------------------------

                        local distanceToTarget =
                            (
                                myHRP.Position
                                -
                                targetPosition
                            ).Magnitude

                        ----------------------------------------------------------------
                        -- JALAN KE POSISI
                        ----------------------------------------------------------------

                        if distanceToTarget > 1.5 then

                            humanoid.AutoRotate = true

                            humanoid:MoveTo(
                                targetPosition
                            )

                            return

                        end

                        ----------------------------------------------------------------
                        -- SUDAH SAMPAI
                        -- SEMUA BOT MENGHADAP KE A
                        ----------------------------------------------------------------

                        humanoid.AutoRotate = false

                        local lookPosition =
                            Vector3.new(
                                targetHRP.Position.X,
                                myHRP.Position.Y,
                                targetHRP.Position.Z
                            )

                        myHRP.CFrame =
                            CFrame.lookAt(
                                myHRP.Position,
                                lookPosition
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

            if not message
                or not sender then

                return

            end

            ----------------------------------------------------------------
            -- CHECK ADMIN
            ----------------------------------------------------------------

            local isAdmin = false

            pcall(function()

                isAdmin =
                    Admin:IsAdmin(sender)

            end)

            ----------------------------------------------------------------
            -- NORMALIZE MESSAGE
            ----------------------------------------------------------------

            local lower =
                message
                :lower()
                :gsub("^%s+", "")
                :gsub("%s+$", "")

            ----------------------------------------------------------------
            -- CURRENT TARGET
            ----------------------------------------------------------------

            local commandTarget =
                _G.BotVars.CommandTarget

            ----------------------------------------------------------------
            -- !STOP
            -- !UNSQUARE
            ----------------------------------------------------------------

            if lower == "!stop"
                or lower == "!unsquare" then

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

            ----------------------------------------------------------------
            -- !SQUARE
            ----------------------------------------------------------------
            --
            -- Admin:
            -- dapat menjalankan ke dirinya sendiri.
            --
            -- Target aktif:
            -- dapat mengganti formasi menjadi square.
            ----------------------------------------------------------------

            if lower == "!square" then

                if not isAdmin
                    and sender ~= commandTarget then

                    return

                end

                _G.BotVars.CommandTarget =
                    sender

                startSquare(sender)

                return

            end

            ----------------------------------------------------------------
            -- !SQUARE PLAYER
            --
            -- HANYA ADMIN
            ----------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!square%s+(.+)$"
                )

            if targetName then

                if not isAdmin then
                    return
                end

                local target =
                    findPlayerByName(
                        targetName
                    )

                if target then

                    _G.BotVars.CommandTarget =
                        target

                    startSquare(target)

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

                channel.MessageReceived:Connect(
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
                )

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

                if _G.BotVars.ActiveMode == "square"
                    and targetPlayer then

                    startSquare(
                        targetPlayer
                    )

                end

            end
        )

        ----------------------------------------------------------------
        -- DONE
        ----------------------------------------------------------------

        print(
            "[Square] Square formation system loaded."
        )

    end
}