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

        local twoLining = false
        local targetPlayer = nil
        local twoLineConnection = nil

        ----------------------------------------------------------------
        -- FORMATION SETTINGS
        ----------------------------------------------------------------

        -- Jarak kiri/kanan dari tengah.
        local sideDistance = 3

        -- Jarak antar baris ke belakang.
        local rowDistance = 3

        -- Jarak dasar dari player.
        -- Sama konsepnya dengan Follow.lua.
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

                    pcall(stopFunction)

                end

            end

        end

        ----------------------------------------------------------------
        -- FIND PLAYER
        ----------------------------------------------------------------

        local function findPlayerByName(name)

            name = name:lower()

            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if player.Name:lower() == name
                    or player.DisplayName:lower() == name then

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
            --
            -- B1
            -- B3
            -- B5
            -- B7
            -- B9
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
            --
            -- B2
            -- B4
            -- B6
            -- B8
            -- B10
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

            _G.BotVars.ActiveMode = "twoline"

            ----------------------------------------------------------------
            -- STOP CONNECTION LAMA
            ----------------------------------------------------------------

            if twoLineConnection then

                twoLineConnection:Disconnect()
                twoLineConnection = nil

            end

            twoLining = true
            targetPlayer = player

            _G.BotVars.CommandTarget = player

            sendChat("Yes, Sir!")

            ----------------------------------------------------------------
            -- CARI INDEX BOT
            ----------------------------------------------------------------

            local myIndex =
                table.find(
                    botOrder,
                    tostring(LocalPlayer.UserId)
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
                        -- JIKA MODE SUDAH BERGANTI
                        ------------------------------------------------

                        if _G.BotVars.ActiveMode ~= "twoline" then

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

                        if Admin:IsAdmin(targetPlayer) then

                            distance =
                                adminTwoLineDistance

                        end

                        ------------------------------------------------
                        -- SPECIAL DISTANCE
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
                        -- FORMATION OFFSET
                        ------------------------------------------------

                        local offset =
                            getTwoLineOffset(
                                myIndex,
                                distance
                            )

                        ------------------------------------------------
                        -- CONVERT LOCAL OFFSET
                        -- KE WORLD POSITION
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

                        if distanceToTarget > 1.5 then

                            humanoid.AutoRotate = true

                            humanoid:MoveTo(
                                targetPosition
                            )

                            return

                        end

                        ------------------------------------------------
                        -- SUDAH SAMPAI
                        -- BOT MENGHADAP KE DEPAN
                        -- SESUAI ARAH PLAYER
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
            -- NORMALIZE MESSAGE
            ----------------------------------------------------------------

            local lower =
                message
                :lower()
                :gsub("^%s+", "")
                :gsub("%s+$", "")

            ----------------------------------------------------------------
            -- CURRENT TARGET
            ----------------------------------------------------------------

            local commandTarget =
                _G.BotVars.CommandTarget

            ----------------------------------------------------------------
            -- !STOP
            -- !UNTWOLINE
            ----------------------------------------------------------------

            if lower == "!stop"
                or lower == "!untwoline" then

                if not isAdmin then
                    return
                end

                _G.BotVars.ActiveMode = nil
                _G.BotVars.CommandTarget = nil

                for _, stopFunction in pairs(
                    _G.BotVars.ModeControllers
                ) do

                    if type(stopFunction) == "function" then

                        pcall(stopFunction)

                    end

                end

                return

            end

            ----------------------------------------------------------------
            -- !TWOLINE
            --
            -- Admin:
            -- dapat menjalankan ke dirinya sendiri.
            --
            -- Target aktif:
            -- dapat mengganti formasi menjadi TwoLine.
            ----------------------------------------------------------------

            if lower == "!twoline" then

                if not isAdmin
                    and sender ~= commandTarget then

                    return

                end

                _G.BotVars.CommandTarget =
                    sender

                startTwoLine(sender)

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
                    return
                end

                local target =
                    findPlayerByName(
                        targetName
                    )

                if target then

                    _G.BotVars.CommandTarget =
                        target

                    startTwoLine(target)

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

                if _G.BotVars.ActiveMode == "twoline"
                    and targetPlayer then

                    startTwoLine(
                        targetPlayer
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
