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

        local rolling = false

        ----------------------------------------------------------------
        -- DISTANCE
        ----------------------------------------------------------------

        local adminFollowDistance = 3
        local defaultBotFollowDistance = 2

        ----------------------------------------------------------------
        -- ROLLING CONFIG
        ----------------------------------------------------------------

        -- Jarak kiri / kanan
        local sideSpacing = 2.5

        -- Jarak antar baris
        local rowSpacing = 3

        -- Jarak minimum dianggap sudah sampai
        local stopThreshold = 1.5

        -- Jarak bot ke belakang player
        local baseBackDistance = 0

        -- Jarak tambahan ketika masuk ke tengah
        local centerDistance = 2

        -- Jarak waktu antar BOT
        --
        -- BOT 1 bergerak
        -- tunggu selesai
        -- BOT 2 bergerak
        --
        local turnDelay = 0.5

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
            rolling = false
            targetPlayer = nil

            if followConnection then

                followConnection:Disconnect()
                followConnection = nil

            end

            if humanoid then

                humanoid.AutoRotate = true

                if myHRP then

                    humanoid:MoveTo(
                        myHRP.Position
                    )

                end

            end

        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.rolling =
            stopRolling

        ----------------------------------------------------------------
        -- STOP MODE LAIN
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

            if not name
                or name == "" then

                return nil

            end

            name = name:lower()

            ------------------------------------------------------------
            -- EXACT
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
            -- PARTIAL
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
        -- GET POSITION
        ----------------------------------------------------------------
        --
        -- Posisi awal:
        --
        --             PLAYER
        --
        --       BOT 1       BOT 2
        --       BOT 3       BOT 4
        --       BOT 5       BOT 6
        --       BOT 7       BOT 8
        --                    BOT 9
        --
        ----------------------------------------------------------------

        local function getPosition(
            row,
            side,
            targetHRP,
            distance
        )

            if not targetHRP then
                return nil
            end

            local backDistance =
                distance
                + baseBackDistance
                + ((row - 1) * rowSpacing)

            local backOffset =
                targetHRP.CFrame.LookVector
                * -backDistance

            local sideOffset =
                targetHRP.CFrame.RightVector
                * (sideSpacing * side)

            return
                targetHRP.Position
                + backOffset
                + sideOffset

        end

        ----------------------------------------------------------------
        -- GET ORIGINAL POSITION
        ----------------------------------------------------------------

        local function getOriginalPosition(
            index,
            targetHRP,
            distance
        )

            ------------------------------------------------------------
            -- BOT 9
            ------------------------------------------------------------

            if index == 9 then

                return getPosition(
                    5,
                    1,
                    targetHRP,
                    distance
                )

            end

            ------------------------------------------------------------
            -- BOT 1 - 8
            ------------------------------------------------------------

            local row =
                math.ceil(index / 2)

            local side

            if index % 2 == 1 then

                side = -1

            else

                side = 1

            end

            return getPosition(
                row,
                side,
                targetHRP,
                distance
            )

        end

        ----------------------------------------------------------------
        -- GET ROLLING DESTINATION
        ----------------------------------------------------------------
        --
        -- Urutan:
        --
        -- BOT 1 → belakang BOT 7
        -- BOT 2 → belakang BOT 9
        -- BOT 3 → posisi BOT 1
        -- BOT 4 → posisi BOT 2
        -- BOT 5 → posisi BOT 3
        -- BOT 6 → posisi BOT 4
        -- BOT 7 → posisi BOT 5
        -- BOT 8 → posisi BOT 6
        -- BOT 9 → posisi BOT 7
        --
        ----------------------------------------------------------------

        local function getRollingDestination(
            index,
            targetHRP,
            distance
        )

            ------------------------------------------------------------
            -- BOT 1
            -- KIRI → BARIS 5
            ------------------------------------------------------------

            if index == 1 then

                return getPosition(
                    5,
                    -1,
                    targetHRP,
                    distance
                )

            end

            ------------------------------------------------------------
            -- BOT 2
            -- KANAN → BARIS 6
            ------------------------------------------------------------

            if index == 2 then

                return getPosition(
                    6,
                    1,
                    targetHRP,
                    distance
                )

            end

            ------------------------------------------------------------
            -- BOT 3
            -- POSISI BOT 1
            ------------------------------------------------------------

            if index == 3 then

                return getPosition(
                    1,
                    -1,
                    targetHRP,
                    distance
                )

            end

            ------------------------------------------------------------
            -- BOT 4
            -- POSISI BOT 2
            ------------------------------------------------------------

            if index == 4 then

                return getPosition(
                    1,
                    1,
                    targetHRP,
                    distance
                )

            end

            ------------------------------------------------------------
            -- BOT 5
            -- POSISI BOT 3
            ------------------------------------------------------------

            if index == 5 then

                return getPosition(
                    2,
                    -1,
                    targetHRP,
                    distance
                )

            end

            ------------------------------------------------------------
            -- BOT 6
            -- POSISI BOT 4
            ------------------------------------------------------------

            if index == 6 then

                return getPosition(
                    2,
                    1,
                    targetHRP,
                    distance
                )

            end

            ------------------------------------------------------------
            -- BOT 7
            -- POSISI BOT 5
            ------------------------------------------------------------

            if index == 7 then

                return getPosition(
                    3,
                    -1,
                    targetHRP,
                    distance
                )

            end

            ------------------------------------------------------------
            -- BOT 8
            -- POSISI BOT 6
            ------------------------------------------------------------

            if index == 8 then

                return getPosition(
                    3,
                    1,
                    targetHRP,
                    distance
                )

            end

            ------------------------------------------------------------
            -- BOT 9
            -- POSISI BOT 7
            ------------------------------------------------------------

            if index == 9 then

                return getPosition(
                    4,
                    1,
                    targetHRP,
                    distance
                )

            end

            return nil

        end

        ----------------------------------------------------------------
        -- MOVE AND WAIT
        ----------------------------------------------------------------
        --
        -- Ini yang membuat BOT benar-benar bergiliran.
        --
        -- BOT tidak akan lanjut sebelum sampai tujuan.
        --
        ----------------------------------------------------------------

        local function moveAndWait(
            position
        )

            if not position then
                return false
            end

            if not humanoid
                or not myHRP then

                return false

            end

            humanoid.AutoRotate = true

            humanoid:MoveTo(
                position
            )

            while rolling do

                if not humanoid
                    or not myHRP then

                    return false

                end

                local currentDistance =
                    (
                        myHRP.Position
                        - position
                    ).Magnitude

                if currentDistance
                    <= stopThreshold then

                    humanoid:MoveTo(
                        myHRP.Position
                    )

                    return true

                end

                RunService.Heartbeat:Wait()

            end

            return false

        end

        ----------------------------------------------------------------
        -- MOVE THROUGH CENTER
        ----------------------------------------------------------------

        local function moveThroughCenter(
            targetHRP,
            distance
        )

            if not targetHRP then
                return false
            end

            ------------------------------------------------------------
            -- POSISI TENGAH
            ------------------------------------------------------------

            local centerPosition =
                targetHRP.Position
                - targetHRP.CFrame.LookVector
                * (distance + centerDistance)

            ------------------------------------------------------------
            -- JALAN KE TENGAH
            ------------------------------------------------------------

            local reachedCenter =
                moveAndWait(
                    centerPosition
                )

            if not reachedCenter then
                return false
            end

            task.wait(0.1)

            return true

        end

        ----------------------------------------------------------------
        -- PERFORM ROLL
        ----------------------------------------------------------------

        local function performRoll()

            if not rolling then
                return
            end

            local myIndex =
                getBotIndex()

            if not myIndex then

                stopRolling()

                return

            end

            ------------------------------------------------------------
            -- BOT TARGET
            ------------------------------------------------------------

            local player =
                targetPlayer

            if not player then
                return
            end

            local character =
                player.Character

            if not character then
                return
            end

            local targetHRP =
                character:FindFirstChild(
                    "HumanoidRootPart"
                )

            if not targetHRP then
                return
            end

            local distance =
                getFollowDistance(
                    player
                )

            ------------------------------------------------------------
            -- WAIT TURN
            --
            -- BOT 1 = langsung
            -- BOT 2 = setelah BOT 1
            -- BOT 3 = setelah BOT 2
            -- dst.
            --
            ------------------------------------------------------------

            task.wait(
                (myIndex - 1)
                * turnDelay
            )

            if not rolling then
                return
            end

            ------------------------------------------------------------
            -- AMBIL TARGET TERBARU
            ------------------------------------------------------------

            character =
                player.Character

            if not character then
                return
            end

            targetHRP =
                character:FindFirstChild(
                    "HumanoidRootPart"
                )

            if not targetHRP then
                return
            end

            distance =
                getFollowDistance(
                    player
                )

            ------------------------------------------------------------
            -- BOT 1 / BOT 2
            --
            -- Masuk ke tengah terlebih dahulu.
            ------------------------------------------------------------

            if myIndex == 1
                or myIndex == 2 then

                local reachedCenter =
                    moveThroughCenter(
                        targetHRP,
                        distance
                    )

                if not reachedCenter then
                    return
                end

            end

            ------------------------------------------------------------
            -- DESTINATION
            ------------------------------------------------------------

            local destination =
                getRollingDestination(
                    myIndex,
                    targetHRP,
                    distance
                )

            if not destination then
                return
            end

            ------------------------------------------------------------
            -- JALAN KE DESTINATION
            ------------------------------------------------------------

            moveAndWait(
                destination
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
            rolling = true
            targetPlayer = player

            ------------------------------------------------------------
            -- CHAT
            ------------------------------------------------------------

            sendChat("Yes, Sir!")

            ------------------------------------------------------------
            -- START ROLL
            ------------------------------------------------------------

            task.spawn(function()

                performRoll()

            end)

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

                    startRolling(
                        target
                    )

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

                    local oldTarget =
                        targetPlayer

                    stopRolling()

                    task.wait(0.5)

                    startRolling(
                        oldTarget
                    )

                end

            end
        )

    end
}