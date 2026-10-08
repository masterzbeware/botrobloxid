return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players =
            game:GetService("Players")

        local RunService =
            game:GetService("RunService")

        local TextChatService =
            game:GetService("TextChatService")

        local ReplicatedStorage =
            game:GetService("ReplicatedStorage")

        local LocalPlayer =
            Players.LocalPlayer


        ----------------------------------------------------------------
        -- VALIDATE LOCAL PLAYER
        ----------------------------------------------------------------

        if not LocalPlayer then
            warn("[RoofLeft] LocalPlayer tidak ditemukan.")
            return
        end


        ----------------------------------------------------------------
        -- GLOBAL SYSTEM
        ----------------------------------------------------------------

        _G.BotVars =
            _G.BotVars or {}

        _G.BotVars.ModeControllers =
            _G.BotVars.ModeControllers or {}


        ----------------------------------------------------------------
        -- PLACE
        ----------------------------------------------------------------

        local TANPANAMA_PLACE_ID =
            119031818630096


        if game.PlaceId ~= TANPANAMA_PLACE_ID then

            warn(
                "[RoofLeft] Command hanya aktif di TANPANAMA.",
                "PlaceId:",
                game.PlaceId
            )

            return
        end


        ----------------------------------------------------------------
        -- LOAD ADMIN
        ----------------------------------------------------------------

        local Admin

        local successAdmin, resultAdmin =
            pcall(function()

                return loadstring(
                    game:HttpGet(
                        "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
                    )
                )()

            end)


        if not successAdmin then

            warn(
                "[RoofLeft] Gagal load Admin.lua:",
                resultAdmin
            )

            return
        end


        Admin = resultAdmin


        if not Admin then

            warn(
                "[RoofLeft] Admin.lua tidak ditemukan."
            )

            return
        end


        ----------------------------------------------------------------
        -- LOAD DISTANCE
        ----------------------------------------------------------------

        local Distance

        local successDistance, resultDistance =
            pcall(function()

                return loadstring(
                    game:HttpGet(
                        "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
                    )
                )()

            end)


        if not successDistance then

            warn(
                "[RoofLeft] Gagal load Distance.lua:",
                resultDistance
            )

            return
        end


        Distance = resultDistance


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
        -- ROOF LEFT CHECKPOINTS
        ----------------------------------------------------------------
        --
        -- Urutan:
        --
        -- 1. Roof Kiri Step 1
        -- 2. Roof Kiri Step 2
        -- 3. Roof Kiri Step 1 kanan
        -- 4. Roof Kiri Step 2 kanan
        -- 5. Roof Kiri Step 3 kanan
        -- 6. Roof Kiri Step 4 kanan
        -- 7. Roof Kiri Middle
        --
        ----------------------------------------------------------------

        local checkpoints = {

            {
                Name = "Roof Kiri Step 1",

                Position = Vector3.new(
                    2759.09,
                    5.04,
                    6.04
                )
            },

            {
                Name = "Roof Kiri Step 2",

                Position = Vector3.new(
                    2758.87,
                    5.04,
                    16.71
                )
            },

            {
                Name = "Roof Kiri Step 1 kanan",

                Position = Vector3.new(
                    2737.54,
                    5.04,
                    16.33
                )
            },

            {
                Name = "Roof Kiri Step 2 kanan",

                Position = Vector3.new(
                    2725.21,
                    16.51,
                    16.25
                )
            },

            {
                Name = "Roof Kiri Step 3 kanan",

                Position = Vector3.new(
                    2707.95,
                    28.83,
                    16.14
                )
            },

            {
                Name = "Roof Kiri Step 4 kanan",

                Position = Vector3.new(
                    2707.56,
                    28.75,
                    2.06
                )
            },

            {
                Name = "Roof Kiri Middle",

                Position = Vector3.new(
                    2760.92,
                    28.78,
                    -1.82
                )
            },

        }


        ----------------------------------------------------------------
        -- CONFIG
        ----------------------------------------------------------------

        -- Jarak dasar antar bot.
        -- Follow.lua juga menggunakan 2 sebagai default.
        local DEFAULT_DISTANCE = 2

        -- Jarak toleransi dianggap sudah sampai.
        local ARRIVAL_DISTANCE = 1.5

        -- Jarak agar follower tidak terlalu menempel.
        local FOLLOW_REACHED_DISTANCE = 1.5

        -- Delay kecil setelah semua bot membentuk formasi
        -- sebelum lanjut ke checkpoint berikutnya.
        local FORMATION_DELAY = 0.25


        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local humanoid = nil
        local myHRP = nil

        local active = false

        local currentCheckpoint = 1

        local movementConnection = nil


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
        -- GET BOT INDEX
        ----------------------------------------------------------------

        local function getBotIndex()

            return table.find(
                botOrder,
                tostring(
                    LocalPlayer.UserId
                )
            )

        end


        ----------------------------------------------------------------
        -- GET BOT PLAYER
        ----------------------------------------------------------------

        local function getBotPlayer(index)

            local userId =
                tonumber(
                    botOrder[index]
                )

            if not userId then
                return nil
            end

            return Players:GetPlayerByUserId(
                userId
            )

        end


        ----------------------------------------------------------------
        -- GET FORMATION DISTANCE
        ----------------------------------------------------------------
        --
        -- Prinsipnya sama dengan Follow.lua.
        --
        -- Bot 1:
        --     target utama
        --
        -- Bot 2:
        --     mengikuti Bot 1
        --
        -- Bot 3:
        --     mengikuti Bot 2
        --
        -- dst.
        --
        ----------------------------------------------------------------

        local function getDistanceBetweenBots(
            botIndexA,
            botIndexB
        )

            local userIdA =
                botOrder[botIndexA]

            local userIdB =
                botOrder[botIndexB]


            if Distance then

                local specialDistance =
                    Distance:GetDistance(
                        userIdA,
                        userIdB
                    )


                if specialDistance then
                    return specialDistance
                end

            end


            return DEFAULT_DISTANCE

        end


        ----------------------------------------------------------------
        -- GET TARGET PLAYER FOR BOT
        ----------------------------------------------------------------
        --
        -- Bot 1:
        --     tidak mengikuti player.
        --     Bot 1 menuju checkpoint.
        --
        -- Bot 2:
        --     mengikuti Bot 1.
        --
        -- Bot 3:
        --     mengikuti Bot 2.
        --
        -- dst.
        ----------------------------------------------------------------

        local function getFollowPlayer()

            local myIndex =
                getBotIndex()


            if not myIndex then
                return nil
            end


            if myIndex == 1 then
                return nil
            end


            return getBotPlayer(
                myIndex - 1
            )

        end


        ----------------------------------------------------------------
        -- SEND CHAT
        ----------------------------------------------------------------

        local function sendChat(message)

            local success = false


            ------------------------------------------------------------
            -- TEXT CHAT
            ------------------------------------------------------------

            if TextChatService
                and TextChatService.TextChannels then

                local channel =
                    TextChatService.TextChannels:
                    FindFirstChild(
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
            -- LEGACY CHAT
            ------------------------------------------------------------

            if not success then

                pcall(function()

                    local chatEvents =
                        ReplicatedStorage:
                        FindFirstChild(
                            "DefaultChatSystemChatEvents"
                        )


                    if chatEvents then

                        local sayMessageRequest =
                            chatEvents:
                            FindFirstChild(
                                "SayMessageRequest"
                            )


                        if sayMessageRequest then

                            sayMessageRequest:
                            FireServer(
                                message,
                                "All"
                            )

                        end

                    end

                end)

            end

        end


        ----------------------------------------------------------------
        -- GET CURRENT CHECKPOINT
        ----------------------------------------------------------------

        local function getCurrentCheckpoint()

            return checkpoints[
                currentCheckpoint
            ]

        end


        ----------------------------------------------------------------
        -- STOP ROOF LEFT
        ----------------------------------------------------------------

        local function stopRoofLeft()

            active = false


            if movementConnection then

                movementConnection:Disconnect()

                movementConnection = nil

            end


            if humanoid then

                humanoid.AutoRotate = true

            end


            print(
                "[RoofLeft] Mode dihentikan."
            )

        end


        ----------------------------------------------------------------
        -- REGISTER MODE
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.roofleft =
            stopRoofLeft


        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "roofleft"
                    and type(stopFunction) == "function" then

                    pcall(
                        stopFunction
                    )

                end

            end

        end


        ----------------------------------------------------------------
        -- CHECK BOT ARRIVAL
        ----------------------------------------------------------------

        local function isBotAtPosition(
            player,
            position,
            distance
        )

            if not player then
                return false
            end


            local character =
                player.Character


            if not character then
                return false
            end


            local hrp =
                character:FindFirstChild(
                    "HumanoidRootPart"
                )


            if not hrp then
                return false
            end


            return (
                hrp.Position
                -
                position
            ).Magnitude
            <= distance

        end


        ----------------------------------------------------------------
        -- CHECK ALL BOTS AT CHECKPOINT
        ----------------------------------------------------------------

        local function areAllBotsAtCheckpoint(
            position
        )

            for index = 1, #botOrder do

                local bot =
                    getBotPlayer(index)


                if not bot then

                    return false

                end


                if not isBotAtPosition(
                    bot,
                    position,
                    ARRIVAL_DISTANCE
                ) then

                    return false

                end

            end


            return true

        end


        ----------------------------------------------------------------
        -- MOVE BOT 1
        ----------------------------------------------------------------
        --
        -- Bot 1 adalah leader.
        --
        -- Dia langsung menuju checkpoint.
        ----------------------------------------------------------------

        local function moveLeader()

            local checkpoint =
                getCurrentCheckpoint()


            if not checkpoint then
                return
            end


            local targetPosition =
                checkpoint.Position


            local distance =
                (
                    myHRP.Position
                    -
                    targetPosition
                ).Magnitude


            if distance > ARRIVAL_DISTANCE then

                humanoid.AutoRotate = true

                humanoid:MoveTo(
                    targetPosition
                )

            else

                humanoid:MoveTo(
                    myHRP.Position
                )

                humanoid.AutoRotate = false

            end

        end


        ----------------------------------------------------------------
        -- MOVE FOLLOWER
        ----------------------------------------------------------------
        --
        -- Ini dibuat mengikuti prinsip Follow.lua.
        --
        -- Follower tidak langsung teleport ke checkpoint.
        --
        -- Dia mengikuti HumanoidRootPart bot sebelumnya.
        ----------------------------------------------------------------

        local function moveFollower()

            local myIndex =
                getBotIndex()


            if not myIndex
                or myIndex <= 1 then

                return

            end


            local previousBot =
                getFollowPlayer()


            if not previousBot then
                return
            end


            local previousCharacter =
                previousBot.Character


            if not previousCharacter then
                return
            end


            local previousHRP =
                previousCharacter:
                FindFirstChild(
                    "HumanoidRootPart"
                )


            if not previousHRP then
                return
            end


            ------------------------------------------------------------
            -- DISTANCE
            ------------------------------------------------------------

            local distance =
                getDistanceBetweenBots(
                    myIndex,
                    myIndex - 1
                )


            ------------------------------------------------------------
            -- TARGET POSITION
            ------------------------------------------------------------
            --
            -- Sama seperti Follow.lua:
            --
            -- previousHRP.Position
            -- -
            -- previousHRP.CFrame.LookVector * distance
            --
            ------------------------------------------------------------

            local targetPosition =
                previousHRP.Position
                -
                (
                    previousHRP.CFrame.LookVector
                    *
                    distance
                )


            ------------------------------------------------------------
            -- MOVE
            ------------------------------------------------------------

            local distanceToTarget =
                (
                    myHRP.Position
                    -
                    targetPosition
                ).Magnitude


            if distanceToTarget
                > FOLLOW_REACHED_DISTANCE then

                humanoid.AutoRotate = true

                humanoid:MoveTo(
                    targetPosition
                )

            else

                humanoid:MoveTo(
                    myHRP.Position
                )

                humanoid.AutoRotate = false


                --------------------------------------------------------
                -- ROTASI SAMA DENGAN BOT SEBELUMNYA
                --------------------------------------------------------

                local previousRotation =
                    previousHRP.CFrame
                    -
                    previousHRP.Position


                myHRP.CFrame =
                    CFrame.new(
                        myHRP.Position
                    )
                    *
                    previousRotation

            end

        end


        ----------------------------------------------------------------
        -- START ROOF LEFT
        ----------------------------------------------------------------

        local function startRoofLeft()

            ------------------------------------------------------------
            -- STOP MODE LAIN
            ------------------------------------------------------------

            stopOtherModes()


            ------------------------------------------------------------
            -- ACTIVE MODE
            ------------------------------------------------------------

            _G.BotVars.ActiveMode =
                "roofleft"


            ------------------------------------------------------------
            -- RESET
            ------------------------------------------------------------

            if movementConnection then

                movementConnection:Disconnect()

                movementConnection = nil

            end


            active = true

            currentCheckpoint = 1


            ------------------------------------------------------------
            -- BOT INDEX
            ------------------------------------------------------------

            local myIndex =
                getBotIndex()


            if not myIndex then

                warn(
                    "[RoofLeft] Player ini bukan Bot 1-10."
                )

                stopRoofLeft()

                return

            end


            ------------------------------------------------------------
            -- CHAT
            ------------------------------------------------------------

            sendChat(
                "Yes, Sir!"
            )


            print(
                "[RoofLeft] Dimulai."
            )

            print(
                "[RoofLeft] Bot:",
                myIndex
            )

            print(
                "[RoofLeft] Checkpoint:",
                getCurrentCheckpoint().Name
            )


            ------------------------------------------------------------
            -- MOVEMENT LOOP
            ------------------------------------------------------------

            movementConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- ACTIVE MODE CHECK
                        ------------------------------------------------

                        if _G.BotVars.ActiveMode
                            ~= "roofleft" then

                            stopRoofLeft()

                            return

                        end


                        ------------------------------------------------
                        -- ACTIVE CHECK
                        ------------------------------------------------

                        if not active then
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
                        -- CURRENT CHECKPOINT
                        ------------------------------------------------

                        local checkpoint =
                            getCurrentCheckpoint()


                        if not checkpoint then

                            print(
                                "[RoofLeft] Semua checkpoint selesai."
                            )

                            stopRoofLeft()

                            return

                        end


                        ------------------------------------------------
                        -- BOT 1 = LEADER
                        ------------------------------------------------

                        if myIndex == 1 then

                            moveLeader()

                        else

                            ------------------------------------------------
                            -- BOT 2-10 = FOLLOWER
                            ------------------------------------------------

                            moveFollower()

                        end

                    end
                )


            ----------------------------------------------------------------
            -- CHECKPOINT MANAGER
            ----------------------------------------------------------------
            --
            -- Setiap bot sendiri-sendiri mengetahui kapan dia sudah
            -- sampai checkpoint.
            --
            -- Tetapi checkpoint TIDAK boleh maju hanya karena satu bot
            -- sudah sampai.
            --
            -- Semua Bot 1-10 harus sudah berada di checkpoint.
            ----------------------------------------------------------------

            task.spawn(
                function()

                    while active do

                        ------------------------------------------------
                        -- ACTIVE MODE
                        ------------------------------------------------

                        if _G.BotVars.ActiveMode
                            ~= "roofleft" then

                            return

                        end


                        ------------------------------------------------
                        -- CURRENT CHECKPOINT
                        ------------------------------------------------

                        local checkpoint =
                            getCurrentCheckpoint()


                        if not checkpoint then

                            stopRoofLeft()

                            return

                        end


                        ------------------------------------------------
                        -- WAIT ALL BOTS
                        ------------------------------------------------

                        if areAllBotsAtCheckpoint(
                            checkpoint.Position
                        ) then

                            print(
                                "[RoofLeft] Semua bot sampai:",
                                checkpoint.Name
                            )


                            ------------------------------------------------
                            -- FORMATION DELAY
                            ------------------------------------------------

                            task.wait(
                                FORMATION_DELAY
                            )


                            ------------------------------------------------
                            -- DOUBLE CHECK
                            ------------------------------------------------

                            if not active then
                                return
                            end


                            if _G.BotVars.ActiveMode
                                ~= "roofleft" then

                                return

                            end


                            ------------------------------------------------
                            -- NEXT CHECKPOINT
                            ------------------------------------------------

                            currentCheckpoint =
                                currentCheckpoint + 1


                            local nextCheckpoint =
                                getCurrentCheckpoint()


                            if nextCheckpoint then

                                print(
                                    "[RoofLeft] Menuju:",
                                    nextCheckpoint.Name
                                )

                            else

                                print(
                                    "[RoofLeft] Roof Kiri selesai."
                                )

                                stopRoofLeft()

                                return

                            end

                        end


                        task.wait(0.1)

                    end

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

            if not sender then
                return
            end


            ------------------------------------------------------------
            -- ADMIN CHECK
            ------------------------------------------------------------

            local isAdmin = false


            pcall(function()

                isAdmin =
                    Admin:IsAdmin(
                        sender
                    )

            end)


            if not isAdmin then
                return
            end


            ------------------------------------------------------------
            -- CLEAN MESSAGE
            ------------------------------------------------------------

            local lower =
                tostring(message)
                :lower()
                :gsub(
                    "^%s+",
                    ""
                )
                :gsub(
                    "%s+$",
                    ""
                )


            ------------------------------------------------------------
            -- !ROOFLEFT
            ------------------------------------------------------------

            if lower == "!roofleft" then

                startRoofLeft()

                return

            end


            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if lower == "!stop" then

                _G.BotVars.ActiveMode =
                    nil

                _G.BotVars.CommandTarget =
                    nil


                for _, stopFunction in pairs(
                    _G.BotVars.ModeControllers
                ) do

                    if type(stopFunction)
                        == "function" then

                        pcall(
                            stopFunction
                        )

                    end

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
                TextChatService.TextChannels:
                FindFirstChild(
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


                if _G.BotVars.ActiveMode
                    == "roofleft"
                    and active then

                    startRoofLeft()

                end

            end
        )


        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print("----------------------------------------")
        print("[RoofLeft] Loaded successfully.")
        print("[RoofLeft] Place: TANPANAMA")
        print("[RoofLeft] PlaceId:", TANPANAMA_PLACE_ID)
        print("[RoofLeft] Command: !roofleft")
        print("[RoofLeft] Checkpoints:", #checkpoints)
        print("[RoofLeft] Bots:", #botOrder)
        print("----------------------------------------")

    end
}