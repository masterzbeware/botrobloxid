return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[Fourline] LocalPlayer tidak ditemukan.")
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

        local Admin

        do
            local success, result = pcall(function()
                return loadstring(game:HttpGet(
                    "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
                ))()
            end)

            if success and result then
                Admin = result
            else
                warn("[Fourline] Gagal load Admin.lua.")
                return
            end
        end


        ----------------------------------------------------------------
        -- LOAD DISTANCE
        ----------------------------------------------------------------

        local Distance

        do
            local success, result = pcall(function()
                return loadstring(game:HttpGet(
                    "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
                ))()
            end)

            if success and result then
                Distance = result
            else
                warn("[Fourline] Gagal load Distance.lua.")
                return
            end
        end


        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local humanoid = nil
        local myHRP = nil

        local fourlining = false
        local targetPlayer = nil

        local fourlineConnection = nil


        ----------------------------------------------------------------
        -- FORMATION DISTANCE
        ----------------------------------------------------------------

        local adminFourlineDistance = 6
        local defaultBotFourlineDistance = 6

        -- Jarak antar bot kiri-kanan
        local formationSpacing = 3

        -- Jarak antar baris
        local rowSpacing = 3


        ----------------------------------------------------------------
        -- BOT ORDER
        ----------------------------------------------------------------

        -- FORMASI:
        --
        --          PLAYER
        --
        --       B1   B2   B3   B4
        --       B5   B6   B7   B8
        --        B9  B10  B11
        --
        -- Semua bot berada DI BELAKANG player
        -- dan menghadap ke arah yang sama.

