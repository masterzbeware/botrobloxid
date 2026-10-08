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
            warn("[TwoLine] LocalPlayer tidak ditemukan.")
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

                warn("[TwoLine] Gagal load Admin.lua.")
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

                warn("[TwoLine] Gagal load Distance.lua.")
                return

            end

        end


        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local humanoid
        local myHRP

        local twoLining = false
        local targetPlayer = nil
        local twoLineConnection = nil


        ----------------------------------------------------------------
        -- FORMATION SETTINGS
        ----------------------------------------------------------------

        local sideDistance = 3

        local rowDistance = 3

        local adminTwoLineDistance = 3
        local defaultBotTwoLineDistance = 2


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
        -- STOP TWO LINE
        ----------------------------------------------------------------

        local function stopTwoLine()

            twoLining = false

            targetPlayer = nil


            if twoLineConnection then

                twoLineConnection:Disconnect()

                twoLineConnection = nil

            end


            if humanoid then

                humanoid.AutoRotate = true

            end


            ----------------------------------------------------------------
            -- PENTING:
            --
            -- JANGAN CLEAR CommandTarget.
            --
            -- CommandTarget hanya dihapus oleh !stop ADMIN.
            ----------------------------------------------------------------

        end


        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.twoline =
            stopTwoLine


        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "twoline"
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
        -- GET TWO LINE OFFSET
        ----------------------------------------------------------------
        --
        -- FORMASI:
        --
        --                 A
        --
        --        B1              B2
        --        B3              B4
        --        B5              B6
        --        B7              B8
        --        B9              B10
        --
        ----------------------------------------------------------------

        local function getTwoLineOffset(
            index,
            distance
        )

            ----------------------------------------------------------------
            -- SISI KIRI
            ----------------------------------------------------------------

            if index % 2 == 1 then

                local row =
                    math.floor(
                        (index - 1) / 2
                    )


                local x =
                    -sideDistance


                local z =
                    -(
                        distance
                        +
                        (row * rowDistance)
                    )


                return Vector3.new(
                    x,
                    0,
                    z
                )

            end


            ----------------------------------------------------------------
            -- SISI KANAN
            ----------------------------------------------------------------

            local row =
                math.floor(
                    (index - 2) / 2
                )


            local x =
                sideDistance


            local z =
                -(
                    distance
                    +
                    (row * rowDistance)
                )


            return Vector3.new(
                x,
                0,
                z
            )

        end


        ----------------------------------------------------------------
        -- START TWO LINE
        ----------------------------------------------------------------

        local function startTwoLine(player)

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
                "twoline"


            ----------------------------------------------------------------
            -- SET COMMAND TARGET
            ----------------------------------------------------------------

            _G.BotVars.CommandTarget =
                player


            ----------------------------------------------------------------
            -- STOP CONNECTION LAMA
            ----------------------------------------------------------------

            if twoLineConnection then

                twoLineConnection:Disconnect()

                twoLineConnection = nil

            end


            twoLining = true

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

                stopTwoLine()

                return

            end


            ----------------------------------------------------------------
            -- TWO LINE LOOP
            ----------------------------------------------------------------

            twoLineConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- MODE SUDAH BERGANTI
                        ------------------------------------------------

                        if _G.BotVars.ActiveMode
                            ~= "twoline" then

                            stopTwoLine()

                            return

                        end


                        ------------------------------------------------
                        -- VALIDASI
                        ------------------------------------------------

                        if not twoLining then
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
                            defaultBotTwoLineDistance


                        if Admin:IsAdmin(
                            targetPlayer
                        ) then

                            distance =
                                adminTwoLineDistance

                        end


                        ------------------------------------------------
                        -- SPECIAL DISTANCE
                        ------------------------------------------------

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


                        ------------------------------------------------
                        -- FORMATION OFFSET
                        ------------------------------------------------

                        local offset =
                            getTwoLineOffset(
                                myIndex,
                                distance
                            )


                        ------------------------------------------------
                        -- CONVERT LOCAL OFFSET
                        -- TO WORLD POSITION
                        ------------------------------------------------

                        local right =
                            targetHRP.CFrame.RightVector


                        local forward =
                            targetHRP.CFrame.LookVector


                        local targetPosition =
                            targetHRP.Position
                            +
                            (right * offset.X)
                            +
                            (forward * offset.Z)


                        ------------------------------------------------
                        -- DISTANCE
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

                        if distanceToTarget > 1.5 then

                            humanoid.AutoRotate = true


                            humanoid:MoveTo(
                                targetPosition
                            )


                            return

                        end


                        ------------------------------------------------
                        -- SUDAH SAMPAI
                        -- MENGHADAP SESUAI ARAH TARGET
                        ------------------------------------------------

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
            -- CHECK ADMIN
            ----------------------------------------------------------------

            local isAdmin = false


            pcall(function()

                isAdmin =
                    Admin:IsAdmin(sender)

            end)


            ----------------------------------------------------------------
            -- CHECK COMMAND TARGET
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
                        "[TwoLine] !stop ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end


                print(
                    "[TwoLine] !stop diterima | Admin:",
                    sender.Name
                )


                ------------------------------------------------------------
                -- CLEAR GLOBAL STATE
                ------------------------------------------------------------

                _G.BotVars.ActiveMode = nil

                _G.BotVars.CommandTarget = nil


                ------------------------------------------------------------
                -- STOP SEMUA MODE
                ------------------------------------------------------------

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
            -- !UNTWOLINE
            --
            -- HANYA ADMIN
            ----------------------------------------------------------------

            if lower == "!untwoline" then

                if not isAdmin then

                    print(
                        "[TwoLine] !untwoline ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end


                print(
                    "[TwoLine] !untwoline diterima | Admin:",
                    sender.Name
                )


                if _G.BotVars.ActiveMode
                    == "twoline" then

                    _G.BotVars.ActiveMode = nil

                    stopTwoLine()

                end


                return

            end


            ----------------------------------------------------------------
            -- !TWOLINE
            --
            -- ADMIN:
            --     !twoline
            --
            -- COMMAND TARGET:
            --     !twoline
            ----------------------------------------------------------------

            if lower == "!twoline" then

                if not isAdmin
                    and not isCommandTarget then

                    print(
                        "[TwoLine] !twoline ditolak:",
                        sender.Name
                    )

                    return

                end


                print(
                    "[TwoLine] !twoline diterima | Sender:",
                    sender.Name,
                    "| Admin:",
                    isAdmin,
                    "| CommandTarget:",
                    isCommandTarget
                )


                ------------------------------------------------------------
                -- TARGET = SENDER
                ------------------------------------------------------------

                _G.BotVars.CommandTarget =
                    sender


                startTwoLine(
                    sender
                )


                return

            end


            ----------------------------------------------------------------
            -- !TWOLINE PLAYER
            --
            -- HANYA ADMIN
            ----------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!twoline%s+(.+)$"
                )


            if targetName then

                if not isAdmin then

                    print(
                        "[TwoLine] !twoline PLAYER ditolak:",
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
                        "[TwoLine] Player tidak ditemukan:",
                        targetName
                    )

                    return

                end


                print(
                    "[TwoLine] Target dipilih:",
                    target.Name,
                    "| Admin:",
                    sender.Name
                )


                ------------------------------------------------------------
                -- SET COMMAND TARGET
                ------------------------------------------------------------

                _G.BotVars.CommandTarget =
                    target


                startTwoLine(
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


                --------------------------------------------------------
                -- RESTART TWO LINE
                --------------------------------------------------------

                if _G.BotVars.ActiveMode
                    == "twoline"
                    and targetPlayer then

                    local oldTarget =
                        targetPlayer


                    startTwoLine(
                        oldTarget
                    )

                end

            end
        )


        ----------------------------------------------------------------
        -- DONE
        ----------------------------------------------------------------

        print(
            "[TwoLine] Two-line formation system loaded."
        )

    end
}