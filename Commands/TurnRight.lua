```lua
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

        local turnRightActive = false
        local turnRightConnection = nil
        local targetPlayer = nil

        ----------------------------------------------------------------
        -- FORMATION SETTINGS
        ----------------------------------------------------------------

        local formationSpacing = 3
        local formationDistance = 3
        local stopThreshold = 1.5
        local formationHeight = 0

        ----------------------------------------------------------------
        -- TURN SETTINGS
        ----------------------------------------------------------------

        -- Jarak Bot 11 setelah belok
        local turnDistance = 3

        -- Jarak minimum
        local turnMoveThreshold = 1.5

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

                        channel:SendAsync(
                            message
                        )

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
        -- STOP TURN RIGHT
        ----------------------------------------------------------------

        local function stopTurnRight()

            turnRightActive = false
            targetPlayer = nil

            if turnRightConnection then

                turnRightConnection:Disconnect()
                turnRightConnection = nil

            end

            if humanoid then

                humanoid.AutoRotate = true

            end

        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        vars.ModeControllers.turnright =
            stopTurnRight

        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                vars.ModeControllers
            ) do

                if name ~= "turnright"
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
        -- GET BOT DISTANCE
        ----------------------------------------------------------------

        local function getBotDistance(player)

            local distance = 1

            ------------------------------------------------------------
            -- ADMIN DEFAULT
            ------------------------------------------------------------

            if Admin:IsAdmin(player) then

                distance = 1

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

                distance = specialDistance

            end

            return distance

        end

        ----------------------------------------------------------------
        -- GET NORMAL FORMATION POSITION
        ----------------------------------------------------------------

        local function getFormationPosition(
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
            -- POSISI DASAR BARISAN
            ------------------------------------------------------------

            local targetPosition =
                targetHRP.Position
                -
                (
                    targetHRP.CFrame.LookVector
                    *
                    (
                        formationDistance
                        + distance
                    )
                )

            ------------------------------------------------------------
            -- OFFSET KIRI / KANAN
            ------------------------------------------------------------

            local horizontalOffset =
                (myIndex - 1)
                * formationSpacing

            ------------------------------------------------------------
            -- POSISI SAMPING
            ------------------------------------------------------------

            local sidePosition =
                targetHRP.CFrame.RightVector
                * horizontalOffset

            return targetPosition
                + sidePosition
                + Vector3.new(
                    0,
                    formationHeight,
                    0
                )

        end

        ----------------------------------------------------------------
        -- GET TURN RIGHT POSITION
        ----------------------------------------------------------------
        --
        -- HANYA BOT 11 YANG MENGGUNAKAN POSISI INI.
        --
        -- Bot 11 akan bergerak 90 derajat ke KANAN.
        --
        ----------------------------------------------------------------

        local function getTurnRightPosition(
            myIndex,
            targetHRP,
            distance
        )

            if not targetHRP
                or not distance then

                return nil
            end

            ------------------------------------------------------------
            -- POSISI NORMAL BOT 11
            ------------------------------------------------------------

            local normalPosition =
                getFormationPosition(
                    myIndex,
                    targetHRP,
                    distance
                )

            if not normalPosition then
                return nil
            end

            ------------------------------------------------------------
            -- ARAH KANAN PLAYER
            ------------------------------------------------------------

            local rightVector =
                targetHRP.CFrame.RightVector

            ------------------------------------------------------------
            -- POSISI SETELAH BELOK
            ------------------------------------------------------------

            local turnPosition =
                normalPosition
                +
                (
                    rightVector
                    *
                    turnDistance
                )

            return turnPosition

        end

        ----------------------------------------------------------------
        -- COPY TARGET ROTATION
        ----------------------------------------------------------------

        local function copyTargetRotation(
            targetHRP
        )

            if not targetHRP
                or not myHRP then

                return
            end

            local targetRotation =
                targetHRP.CFrame
                -
                targetHRP.Position

            myHRP.CFrame =
                CFrame.new(
                    myHRP.Position
                )
                *
                targetRotation

        end

        ----------------------------------------------------------------
        -- ROTATE 90 DEGREE RIGHT
        ----------------------------------------------------------------

        local function rotate90Right(
            targetHRP
        )

            if not targetHRP
                or not myHRP then

                return
            end

            ------------------------------------------------------------
            -- ROTASI TARGET
            ------------------------------------------------------------

            local targetRotation =
                targetHRP.CFrame
                -
                targetHRP.Position

            ------------------------------------------------------------
            -- 90 DEGREE KE KANAN
            ------------------------------------------------------------

            local rightRotation =
                CFrame.Angles(
                    0,
                    math.rad(90),
                    0
                )

            ------------------------------------------------------------
            -- APPLY ROTATION
            ------------------------------------------------------------

            myHRP.CFrame =
                CFrame.new(
                    myHRP.Position
                )
                *
                targetRotation
                *
                rightRotation

        end

        ----------------------------------------------------------------
        -- START TURN RIGHT
        ----------------------------------------------------------------

        local function startTurnRight(player)

            if not player then
                return
            end

            ------------------------------------------------------------
            -- STOP MODE LAIN
            ------------------------------------------------------------

            stopOtherModes()

            ------------------------------------------------------------
            -- ACTIVE MODE
            ------------------------------------------------------------

            vars.ActiveMode =
                "turnright"

            ------------------------------------------------------------
            -- DISCONNECT LOOP LAMA
            ------------------------------------------------------------

            if turnRightConnection then

                turnRightConnection:Disconnect()
                turnRightConnection = nil

            end

            ------------------------------------------------------------
            -- STATE
            ------------------------------------------------------------

            turnRightActive = true
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
                    tostring(LocalPlayer.UserId)
                )

            if not myIndex then

                print(
                    "[TURNRIGHT]",
                    "Bot ini bukan Bot 1-11:",
                    LocalPlayer.UserId
                )

                stopTurnRight()

                return

            end

            ------------------------------------------------------------
            -- DEBUG
            ------------------------------------------------------------

            print(
                "[TURNRIGHT]",
                "Bot Index:",
                myIndex,
                "UserId:",
                LocalPlayer.UserId
            )

            ------------------------------------------------------------
            -- HEARTBEAT
            ------------------------------------------------------------

            turnRightConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- MODE CHECK
                        ------------------------------------------------

                        if vars.ActiveMode
                            ~= "turnright" then

                            stopTurnRight()

                            return

                        end

                        ------------------------------------------------
                        -- ACTIVE CHECK
                        ------------------------------------------------

                        if not turnRightActive then
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

                        local botDistance =
                            getBotDistance(
                                targetPlayer
                            )

                        ------------------------------------------------
                        -- BOT 11
                        ------------------------------------------------

                        if myIndex == #botOrder then

                            ------------------------------------------------
                            -- POSISI TURN RIGHT
                            ------------------------------------------------

                            local targetPosition =
                                getTurnRightPosition(
                                    myIndex,
                                    targetHRP,
                                    botDistance
                                )

                            if not targetPosition then
                                return
                            end

                            ------------------------------------------------
                            -- JARAK
                            ------------------------------------------------

                            local distanceToTarget =
                                (
                                    myHRP.Position
                                    -
                                    targetPosition
                                ).Magnitude

                            ------------------------------------------------
                            -- JALAN
                            ------------------------------------------------

                            if distanceToTarget
                                > turnMoveThreshold then

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
                            -- PUTAR 90 DERAJAT KE KANAN
                            ------------------------------------------------

                            rotate90Right(
                                targetHRP
                            )

                            return

                        end

                        ------------------------------------------------
                        -- BOT 1 - BOT 10
                        ------------------------------------------------

                        local targetPosition =
                            getFormationPosition(
                                myIndex,
                                targetHRP,
                                botDistance
                            )

                        if not targetPosition then
                            return
                        end

                        ------------------------------------------------
                        -- JARAK
                        ------------------------------------------------

                        local distanceToTarget =
                            (
                                myHRP.Position
                                -
                                targetPosition
                            ).Magnitude

                        ------------------------------------------------
                        -- JALAN
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
                        -- BOT 1 - 10
                        -- MENGHADAP SAMA DENGAN TARGET
                        ------------------------------------------------

                        copyTargetRotation(
                            targetHRP
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

            ------------------------------------------------------------
            -- ADMIN ONLY
            ------------------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end

            local lower =
                message:lower()

            ------------------------------------------------------------
            -- !TURNRIGHT
            ------------------------------------------------------------

            if lower == "!turnright" then

                startTurnRight(sender)

                return

            end

            ------------------------------------------------------------
            -- !TURNRIGHT PLAYER
            ------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!turnright%s+(.+)$"
                )

            if targetName then

                local target =
                    findPlayerByName(
                        targetName
                    )

                if target then

                    startTurnRight(
                        target
                    )

                end

                return

            end

            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if lower == "!stop"
                or lower == "!unturnright" then

                vars.ActiveMode = nil

                stopTurnRight()

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
        -- OLD CHAT
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
        -- NEW PLAYER
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

                if vars.ActiveMode
                    == "turnright"
                    and targetPlayer then

                    startTurnRight(
                        targetPlayer
                    )

                end

            end
        )

    end
}