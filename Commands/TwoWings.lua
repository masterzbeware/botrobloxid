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
        -- VARIABLES
        ----------------------------------------------------------------

        local humanoid
        local myHRP

        local twoWingsActive = false
        local targetPlayer = nil
        local twoWingsConnection = nil

        ----------------------------------------------------------------
        -- DISTANCE
        ----------------------------------------------------------------

        local adminFollowDistance = 3
        local defaultBotFollowDistance = 2

        ----------------------------------------------------------------
        -- TWOWINGS CONFIG
        ----------------------------------------------------------------

        -- Jarak ke belakang berdasarkan baris
        local rowSpacing = 2.5

        -- Jarak kiri dan kanan
        local sideSpacing = 2.5

        -- Jarak minimum sebelum berhenti
        local stopThreshold = 1.5

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

                        channel:SendAsync(message)

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
        -- STOP TWOWINGS
        ----------------------------------------------------------------

        local function stopTwoWings()

            twoWingsActive = false
            targetPlayer = nil

            if twoWingsConnection then

                twoWingsConnection:Disconnect()
                twoWingsConnection = nil

            end

            if humanoid then

                humanoid.AutoRotate = true

            end

        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        vars.ModeControllers.twowings =
            stopTwoWings

        ----------------------------------------------------------------
        -- STOP SEMUA MODE LAIN
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                vars.ModeControllers
            ) do

                if name ~= "twowings"
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
        -- GET DISTANCE
        ----------------------------------------------------------------

        local function getBotDistance(player)

            local distance =
                defaultBotFollowDistance

            ------------------------------------------------------------
            -- ADMIN DISTANCE
            ------------------------------------------------------------

            if Admin:IsAdmin(player) then

                distance =
                    adminFollowDistance

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

                distance =
                    specialDistance

            end

            return distance

        end

        ----------------------------------------------------------------
        -- GET TWOWINGS POSITION
        ----------------------------------------------------------------
        --
        -- FORMASI:
        --
        -- B1  B2  B3             B9  B10  B11
        --       B4             B8
        --          B5       B7
        --             B6
        --            PLAYER
        --
        -- SEMUA BOT BERADA DI BELAKANG PLAYER
        --
        -- B3 lebih belakang dari B4
        -- B9 lebih belakang dari B8
        --
        ----------------------------------------------------------------

        local function getTwoWingsPosition(
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
            -- TARGET AXIS
            ------------------------------------------------------------

            local backward =
                -targetHRP.CFrame.LookVector

            local right =
                targetHRP.CFrame.RightVector

            local origin =
                targetHRP.Position

            ------------------------------------------------------------
            -- POSISI BELAKANG
            ------------------------------------------------------------

            local backDistance
            local sideOffset

            ------------------------------------------------------------
            -- BARIS 1
            --
            -- B1  B2  B3       B9  B10  B11
            --
            ------------------------------------------------------------

            if myIndex == 1 then

                backDistance =
                    distance + (rowSpacing * 3)

                sideOffset =
                    -sideSpacing * 2

            elseif myIndex == 2 then

                backDistance =
                    distance + (rowSpacing * 3)

                sideOffset =
                    -sideSpacing

            elseif myIndex == 3 then

                ------------------------------------------------
                -- B3 DI BELAKANG B4
                ------------------------------------------------

                backDistance =
                    distance + (rowSpacing * 4)

                sideOffset =
                    -sideSpacing * 0.5

            elseif myIndex == 9 then

                ------------------------------------------------
                -- B9 DI BELAKANG B8
                ------------------------------------------------

                backDistance =
                    distance + (rowSpacing * 4)

                sideOffset =
                    sideSpacing * 0.5

            elseif myIndex == 10 then

                backDistance =
                    distance + (rowSpacing * 3)

                sideOffset =
                    sideSpacing

            elseif myIndex == 11 then

                backDistance =
                    distance + (rowSpacing * 3)

                sideOffset =
                    sideSpacing * 2

            ------------------------------------------------------------
            -- BARIS 2
            --
            --       B4             B8
            --
            ------------------------------------------------------------

            elseif myIndex == 4 then

                backDistance =
                    distance + (rowSpacing * 2)

                sideOffset =
                    -sideSpacing * 0.5

            elseif myIndex == 8 then

                backDistance =
                    distance + (rowSpacing * 2)

                sideOffset =
                    sideSpacing * 0.5

            ------------------------------------------------------------
            -- BARIS 3
            --
            --          B5       B7
            --
            ------------------------------------------------------------

            elseif myIndex == 5 then

                backDistance =
                    distance + rowSpacing

                sideOffset =
                    -sideSpacing * 0.5

            elseif myIndex == 7 then

                backDistance =
                    distance + rowSpacing

                sideOffset =
                    sideSpacing * 0.5

            ------------------------------------------------------------
            -- BARIS DEPAN
            --
            --             B6
            --
            ------------------------------------------------------------

            elseif myIndex == 6 then

                backDistance =
                    distance

                sideOffset =
                    0

            end

            ------------------------------------------------------------
            -- VALIDASI
            ------------------------------------------------------------

            if not backDistance
                or sideOffset == nil then

                return nil

            end

            ------------------------------------------------------------
            -- BACK OFFSET
            --
            -- SELALU NEGATIVE LOOKVECTOR
            -- = DI BELAKANG PLAYER
            ------------------------------------------------------------

            local backOffset =
                backward * backDistance

            ------------------------------------------------------------
            -- SIDE OFFSET
            ------------------------------------------------------------

            local sideOffsetVector =
                right * sideOffset

            ------------------------------------------------------------
            -- FINAL POSITION
            ------------------------------------------------------------

            local targetPosition =
                origin
                + backOffset
                + sideOffsetVector

            return targetPosition

        end

        ----------------------------------------------------------------
        -- START TWOWINGS
        ----------------------------------------------------------------

        local function startTwoWings(player)

            if not player then
                return
            end

            ------------------------------------------------------------
            -- STOP MODE LAIN
            ------------------------------------------------------------

            stopOtherModes()

            ------------------------------------------------------------
            -- SET ACTIVE MODE
            ------------------------------------------------------------

            vars.ActiveMode =
                "twowings"

            ------------------------------------------------------------
            -- STOP CONNECTION LAMA
            ------------------------------------------------------------

            if twoWingsConnection then

                twoWingsConnection:Disconnect()
                twoWingsConnection = nil

            end

            ------------------------------------------------------------
            -- STATE
            ------------------------------------------------------------

            twoWingsActive = true
            targetPlayer = player

            ------------------------------------------------------------
            -- CHAT
            ------------------------------------------------------------

            sendChat("Yes, Sir!")

            ------------------------------------------------------------
            -- CARI INDEX BOT
            ------------------------------------------------------------

            local myIndex =
                table.find(
                    botOrder,
                    tostring(LocalPlayer.UserId)
                )

            ------------------------------------------------------------
            -- BOT TIDAK TERDAFTAR
            ------------------------------------------------------------

            if not myIndex then

                print(
                    "[TWOWINGS]",
                    "Bot tidak termasuk formasi:",
                    LocalPlayer.Name,
                    LocalPlayer.UserId
                )

                stopTwoWings()

                return

            end

            ------------------------------------------------------------
            -- DEBUG
            ------------------------------------------------------------

            print(
                "[TWOWINGS]",
                "Bot Index:",
                myIndex,
                "UserId:",
                LocalPlayer.UserId
            )

            ------------------------------------------------------------
            -- TWOWINGS LOOP
            ------------------------------------------------------------

            twoWingsConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- JIKA MODE BERGANTI
                        ------------------------------------------------

                        if vars.ActiveMode
                            ~= "twowings" then

                            stopTwoWings()

                            return

                        end

                        ------------------------------------------------
                        -- VALIDASI ACTIVE
                        ------------------------------------------------

                        if not twoWingsActive then
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
                        -- TWOWINGS POSITION
                        ------------------------------------------------

                        local targetPosition =
                            getTwoWingsPosition(
                                myIndex,
                                targetHRP,
                                distance
                            )

                        if not targetPosition then
                            return
                        end

                        ------------------------------------------------
                        -- DISTANCE TO TARGET POSITION
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
                        -- SUDAH SAMPAI
                        ------------------------------------------------

                        humanoid.AutoRotate = false

                        ------------------------------------------------
                        -- MENGHADAP SAMA SEPERTI PLAYER
                        ------------------------------------------------

                        local adminRotation =
                            targetHRP.CFrame
                            - targetHRP.Position

                        myHRP.CFrame =
                            CFrame.new(
                                myHRP.Position
                            )
                            * adminRotation

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

            ------------------------------------------------------------
            -- ADMIN ONLY
            ------------------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end

            local lower =
                message:lower()

            ------------------------------------------------------------
            -- !TWOWINGS
            ------------------------------------------------------------

            if lower == "!twowings" then

                startTwoWings(
                    sender
                )

                return

            end

            ------------------------------------------------------------
            -- !TWOWINGS PLAYER
            ------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!twowings%s+(.+)$"
                )

            if targetName then

                local target =
                    findPlayerByName(
                        targetName
                    )

                if target then

                    startTwoWings(
                        target
                    )

                end

                return

            end

            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if lower == "!stop"
                or lower == "!untwowings" then

                vars.ActiveMode = nil

                stopTwoWings()

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
        -- OLD CHAT FALLBACK
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

                --------------------------------------------------------
                -- RESTART TWOWINGS
                --------------------------------------------------------

                if vars.ActiveMode
                    == "twowings"
                    and targetPlayer then

                    startTwoWings(
                        targetPlayer
                    )

                end

            end
        )

        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[TWOWINGS] TwoWings.lua aktif!"
        )

    end
}