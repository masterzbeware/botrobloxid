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
        _G.BotVars.ModeControllers = _G.BotVars.ModeControllers or {}

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

        local following = false
        local targetPlayer = nil
        local followConnection = nil

        ----------------------------------------------------------------
        -- DISTANCE
        ----------------------------------------------------------------

        local adminFollowDistance = 3
        local defaultBotFollowDistance = 2

        ----------------------------------------------------------------
        -- ROLLING CONFIG
        ----------------------------------------------------------------

        -- Jarak kiri dan kanan
        local sideSpacing = 2.5

        -- Jarak antar baris
        local rowSpacing = 3

        -- Jarak minimum sebelum dianggap sudah sampai
        local stopThreshold = 1.5

        -- Kecepatan gerakan saat rolling
        local rollSpeed = 10

        -- Jarak bot menuju tengah
        local centerDistance = 2

        -- Waktu tunggu antar perpindahan
        local rollDelay = 0.25

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
        -- STOP ROLLING
        ----------------------------------------------------------------

        local function stopRolling()

            following = false
            targetPlayer = nil

            if followConnection then

                followConnection:Disconnect()
                followConnection = nil

            end

            if humanoid then

                humanoid.AutoRotate = true
                humanoid:MoveTo(myHRP.Position)

            end

        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.rolling = stopRolling

        ----------------------------------------------------------------
        -- STOP SEMUA MODE LAIN
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "rolling"
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
        -- GET BOT INDEX
        ----------------------------------------------------------------

        local function getBotIndex()

            return table.find(
                botOrder,
                tostring(LocalPlayer.UserId)
            )

        end

        ----------------------------------------------------------------
        -- GET DISTANCE
        ----------------------------------------------------------------

        local function getFollowDistance(player)

            local distance =
                defaultBotFollowDistance

            if Admin:IsAdmin(player) then

                distance =
                    adminFollowDistance

            end

            local success, specialDistance =
                pcall(function()

                    return Distance:GetDistance(
                        tostring(LocalPlayer.UserId),
                        tostring(player.UserId)
                    )

                end)

            if success
                and specialDistance then

                distance =
                    specialDistance

            end

            return distance

        end

        ----------------------------------------------------------------
        -- GET NORMAL TWOLINE POSITION
        ----------------------------------------------------------------

        local function getNormalPosition(
            index,
            targetHRP,
            distance
        )

            ------------------------------------------------------------
            -- BOT 1 - 8
            ------------------------------------------------------------

            local row =
                math.ceil(index / 2)

            local side

            if index % 2 == 1 then

                -- GANJIL = KIRI
                side = -1

            else

                -- GENAP = KANAN
                side = 1

            end

            ------------------------------------------------------------
            -- BELAKANG
            ------------------------------------------------------------

            local backDistance =
                distance
                + ((row - 1) * rowSpacing)

            local backOffset =
                targetHRP.CFrame.LookVector
                * -backDistance

            ------------------------------------------------------------
            -- KIRI / KANAN
            ------------------------------------------------------------

            local sideOffset =
                targetHRP.CFrame.RightVector
                * (sideSpacing * side)

            ------------------------------------------------------------
            -- FINAL
            ------------------------------------------------------------

            return
                targetHRP.Position
                + backOffset
                + sideOffset

        end

        ----------------------------------------------------------------
        -- BOT 9 POSITION
        ----------------------------------------------------------------

        local function getBot9Position(
            targetHRP,
            distance
        )

            -- BOT 9 berada di kanan,
            -- satu baris di bawah BOT 8.

            local backDistance =
                distance
                + (4 * rowSpacing)

            local backOffset =
                targetHRP.CFrame.LookVector
                * -backDistance

            local sideOffset =
                targetHRP.CFrame.RightVector
                * sideSpacing

            return
                targetHRP.Position
                + backOffset
                + sideOffset

        end

        ----------------------------------------------------------------
        -- GET ROLLING POSITION
        ----------------------------------------------------------------

        local function getRollingPosition(
            index,
            targetHRP,
            distance
        )

            if index == 9 then

                return getBot9Position(
                    targetHRP,
                    distance
                )

            end

            return getNormalPosition(
                index,
                targetHRP,
                distance
            )

        end

        ----------------------------------------------------------------
        -- GET CENTER POSITION
        ----------------------------------------------------------------

        local function getCenterPosition(
            targetHRP,
            distance
        )

            return
                targetHRP.Position
                - targetHRP.CFrame.LookVector
                * (distance + centerDistance)

        end

        ----------------------------------------------------------------
        -- MOVE TO POSITION
        ----------------------------------------------------------------

        local function moveToPosition(
            position
        )

            if not position then
                return false
            end

            if not humanoid
                or not myHRP then

                return false

            end

            local distance =
                (myHRP.Position - position).Magnitude

            if distance <= stopThreshold then

                return true

            end

            humanoid.AutoRotate = true

            humanoid:MoveTo(position)

            return false

        end

        ----------------------------------------------------------------
        -- GET ROLL TARGET
        ----------------------------------------------------------------

        local function getRollTargetPosition(
            targetHRP,
            distance,
            index
        )

            ------------------------------------------------------------
            -- BOT 1
            --
            -- BOT 1 masuk ke tengah lalu ke belakang
            -- setelah BOT 7.
            ------------------------------------------------------------

            if index == 1 then

                local backDistance =
                    distance
                    + (4 * rowSpacing)

                local backOffset =
                    targetHRP.CFrame.LookVector
                    * -backDistance

                local sideOffset =
                    targetHRP.CFrame.RightVector
                    * (-sideSpacing)

                return
                    targetHRP.Position
                    + backOffset
                    + sideOffset

            end

            ------------------------------------------------------------
            -- BOT 2
            --
            -- BOT 2 masuk ke tengah lalu ke belakang
            -- BOT 9.
            ------------------------------------------------------------

            if index == 2 then

                local backDistance =
                    distance
                    + (5 * rowSpacing)

                local backOffset =
                    targetHRP.CFrame.LookVector
                    * -backDistance

                local sideOffset =
                    targetHRP.CFrame.RightVector
                    * sideSpacing

                return
                    targetHRP.Position
                    + backOffset
                    + sideOffset

            end

            return nil

        end

        ----------------------------------------------------------------
        -- ROLL BOT 1
        ----------------------------------------------------------------

        local function rollBot1(
            targetHRP,
            distance
        )

            ------------------------------------------------------------
            -- STEP 1
            -- BOT 1 KE TENGAH
            ------------------------------------------------------------

            local centerPosition =
                getCenterPosition(
                    targetHRP,
                    distance
                )

            moveToPosition(
                centerPosition
            )

            ------------------------------------------------------------
            -- STEP 2
            -- BOT 1 KE BELAKANG BOT 7
            ------------------------------------------------------------

            local finalPosition =
                getRollTargetPosition(
                    targetHRP,
                    distance,
                    1
                )

            moveToPosition(
                finalPosition
            )

        end

        ----------------------------------------------------------------
        -- ROLL BOT 2
        ----------------------------------------------------------------

        local function rollBot2(
            targetHRP,
            distance
        )

            ------------------------------------------------------------
            -- STEP 1
            -- BOT 2 KE TENGAH
            ------------------------------------------------------------

            local centerPosition =
                getCenterPosition(
                    targetHRP,
                    distance
                )

            moveToPosition(
                centerPosition
            )

            ------------------------------------------------------------
            -- STEP 2
            -- BOT 2 KE BELAKANG BOT 9
            ------------------------------------------------------------

            local finalPosition =
                getRollTargetPosition(
                    targetHRP,
                    distance,
                    2
                )

            moveToPosition(
                finalPosition
            )

        end

        ----------------------------------------------------------------
        -- START ROLLING
        ----------------------------------------------------------------

        local function startRolling(
            player
        )

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

            _G.BotVars.ActiveMode =
                "rolling"

            ------------------------------------------------------------
            -- STOP CONNECTION LAMA
            ------------------------------------------------------------

            if followConnection then

                followConnection:Disconnect()
                followConnection = nil

            end

            ------------------------------------------------------------
            -- STATE
            ------------------------------------------------------------

            following = true
            targetPlayer = player

            ------------------------------------------------------------
            -- CHAT
            ------------------------------------------------------------

            sendChat("Yes, Sir!")

            ------------------------------------------------------------
            -- INDEX
            ------------------------------------------------------------

            local myIndex =
                getBotIndex()

            if not myIndex then

                stopRolling()

                return

            end

            ----------------------------------------------------------------
            -- ROLLING LOOP
            ----------------------------------------------------------------

            followConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- MODE CHECK
                        ------------------------------------------------

                        if _G.BotVars.ActiveMode
                            ~= "rolling" then

                            stopRolling()

                            return

                        end

                        ------------------------------------------------
                        -- VALIDASI
                        ------------------------------------------------

                        if not following then
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
                            getFollowDistance(
                                targetPlayer
                            )

                        ------------------------------------------------
                        -- NORMAL POSITION
                        ------------------------------------------------

                        local targetPosition =
                            getRollingPosition(
                                myIndex,
                                targetHRP,
                                distance
                            )

                        ------------------------------------------------
                        -- BOT 1 / BOT 2
                        --
                        -- Untuk sementara mengikuti posisi rolling
                        -- masing-masing.
                        ------------------------------------------------

                        if myIndex == 1 then

                            local centerPosition =
                                getCenterPosition(
                                    targetHRP,
                                    distance
                                )

                            local distanceToCenter =
                                (
                                    myHRP.Position
                                    - centerPosition
                                ).Magnitude

                            if distanceToCenter
                                > stopThreshold then

                                humanoid.AutoRotate = true

                                humanoid:MoveTo(
                                    centerPosition
                                )

                                return

                            end

                        elseif myIndex == 2 then

                            local centerPosition =
                                getCenterPosition(
                                    targetHRP,
                                    distance
                                )

                            local distanceToCenter =
                                (
                                    myHRP.Position
                                    - centerPosition
                                ).Magnitude

                            if distanceToCenter
                                > stopThreshold then

                                humanoid.AutoRotate = true

                                humanoid:MoveTo(
                                    centerPosition
                                )

                                return

                            end

                        end

                        ------------------------------------------------
                        -- MOVE
                        ------------------------------------------------

                        if targetPosition then

                            local distanceToTarget =
                                (
                                    myHRP.Position
                                    - targetPosition
                                ).Magnitude

                            if distanceToTarget
                                > stopThreshold then

                                humanoid.AutoRotate = true

                                humanoid:MoveTo(
                                    targetPosition
                                )

                                return

                            end

                        end

                        ------------------------------------------------
                        -- ARRIVED
                        ------------------------------------------------

                        humanoid.AutoRotate = false

                        ------------------------------------------------
                        -- ROTATION
                        ------------------------------------------------

                        local targetRotation =
                            targetHRP.CFrame
                            - targetHRP.Position

                        myHRP.CFrame =
                            CFrame.new(
                                myHRP.Position
                            )
                            * targetRotation

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

            if not Admin:IsAdmin(sender) then
                return
            end

            local lower =
                message:lower()

            ------------------------------------------------------------
            -- !ROLLING
            ------------------------------------------------------------

            if lower == "!rolling" then

                startRolling(sender)

                return

            end

            ------------------------------------------------------------
            -- !ROLLING PLAYER
            ------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!rolling%s+(.+)$"
                )

            if targetName then

                local target =
                    findPlayerByName(
                        targetName
                    )

                if target then

                    startRolling(target)

                end

                return

            end

            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if lower == "!stop"
                or lower == "!unrolling" then

                _G.BotVars.ActiveMode = nil

                stopRolling()

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

                --------------------------------------------------------
                -- JIKA ROLLING MASIH AKTIF
                --------------------------------------------------------

                if _G.BotVars.ActiveMode
                    == "rolling"
                    and targetPlayer then

                    startRolling(
                        targetPlayer
                    )

                end

            end
        )

    end
}