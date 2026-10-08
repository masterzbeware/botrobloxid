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

        local adminSuccess, adminResult =
            pcall(function()

                return loadstring(game:HttpGet(
                    "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
                ))()

            end)

        if not adminSuccess or not adminResult then

            warn(
                "[TwoLine] Gagal load Admin.lua"
            )

            return

        end

        Admin = adminResult


        ----------------------------------------------------------------
        -- LOAD DISTANCE
        ----------------------------------------------------------------

        local Distance

        local distanceSuccess, distanceResult =
            pcall(function()

                return loadstring(game:HttpGet(
                    "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
                ))()

            end)

        if not distanceSuccess or not distanceResult then

            warn(
                "[TwoLine] Gagal load Distance.lua"
            )

            return

        end

        Distance = distanceResult


        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local humanoid = nil
        local myHRP = nil

        local twoLining = false
        local targetPlayer = nil
        local twoLineConnection = nil


        ----------------------------------------------------------------
        -- FORMATION
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
            "11775843339", -- Bot 12,

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
                -- LEGACY FALLBACK
                --------------------------------------------------------

                local chatEvents =
                    ReplicatedStorage:FindFirstChild(
                        "DefaultChatSystemChatEvents"
                    )

                if chatEvents then

                    local request =
                        chatEvents:FindFirstChild(
                            "SayMessageRequest"
                        )

                    if request then

                        request:FireServer(
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
        -- TWO LINE OFFSET
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


            print(
                "[TwoLine] START TWO LINE:",
                player.Name
            )


            ------------------------------------------------------------
            -- STOP MODE LAIN
            ------------------------------------------------------------

            stopOtherModes()


            ------------------------------------------------------------
            -- GLOBAL STATE
            ------------------------------------------------------------

            _G.BotVars.ActiveMode =
                "twoline"

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
            -- BOT INDEX
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
                    "[TwoLine] UserId bukan bot:",
                    LocalPlayer.UserId,
                    LocalPlayer.Name
                )

                stopTwoLine()

                return

            end


            print(
                "[TwoLine] Bot:",
                LocalPlayer.Name,
                "| Index:",
                myIndex,
                "| Target:",
                player.Name
            )


            ------------------------------------------------------------
            -- CHAT
            ------------------------------------------------------------

            sendChat("Yes, Sir!")


            ------------------------------------------------------------
            -- LOOP
            ------------------------------------------------------------

            twoLineConnection =
                RunService.Heartbeat:Connect(
                    function()

                        if _G.BotVars.ActiveMode
                            ~= "twoline" then

                            stopTwoLine()

                            return

                        end


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
                        -- MOVE
                        ------------------------------------------------

                        local distanceToTarget =
                            (
                                myHRP.Position
                                -
                                targetPosition
                            ).Magnitude


                        if distanceToTarget > 1.5 then

                            humanoid.AutoRotate = true

                            humanoid:MoveTo(
                                targetPosition
                            )

                            return

                        end


                        ------------------------------------------------
                        -- FACE TARGET
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

            if not message then
                return
            end

            if not sender then
                return
            end


            ------------------------------------------------------------
            -- NORMALIZE
            ------------------------------------------------------------

            local lower =
                tostring(message)
                :lower()
                :gsub("^%s+", "")
                :gsub("%s+$", "")


            if lower == "" then
                return
            end


            ------------------------------------------------------------
            -- ADMIN
            ------------------------------------------------------------

            local isAdmin = false

            pcall(function()

                isAdmin =
                    Admin:IsAdmin(sender)

            end)


            ------------------------------------------------------------
            -- COMMAND TARGET
            ------------------------------------------------------------

            local isCommandTarget =
                (
                    _G.BotVars.CommandTarget
                    == sender
                )


            ------------------------------------------------------------
            -- DEBUG SEMUA TWOLINE
            ------------------------------------------------------------

            if lower:sub(1, 8) == "!twoline" then

                print(
                    "[TwoLine] CHAT RECEIVED:",
                    lower,
                    "| Sender:",
                    sender.Name,
                    "| Admin:",
                    isAdmin,
                    "| CommandTarget:",
                    isCommandTarget
                )

            end


            ----------------------------------------------------------------
            -- !STOP
            ----------------------------------------------------------------

            if lower == "!stop" then

                if not isAdmin then

                    print(
                        "[TwoLine] !stop DITOLAK:",
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

                        pcall(
                            stopFunction
                        )

                    end

                end


                print(
                    "[TwoLine] Semua mode dihentikan."
                )

                return

            end


            ----------------------------------------------------------------
            -- !UNTWOLINE
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
                    "[TwoLine] TwoLine dihentikan."
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
                        "[TwoLine] !twoline DITOLAK:",
                        sender.Name
                    )

                    return

                end


                print(
                    "[TwoLine] !twoline DITERIMA:",
                    sender.Name
                )


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
                        "[TwoLine] Target selection DITOLAK:",
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
                        "[TwoLine] PLAYER TIDAK DITEMUKAN:",
                        targetName
                    )

                    return

                end


                print(
                    "[TwoLine] TARGET DIPILIH:",
                    target.Name
                )


                startTwoLine(
                    target
                )

                return

            end

        end


        ----------------------------------------------------------------
        -- CHAT LISTENER UTAMA
        --
        -- PENTING:
        -- Gunakan TextChatService.MessageReceived,
        -- bukan hanya RBXGeneral.MessageReceived.
        ----------------------------------------------------------------

        local textChatConnected = false


        if TextChatService then

            TextChatService.MessageReceived:Connect(
                function(message)

                    if not message then
                        return
                    end


                    local textSource =
                        message.TextSource


                    if not textSource then
                        return
                    end


                    local userId =
                        textSource.UserId


                    local sender =
                        Players:GetPlayerByUserId(
                            userId
                        )


                    if not sender then
                        return
                    end


                    textChatConnected = true


                    handleCommand(
                        message.Text,
                        sender
                    )

                end
            )


            print(
                "[TwoLine] TextChatService.MessageReceived AKTIF."
            )

        end


        ----------------------------------------------------------------
        -- FALLBACK PLAYER.CHATTED
        ----------------------------------------------------------------

        local connectedPlayers = {}


        local function connectPlayer(player)

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


        for _, player in ipairs(
            Players:GetPlayers()
        ) do

            connectPlayer(player)

        end


        Players.PlayerAdded:Connect(
            function(player)

                connectPlayer(player)

            end
        )


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
            "[TwoLine] =================================="
        )

        print(
            "[TwoLine] TwoLine berhasil dimuat."
        )

        print(
            "[TwoLine] Bot:",
            LocalPlayer.Name
        )

        print(
            "[TwoLine] UserId:",
            LocalPlayer.UserId
        )

        print(
            "[TwoLine] =================================="
        )

    end

}