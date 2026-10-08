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
        -- GLOBAL
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

            if not success or not result then

                warn("[TwoLine] Gagal load Admin.lua.")

                return

            end

            Admin = result

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

            if not success or not result then

                warn("[TwoLine] Gagal load Distance.lua.")

                return

            end

            Distance = result

        end


        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local humanoid = nil
        local myHRP = nil

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

            pcall(function()

                local channels =
                    TextChatService:FindFirstChild(
                        "TextChannels"
                    )

                if channels then

                    local channel =
                        channels:FindFirstChild(
                            "RBXGeneral"
                        )

                    if channel then

                        channel:SendAsync(message)

                        return

                    end

                end


                --------------------------------------------------------
                -- FALLBACK LEGACY CHAT
                --------------------------------------------------------

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

            name = name:lower()


            ------------------------------------------------------------
            -- EXACT USERNAME
            ------------------------------------------------------------

            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if player.Name:lower() == name then

                    return player

                end

            end


            ------------------------------------------------------------
            -- EXACT DISPLAY NAME
            ------------------------------------------------------------

            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if player.DisplayName:lower() == name then

                    return player

                end

            end


            ------------------------------------------------------------
            -- USERNAME PREFIX
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


            ------------------------------------------------------------
            -- DISPLAY NAME PREFIX
            ------------------------------------------------------------

            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if player.DisplayName:lower():sub(
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
        --             A
        --
        --       B1          B2
        --       B3          B4
        --       B5          B6
        --       B7          B8
        --       B9          B10
        --       B11         B12
        --
        ----------------------------------------------------------------

        local function getTwoLineOffset(
            index,
            distance
        )

            local row =
                math.floor(
                    (index - 1) / 2
                )

            local x

            if index % 2 == 1 then

                x = -sideDistance

            else

                x = sideDistance

            end

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


            ------------------------------------------------------------
            -- STOP MODE LAIN
            ------------------------------------------------------------

            stopOtherModes()


            ------------------------------------------------------------
            -- SET GLOBAL MODE
            ------------------------------------------------------------

            _G.BotVars.ActiveMode =
                "twoline"


            ------------------------------------------------------------
            -- SET COMMAND TARGET
            ------------------------------------------------------------

            _G.BotVars.CommandTarget =
                player


            ------------------------------------------------------------
            -- STOP CONNECTION LAMA
            ------------------------------------------------------------

            if twoLineConnection then

                twoLineConnection:Disconnect()

                twoLineConnection = nil

            end


            twoLining = true
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
                    tostring(
                        LocalPlayer.UserId
                    )
                )


            if not myIndex then

                warn(
                    "[TwoLine] Bot tidak ada di botOrder:",
                    LocalPlayer.Name,
                    LocalPlayer.UserId
                )

                stopTwoLine()

                return

            end


            print(
                "[TwoLine] START:",
                LocalPlayer.Name,
                "| Target:",
                player.Name,
                "| BotIndex:",
                myIndex
            )


            ------------------------------------------------------------
            -- HEARTBEAT
            ------------------------------------------------------------

            twoLineConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- MODE BERUBAH
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
                        -- OFFSET
                        ------------------------------------------------

                        local offset =
                            getTwoLineOffset(
                                myIndex,
                                distance
                            )


                        ------------------------------------------------
                        -- WORLD POSITION
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
                        -- DISTANCE CHECK
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
                        -- FACE TARGET DIRECTION
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


            ------------------------------------------------------------
            -- NORMALIZE
            ------------------------------------------------------------

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


            if lower == "" then
                return
            end


            ------------------------------------------------------------
            -- ADMIN CHECK
            ------------------------------------------------------------

            local isAdmin = false

            pcall(function()

                isAdmin =
                    Admin:IsAdmin(sender)

            end)


            ------------------------------------------------------------
            -- COMMAND TARGET CHECK
            ------------------------------------------------------------

            local isCommandTarget =
                (
                    _G.BotVars.CommandTarget
                    == sender
                )


            ------------------------------------------------------------
            -- DEBUG
            ------------------------------------------------------------

            if lower == "!twoline"
                or lower == "!stop"
                or lower == "!untwoline"
                or lower:match("^!twoline%s+") then

                print(
                    "[TwoLine] Command:",
                    lower,
                    "| Sender:",
                    sender.Name,
                    "| Admin:",
                    isAdmin,
                    "| Target:",
                    isCommandTarget
                )

            end


            ----------------------------------------------------------------
            -- !STOP
            --
            -- HANYA ADMIN
            ----------------------------------------------------------------

            if lower == "!stop" then

                if not isAdmin then

                    print(
                        "[TwoLine] !stop ditolak:",
                        sender.Name
                    )

                    return

                end


                _G.BotVars.ActiveMode = nil

                _G.BotVars.CommandTarget = nil


                for _, stopFunction in pairs(
                    _G.BotVars.ModeControllers
                ) do

                    if type(stopFunction) == "function" then

                        pcall(function()

                            stopFunction()

                        end)

                    end

                end


                print(
                    "[TwoLine] Semua mode dihentikan oleh:",
                    sender.Name
                )

                return

            end


            ----------------------------------------------------------------
            -- !UNTWOLINE
            --
            -- HANYA ADMIN
            ----------------------------------------------------------------

            if lower == "!untwoline" then

                if not isAdmin then
                    return
                end


                if _G.BotVars.ActiveMode
                    == "twoline" then

                    _G.BotVars.ActiveMode = nil

                end


                stopTwoLine()


                print(
                    "[TwoLine] TwoLine dihentikan oleh:",
                    sender.Name
                )

                return

            end


            ----------------------------------------------------------------
            -- !TWOLINE
            --
            -- ADMIN ATAU COMMAND TARGET
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


                ------------------------------------------------------------
                -- ADMIN / COMMAND TARGET MENJADI TARGET
                ------------------------------------------------------------

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
                        "[TwoLine] Target selection ditolak:",
                        sender.Name
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


                startTwoLine(
                    target
                )

                return

            end

        end


        ----------------------------------------------------------------
        -- CHAT CONNECTION
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
        -- CONNECT EXISTING PLAYERS
        ----------------------------------------------------------------

        for _, player in ipairs(
            Players:GetPlayers()
        ) do

            connectPlayerChat(
                player
            )

        end


        ----------------------------------------------------------------
        -- CONNECT NEW PLAYERS
        ----------------------------------------------------------------

        Players.PlayerAdded:Connect(
            function(player)

                connectPlayerChat(
                    player
                )

            end
        )


        ----------------------------------------------------------------
        -- CLEAN PLAYER
        ----------------------------------------------------------------

        Players.PlayerRemoving:Connect(
            function(player)

                connectedPlayers[player] = nil

            end
        )


        ----------------------------------------------------------------
        -- TEXT CHAT MESSAGE RECEIVED
        --
        -- Dipasang dengan cara yang aman.
        ----------------------------------------------------------------

        task.spawn(function()

            local channels =
                TextChatService:WaitForChild(
                    "TextChannels",
                    10
                )

            if not channels then

                warn(
                    "[TwoLine] TextChannels tidak ditemukan."
                )

                return

            end


            local channel =
                channels:WaitForChild(
                    "RBXGeneral",
                    10
                )


            if not channel then

                warn(
                    "[TwoLine] RBXGeneral tidak ditemukan."
                )

                return

            end


            channel.MessageReceived:Connect(
                function(message)

                    if not message then
                        return
                    end


                    local textSource =
                        message.TextSource


                    if not textSource then
                        return
                    end


                    local sender =
                        Players:GetPlayerByUserId(
                            textSource.UserId
                        )


                    if not sender then
                        return
                    end


                    handleCommand(
                        message.Text,
                        sender
                    )

                end
            )


            print(
                "[TwoLine] TextChatService listener aktif."
            )

        end)


        ----------------------------------------------------------------
        -- CHARACTER RESPAWN
        ----------------------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(
            function()

                task.wait(1)

                updateCharacter()


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