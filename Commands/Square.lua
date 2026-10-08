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
            warn("[Square] LocalPlayer tidak ditemukan.")
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

        local Admin

        do

            local success, result =
                pcall(function()

                    return loadstring(game:HttpGet(
                        "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
                    ))()

                end)

            if success and result then

                Admin = result

            else

                warn("[Square] Gagal load Admin.lua.")
                return

            end

        end


        ----------------------------------------------------------------
        -- LOAD DISTANCE
        ----------------------------------------------------------------

        local Distance

        do

            local success, result =
                pcall(function()

                    return loadstring(game:HttpGet(
                        "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
                    ))()

                end)

            if success and result then

                Distance = result

            else

                warn("[Square] Gagal load Distance.lua.")
                return

            end

        end


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

        local botSpacing = 3

        local rowSpacing = 3

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

            "11775829997", -- Bot 11
            "11775843339", -- Bot 12

        }


        ----------------------------------------------------------------
        -- UPDATE CHARACTER
        ----------------------------------------------------------------

        local function updateCharacter()

            local character =
                LocalPlayer.Character
                or LocalPlayer.CharacterAdded:Wait()


            humanoid =
                character:WaitForChild(
                    "Humanoid"
                )


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

            local success = false


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


            ----------------------------------------------------------------
            -- PENTING:
            --
            -- JANGAN CLEAR:
            -- _G.BotVars.CommandTarget
            --
            -- CommandTarget hanya dihapus oleh !stop ADMIN.
            ----------------------------------------------------------------

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

                    pcall(function()

                        stopFunction()

                    end)

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


            name =
                name:lower()


            ------------------------------------------------------------
            -- EXACT USERNAME / DISPLAY NAME
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
            -- PREFIX USERNAME
            ------------------------------------------------------------

            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if player.Name:lower():sub(
                    1,
                    #name
                ) == name then

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
        -- A = Target
        --
        ----------------------------------------------------------------

        local function getSquareOffset(
            index,
            distance
        )

            ----------------------------------------------------------------
            -- BARIS ATAS
            ----------------------------------------------------------------

            if index >= 1
                and index <= 4 then

                local column =
                    index - 1


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

            if index >= 7
                and index <= 10 then

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
            -- BOT 11 / 12
            --
            -- Tambahan supaya tidak overlap di tengah.
            ----------------------------------------------------------------

            if index == 11 then

                return Vector3.new(
                    -botSpacing * 3.5,
                    0,
                    0
                )

            end


            if index == 12 then

                return Vector3.new(
                    botSpacing * 3.5,
                    0,
                    0
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

            _G.BotVars.ActiveMode =
                "square"


            ----------------------------------------------------------------
            -- SET COMMAND TARGET
            ----------------------------------------------------------------

            _G.BotVars.CommandTarget =
                player


            ----------------------------------------------------------------
            -- STOP CONNECTION LAMA
            ----------------------------------------------------------------

            if squareConnection then

                squareConnection:Disconnect()

                squareConnection = nil

            end


            squaring = true

            targetPlayer = player


            sendChat(
                "Yes, Sir!"
            )


            ----------------------------------------------------------------
            -- CARI INDEX BOT
            ----------------------------------------------------------------

            local myIndex =
                table.find(
                    botOrder,
                    tostring(
                        LocalPlayer.UserId
                    )
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
                        -- MODE SUDAH BERGANTI
                        ----------------------------------------------------------------

                        if _G.BotVars.ActiveMode
                            ~= "square" then

                            stopSquare()

                            return

                        end


                        ----------------------------------------------------------------
                        -- VALIDATION
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


                        if Admin:IsAdmin(
                            targetPlayer
                        ) then

                            distance =
                                adminSquareDistance

                        end


                        ----------------------------------------------------------------
                        -- SPECIAL DISTANCE
                        ----------------------------------------------------------------

                        local specialDistance =
                            Distance:GetDistance(
                                tostring(
                                    LocalPlayer.UserId
                                ),
                                tostring(
                                    targetPlayer.UserId
                                )
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
                        -- TO WORLD POSITION
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
                        -- DISTANCE TO POSITION
                        ----------------------------------------------------------------

                        local distanceToTarget =
                            (
                                myHRP.Position
                                -
                                targetPosition
                            ).Magnitude


                        ----------------------------------------------------------------
                        -- MOVE
                        ----------------------------------------------------------------

                        if distanceToTarget > 1.5 then

                            humanoid.AutoRotate = true


                            humanoid:MoveTo(
                                targetPosition
                            )


                            return

                        end


                        ----------------------------------------------------------------
                        -- ALREADY IN POSITION
                        -- FACE SAME DIRECTION AS TARGET
                        ----------------------------------------------------------------

                        humanoid.AutoRotate = false


                        myHRP.CFrame =
                            CFrame.lookAt(
                                myHRP.Position,
                                myHRP.Position
                                +
                                targetHRP.CFrame.LookVector
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
            -- ADMIN CHECK
            ----------------------------------------------------------------

            local isAdmin = false


            pcall(function()

                isAdmin =
                    Admin:IsAdmin(sender)

            end)


            ----------------------------------------------------------------
            -- COMMAND TARGET CHECK
            ----------------------------------------------------------------

            local isCommandTarget =
                (
                    _G.BotVars.CommandTarget
                    == sender
                )


            ----------------------------------------------------------------
            -- NORMALIZE MESSAGE
            ----------------------------------------------------------------

            local lower =
                message
                :lower()
                :gsub(
                    "^%s+",
                    ""
                )
                :gsub(
                    "%s+$",
                    ""
                )


            ----------------------------------------------------------------
            -- !STOP
            --
            -- HANYA ADMIN
            ----------------------------------------------------------------

            if lower == "!stop" then

                if not isAdmin then

                    print(
                        "[Square] !stop ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end


                print(
                    "[Square] !stop diterima | Admin:",
                    sender.Name
                )


                ----------------------------------------------------------------
                -- CLEAR GLOBAL STATE
                ----------------------------------------------------------------

                _G.BotVars.ActiveMode = nil

                _G.BotVars.CommandTarget = nil


                ----------------------------------------------------------------
                -- STOP SEMUA MODE
                ----------------------------------------------------------------

                for _, stopFunction in pairs(
                    _G.BotVars.ModeControllers
                ) do

                    if type(stopFunction)
                        == "function" then

                        pcall(function()

                            stopFunction()

                        end)

                    end

                end


                return

            end


            ----------------------------------------------------------------
            -- !UNSQUARE
            --
            -- HANYA ADMIN
            ----------------------------------------------------------------

            if lower == "!unsquare" then

                if not isAdmin then

                    print(
                        "[Square] !unsquare ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end


                print(
                    "[Square] !unsquare diterima | Admin:",
                    sender.Name
                )


                if _G.BotVars.ActiveMode
                    == "square" then

                    _G.BotVars.ActiveMode = nil

                    stopSquare()

                end


                return

            end


            ----------------------------------------------------------------
            -- !SQUARE
            --
            -- ADMIN:
            --     !square
            --
            -- COMMAND TARGET:
            --     !square
            --
            ----------------------------------------------------------------

            if lower == "!square" then

                if not isAdmin
                    and not isCommandTarget then

                    print(
                        "[Square] !square ditolak:",
                        sender.Name
                    )

                    return

                end


                print(
                    "[Square] !square diterima | Sender:",
                    sender.Name,
                    "| Admin:",
                    isAdmin,
                    "| CommandTarget:",
                    isCommandTarget
                )


                ----------------------------------------------------------------
                -- TARGET = SENDER
                ----------------------------------------------------------------

                _G.BotVars.CommandTarget =
                    sender


                startSquare(
                    sender
                )


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

                    print(
                        "[Square] !square PLAYER ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end


                local target =
                    findPlayerByName(
                        targetName
                    )


                if not target then

                    warn(
                        "[Square] Player tidak ditemukan:",
                        targetName
                    )

                    return

                end


                print(
                    "[Square] Target dipilih:",
                    target.Name,
                    "| Admin:",
                    sender.Name
                )


                _G.BotVars.CommandTarget =
                    target


                startSquare(
                    target
                )


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

        local connectedPlayers = {}


        local function connectPlayerChat(player)

            if connectedPlayers[player] then
                return
            end


            connectedPlayers[player] = true


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
        -- EXISTING PLAYERS
        ----------------------------------------------------------------

        for _, player in ipairs(
            Players:GetPlayers()
        ) do

            connectPlayerChat(
                player
            )

        end


        ----------------------------------------------------------------
        -- PLAYER ADDED
        ----------------------------------------------------------------

        Players.PlayerAdded:Connect(
            function(player)

                connectPlayerChat(
                    player
                )

            end
        )


        ----------------------------------------------------------------
        -- PLAYER REMOVING
        ----------------------------------------------------------------

        Players.PlayerRemoving:Connect(
            function(player)

                connectedPlayers[player] = nil

            end
        )


        ----------------------------------------------------------------
        -- CHARACTER RESPAWN
        ----------------------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(
            function()

                task.wait(1)


                updateCharacter()


                ----------------------------------------------------------------
                -- RESTART SQUARE
                ----------------------------------------------------------------

                if _G.BotVars.ActiveMode
                    == "square"
                    and targetPlayer then

                    local oldTarget =
                        targetPlayer


                    startSquare(
                        oldTarget
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