local botOrder = {
    "11001608049", -- Bot 1
    "11001607521", -- Bot 2
    "11611493000", -- Bot 3
    "11611503633", -- Bot 4
    "11611567975", -- Bot 5
    "11611562042", -- Bot 6
    "11611591921", -- Bot 7
    "11611597741", -- Bot 8
    "11122806815", -- Bot 9
    "11122806817", -- Bot 10
    "11122687468", -- Bot 11
    "11122854402", -- Bot 12
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

                local TextChatService =
                    game:GetService("TextChatService")

                local channel =
                    TextChatService.TextChannels
                    and TextChatService.TextChannels:FindFirstChild(
                        "RBXGeneral"
                    )

                if channel then

                    channel:SendAsync(message)

                    return

                end


                --------------------------------------------------------
                -- OLD CHAT FALLBACK
                --------------------------------------------------------

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


        ----------------------------------------------------------------
        -- STOP FOURLINE
        ----------------------------------------------------------------

        local function stopFourline()

            fourlining = false
            targetPlayer = nil


            if fourlineConnection then

                fourlineConnection:Disconnect()
                fourlineConnection = nil

            end


            if humanoid then
                humanoid.AutoRotate = true
            end

        end


        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.fourline =
            stopFourline


        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "fourline"
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

            if not name then
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
            -- PARTIAL USERNAME
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
        -- GET MY INDEX
        ----------------------------------------------------------------

        local function getMyIndex()

            local userId =
                tostring(LocalPlayer.UserId)

            return table.find(
                botOrder,
                userId
            )

        end


        ----------------------------------------------------------------
        -- START FOURLINE
        ----------------------------------------------------------------

        local function startFourline(player)

            if not player then

                warn(
                    "[Fourline] Target player tidak ditemukan."
                )

                return

            end


            ------------------------------------------------------------
            -- STOP MODE LAIN
            ------------------------------------------------------------

            stopOtherModes()


            ------------------------------------------------------------
            -- ACTIVE MODE
            ------------------------------------------------------------

            _G.BotVars.ActiveMode = "fourline"


            ------------------------------------------------------------
            -- DISCONNECT OLD LOOP
            ------------------------------------------------------------

            if fourlineConnection then

                fourlineConnection:Disconnect()
                fourlineConnection = nil

            end


            ------------------------------------------------------------
            -- GET BOT INDEX
            ------------------------------------------------------------

            local myIndex =
                getMyIndex()


            if not myIndex then

                warn(
                    "[Fourline] Bot ini tidak terdapat di botOrder."
                )

                warn(
                    "[Fourline] LocalPlayer:",
                    LocalPlayer.Name
                )

                warn(
                    "[Fourline] UserId:",
                    LocalPlayer.UserId
                )

                warn(
                    "[Fourline] Tambahkan UserId bot ini ke botOrder."
                )

                _G.BotVars.ActiveMode = nil

                stopFourline()

                return

            end


            ------------------------------------------------------------
            -- START
            ------------------------------------------------------------

            fourlining = true
            targetPlayer = player

            sendChat("Yes, Sir!")


            ----------------------------------------------------------------
            -- FOURLINE LOOP
            ----------------------------------------------------------------

            fourlineConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- CHECK ACTIVE MODE
                        ------------------------------------------------

                        if _G.BotVars.ActiveMode
                            ~= "fourline" then

                            stopFourline()

                            return

                        end


                        if not fourlining then
                            return
                        end


                        ------------------------------------------------
                        -- CHARACTER VALIDATION
                        ------------------------------------------------

                        if not humanoid
                            or not myHRP then

                            return

                        end


                        if not targetPlayer then

                            stopFourline()

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
                            defaultBotFourlineDistance


                        ------------------------------------------------
                        -- ADMIN DISTANCE
                        ------------------------------------------------

                        local isTargetAdmin = false

                        pcall(function()

                            isTargetAdmin =
                                Admin:IsAdmin(
                                    targetPlayer
                                )

                        end)


                        if isTargetAdmin then

                            distance =
                                adminFourlineDistance

                        end


                        ------------------------------------------------
                        -- SPECIAL DISTANCE
                        ------------------------------------------------

                        local specialDistance = nil

                        pcall(function()

                            specialDistance =
                                Distance:GetDistance(
                                    tostring(
                                        LocalPlayer.UserId
                                    ),
                                    tostring(
                                        targetPlayer.UserId
                                    )
                                )

                        end)


                        if specialDistance then

                            distance =
                                specialDistance

                        end


                        ------------------------------------------------
                        -- FORMATION SETTINGS
                        ------------------------------------------------

                        local columnCount = 4


                        ------------------------------------------------
                        -- ROW
                        ------------------------------------------------

                        local row =
                            math.floor(
                                (myIndex - 1)
                                / columnCount
                            )


                        ------------------------------------------------
                        -- COLUMN
                        ------------------------------------------------

                        local column =
                            (myIndex - 1)
                            % columnCount


                        ------------------------------------------------
                        -- BOT COUNT THIS ROW
                        ------------------------------------------------

                        local remainingBots =
                            #botOrder
                            - (
                                row
                                * columnCount
                            )


                        local columnsInThisRow =
                            math.min(
                                columnCount,
                                remainingBots
                            )


                        ------------------------------------------------
                        -- CENTER COLUMN
                        ------------------------------------------------

                        local centerColumn =
                            (
                                columnsInThisRow
                                - 1
                            )
                            / 2


                        ------------------------------------------------
                        -- HORIZONTAL OFFSET
                        ------------------------------------------------

                        local horizontalOffset =
                            (
                                column
                                - centerColumn
                            )
                            * formationSpacing


                        ------------------------------------------------
                        -- DEPTH OFFSET
                        ------------------------------------------------

                        local depthOffset =
                            row * rowSpacing


                        ----------------------------------------------------------------
                        -- TARGET POSITION
                        ----------------------------------------------------------------
                        --
                        -- PENTING:
                        --
                        -- Gunakan MINUS LookVector.
                        --
                        -- LookVector = arah DEPAN Player
                        --
                        -- -LookVector = arah BELAKANG Player
                        --
                        -- Jadi bot akan berada di belakang Player.
                        ----------------------------------------------------------------

                        local targetPosition =
                            targetHRP.Position

                            -

                            (
                                targetHRP.CFrame.LookVector
                                * (
                                    distance
                                    + depthOffset
                                )
                            )

                            +

                            (
                                targetHRP.CFrame.RightVector
                                * horizontalOffset
                            )


                        ------------------------------------------------
                        -- DISTANCE TO POSITION
                        ------------------------------------------------

                        local distanceToTarget =
                            (
                                myHRP.Position
                                -
                                targetPosition
                            ).Magnitude


                        ------------------------------------------------
                        -- MOVE TO FORMATION
                        ------------------------------------------------

                        if distanceToTarget > 1.5 then

                            humanoid.AutoRotate = true

                            humanoid:MoveTo(
                                targetPosition
                            )

                            return

                        end


                        ----------------------------------------------------------------
                        -- ARRIVED
                        ----------------------------------------------------------------

                        humanoid.AutoRotate = false


                        ----------------------------------------------------------------
                        -- FACE SAME DIRECTION AS PLAYER
                        ----------------------------------------------------------------
                        --
                        -- Bot tidak membelakangi Player.
                        --
                        -- Bot menghadap ke arah yang sama
                        -- dengan Player/Admin.
                        ----------------------------------------------------------------

                        local forwardDirection =
                            targetHRP.CFrame.LookVector


                        myHRP.CFrame =
                            CFrame.lookAt(
                                myHRP.Position,
                                myHRP.Position
                                + forwardDirection
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
            -- ADMIN CHECK
            ------------------------------------------------------------

            local isAdmin = false

            pcall(function()

                isAdmin =
                    Admin:IsAdmin(sender)

            end)


            if not isAdmin then
                return
            end


            ------------------------------------------------------------
            -- CLEAN MESSAGE
            ------------------------------------------------------------

            local lower =
                message:lower()

            lower =
                lower:gsub(
                    "^%s+",
                    ""
                )

            lower =
                lower:gsub(
                    "%s+$",
                    ""
                )


            ------------------------------------------------------------
            -- !FOURLINE
            ------------------------------------------------------------

            if lower == "!fourline" then

                print(
                    "[Fourline] Command diterima dari:",
                    sender.Name
                )

                startFourline(sender)

                return

            end


            ------------------------------------------------------------
            -- !FOURLINE PLAYER
            ------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!fourline%s+(.+)$"
                )


            if targetName then

                print(
                    "[Fourline] Target command:",
                    targetName
                )


                local target =
                    findPlayerByName(
                        targetName
                    )


                if target then

                    print(
                        "[Fourline] Target ditemukan:",
                        target.Name
                    )

                    startFourline(target)

                else

                    warn(
                        "[Fourline] Player tidak ditemukan:",
                        targetName
                    )

                end


                return

            end


            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if lower == "!stop"
                or lower == "!unfourline" then

                print(
                    "[Fourline] Stop command dari:",
                    sender.Name
                )

                _G.BotVars.ActiveMode = nil

                stopFourline()

                return

            end

        end


        ----------------------------------------------------------------
        -- CHAT HANDLER
        ----------------------------------------------------------------
        --
        -- Tidak menggunakan:
        --
        -- TextChatService.OnIncomingMessage
        --
        -- supaya tidak bentrok dengan Follow / Frontline / Circle.
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

            connectPlayerChat(player)

        end


        ----------------------------------------------------------------
        -- PLAYER ADDED
        ----------------------------------------------------------------

        Players.PlayerAdded:Connect(
            function(player)

                connectPlayerChat(player)

            end
        )


        ----------------------------------------------------------------
        -- PLAYER REMOVING
        ----------------------------------------------------------------

        Players.PlayerRemoving:Connect(
            function(player)

                connectedPlayers[player] = nil


                if targetPlayer == player then

                    _G.BotVars.ActiveMode = nil

                    stopFourline()

                end

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
                -- RESTORE FOURLINE
                --------------------------------------------------------

                if _G.BotVars.ActiveMode
                    == "fourline"
                    and targetPlayer then

                    local currentTarget =
                        targetPlayer

                    task.wait(0.2)

                    startFourline(
                        currentTarget
                    )

                end

            end
        )


        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[Fourline] Loaded untuk:",
            LocalPlayer.Name,
            "| UserId:",
            LocalPlayer.UserId
        )


        local myIndex =
            getMyIndex()


        if myIndex then

            print(
                "[Fourline] Bot Index:",
                myIndex
            )

        else

            warn(
                "[Fourline] UserId bot ini BELUM ADA di botOrder:",
                LocalPlayer.UserId
            )

        end

    end
}