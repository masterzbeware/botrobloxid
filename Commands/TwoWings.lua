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
        -- TWOWINGS CONFIG
        ----------------------------------------------------------------

        -- Jarak kiri / kanan antar bot
        local sideSpacing = 2.5

        -- Jarak minimum sebelum bot berhenti
        local stopThreshold = 1.5

        ----------------------------------------------------------------
        -- BOT ORDER
        ----------------------------------------------------------------
        -- Hanya 5 bot
        --
        -- BOT 1 = TENGAH BELAKANG
        -- BOT 2 = KIRI
        -- BOT 3 = KANAN
        -- BOT 4 = KIRI
        -- BOT 5 = KANAN
        ----------------------------------------------------------------

        local botOrder = {

            "11611503633", -- Bot 1
            "11611534165", -- Bot 2
            "11611567975", -- Bot 3
            "11611562042", -- Bot 4
            "11611591921", -- Bot 5

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
        -- STOP TWOWINGS
        ----------------------------------------------------------------

        local function stopTwowings()

            following = false
            targetPlayer = nil

            if followConnection then

                followConnection:Disconnect()
                followConnection = nil

            end

            if humanoid then

                humanoid.AutoRotate = true

            end

        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.twowings =
            stopTwowings

        ----------------------------------------------------------------
        -- STOP SEMUA MODE LAIN
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
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
        -- START TWOWINGS
        ----------------------------------------------------------------

        local function startTwowings(player)

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

            _G.BotVars.ActiveMode = "twowings"

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
            -- CARI INDEX BOT
            ------------------------------------------------------------

            local myIndex =
                table.find(
                    botOrder,
                    tostring(LocalPlayer.UserId)
                )

            if not myIndex then

                stopTwowings()

                return

            end

            ----------------------------------------------------------------
            -- TWOWINGS LOOP
            ----------------------------------------------------------------

            followConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- JIKA MODE BERGANTI
                        ------------------------------------------------

                        if _G.BotVars.ActiveMode ~= "twowings" then

                            stopTwowings()

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
                        -- SAMA SEPERTI FOLLOW.LUA
                        ------------------------------------------------

                        local distance =
                            defaultBotFollowDistance

                        if Admin:IsAdmin(targetPlayer) then

                            distance =
                                adminFollowDistance

                        end

                        ------------------------------------------------
                        -- SPECIAL DISTANCE
                        -- SAMA SEPERTI FOLLOW.LUA
                        ------------------------------------------------

                        local specialDistance =
                            Distance:GetDistance(
                                tostring(LocalPlayer.UserId),
                                tostring(targetPlayer.UserId)
                            )

                        if specialDistance then

                            distance =
                                specialDistance

                        end

                        ------------------------------------------------
                        -- FORMASI TWOWINGS
                        ------------------------------------------------
                        --
                        -- BOT 1
                        -- Tengah belakang
                        --
                        -- BOT 2 / BOT 3
                        -- Kiri / kanan
                        --
                        -- BOT 4 / BOT 5
                        -- Kiri / kanan
                        ------------------------------------------------

                        local backDistance
                        local sideOffset

                        ------------------------------------------------
                        -- BOT 1
                        -- TENGAH BELAKANG
                        ------------------------------------------------

                        if myIndex == 1 then

                            backDistance =
                                distance

                            sideOffset =
                                Vector3.zero

                        ------------------------------------------------
                        -- BOT 2 & BOT 3
                        -- BARIS KEDUA
                        ------------------------------------------------

                        elseif myIndex == 2 then

                            backDistance =
                                distance * 2

                            sideOffset =
                                targetHRP.CFrame.RightVector
                                * -sideSpacing

                        elseif myIndex == 3 then

                            backDistance =
                                distance * 2

                            sideOffset =
                                targetHRP.CFrame.RightVector
                                * sideSpacing

                        ------------------------------------------------
                        -- BOT 4 & BOT 5
                        -- BARIS KETIGA
                        ------------------------------------------------

                        elseif myIndex == 4 then

                            backDistance =
                                distance * 3

                            sideOffset =
                                targetHRP.CFrame.RightVector
                                * -sideSpacing

                        elseif myIndex == 5 then

                            backDistance =
                                distance * 3

                            sideOffset =
                                targetHRP.CFrame.RightVector
                                * sideSpacing

                        else

                            return

                        end

                        ------------------------------------------------
                        -- POSISI BELAKANG
                        ------------------------------------------------

                        local backOffset =
                            targetHRP.CFrame.LookVector
                            * -backDistance

                        ------------------------------------------------
                        -- POSISI AKHIR
                        ------------------------------------------------

                        local targetPosition =
                            targetHRP.Position
                            + backOffset
                            + sideOffset

                        ------------------------------------------------
                        -- JARAK BOT KE POSISI
                        ------------------------------------------------

                        local distanceToTarget =
                            (
                                myHRP.Position
                                - targetPosition
                            ).Magnitude

                        ------------------------------------------------
                        -- JALAN
                        ------------------------------------------------

                        if distanceToTarget > stopThreshold then

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
                        -- ROTASI SAMA SEPERTI FOLLOW.LUA
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

            if not Admin:IsAdmin(sender) then
                return
            end

            local lower =
                message:lower()

            ------------------------------------------------------------
            -- !TWOWINGS
            ------------------------------------------------------------

            if lower == "!twowings" then

                startTwowings(sender)

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

                    startTwowings(target)

                end

                return

            end

            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if lower == "!stop"
                or lower == "!untwowings" then

                _G.BotVars.ActiveMode = nil

                stopTwowings()

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
                -- JIKA TWOWINGS MASIH AKTIF
                --------------------------------------------------------

                if _G.BotVars.ActiveMode == "twowings"
                    and targetPlayer then

                    startTwowings(
                        targetPlayer
                    )

                end

            end
        )

    end
}