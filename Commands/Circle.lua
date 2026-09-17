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

        local circling = false
        local targetPlayer = nil
        local circleConnection = nil

        ----------------------------------------------------------------
        -- FORMATION DISTANCE
        ----------------------------------------------------------------

        -- Jarak lingkaran B1-B11 dari Player/Admin.
        local adminCircleDistance = 6
        local defaultBotCircleDistance = 6

        ----------------------------------------------------------------
        -- BOT ORDER
        ----------------------------------------------------------------

local botOrder = {
    "11611503633", -- Bot 1
    "11611591921", -- Bot 2
    "11611597741", -- Bot 3
    "11122806815", -- Bot 4
    "11122806817", -- Bot 5
    "11122687468", -- Bot 6
    "11122854402", -- Bot 7
    "11002763516", -- Bot 8
    "11001647769", -- Bot 9
    "11001625681", -- Bot 10
    "11001608049", -- Bot 11
    "11001607521", -- Bot 12
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
        -- STOP CIRCLE
        ----------------------------------------------------------------

        local function stopCircle()

            circling = false
            targetPlayer = nil

            if circleConnection then

                circleConnection:Disconnect()
                circleConnection = nil

            end

            if humanoid then
                humanoid.AutoRotate = true
            end

        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.circle = stopCircle

        ----------------------------------------------------------------
        -- STOP SEMUA MODE LAIN
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "circle"
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
        -- START CIRCLE
        ----------------------------------------------------------------

        local function startCircle(player)

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

            _G.BotVars.ActiveMode = "circle"

            ------------------------------------------------------------
            -- STOP CONNECTION LAMA
            ------------------------------------------------------------

            if circleConnection then

                circleConnection:Disconnect()
                circleConnection = nil

            end

            circling = true
            targetPlayer = player
            _G.BotVars.CommandTarget = player

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

                stopCircle()

                return

            end

            ------------------------------------------------------------
            -- CIRCLE LOOP
            ------------------------------------------------------------

            circleConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- JIKA MODE SUDAH BERGANTI
                        ------------------------------------------------

                        if _G.BotVars.ActiveMode ~= "circle" then

                            stopCircle()

                            return

                        end

                        ------------------------------------------------
                        -- VALIDASI
                        ------------------------------------------------

                        if not circling then
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

                        local radius =
                            defaultBotCircleDistance

                        if Admin:IsAdmin(targetPlayer) then

                            radius =
                                adminCircleDistance

                        end

                        local specialDistance =
                            Distance:GetDistance(
                                tostring(LocalPlayer.UserId),
                                tostring(targetPlayer.UserId)
                            )

                        if specialDistance then

                            radius =
                                specialDistance

                        end

                        ------------------------------------------------
                        -- CIRCLE POSITION
                        --
                        -- Semua bot ditempatkan merata 360 derajat
                        -- mengelilingi target.
                        --
                        -- Bot 1 mulai dari arah depan target,
                        -- kemudian bot berikutnya bergerak searah
                        -- jarum jam berdasarkan index.
                        ------------------------------------------------

                        local totalBots = #botOrder

                        local angle =
                            ((myIndex - 1) / totalBots)
                            * math.pi * 2

                        local forward =
                            targetHRP.CFrame.LookVector

                        local right =
                            targetHRP.CFrame.RightVector

                        local offset =
                            (
                                forward * math.cos(angle)
                            )
                            +
                            (
                                right * math.sin(angle)
                            )

                        local targetPosition =
                            targetHRP.Position
                            +
                            (offset * radius)

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
                        -- BOT MENGHADAP KE TENGAH LINGKARAN
                        ------------------------------------------------

                        humanoid.AutoRotate = false

                        local lookPosition =
                            Vector3.new(
                                targetHRP.Position.X,
                                myHRP.Position.Y,
                                targetHRP.Position.Z
                            )

                        myHRP.CFrame =
                            CFrame.lookAt(
                                myHRP.Position,
                                lookPosition
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

            if not message or not sender then
                return
            end

            local isAdmin = false
            pcall(function()
                isAdmin = Admin:IsAdmin(sender)
            end)

            local lower =
                message:lower():gsub("^%s+", ""):gsub("%s+$", "")

            local commandTarget =
                _G.BotVars.CommandTarget

            ------------------------------------------------------------
            -- !STOP
            -- HANYA PLAYER/ADMIN YANG BOLEH STOP SEMUA MODE.
            ------------------------------------------------------------

            if lower == "!stop"
                or lower == "!uncircle" then

                if not isAdmin then
                    return
                end

                _G.BotVars.ActiveMode = nil
                _G.BotVars.CommandTarget = nil

                for _, stopFunction in pairs(_G.BotVars.ModeControllers) do
                    if type(stopFunction) == "function" then
                        pcall(stopFunction)
                    end
                end

                return
            end

            ------------------------------------------------------------
            -- !circle
            -- Admin boleh menjalankan kapan saja.
            -- Target aktif juga boleh mengganti formasi, tetapi hanya
            -- dengan command tanpa nama player.
            ------------------------------------------------------------

            if lower == "!circle" then

                if not isAdmin and sender ~= commandTarget then
                    return
                end

                _G.BotVars.CommandTarget = sender
                startCircle(sender)

                return
            end

            ------------------------------------------------------------
            -- !circle PLAYER
            -- HANYA ADMIN YANG boleh memilih target baru.
            ------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!circle%s+(.+)$"
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
                    _G.BotVars.CommandTarget = target
                    startCircle(target)
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

                    end)

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

                if _G.BotVars.ActiveMode == "circle"
                    and targetPlayer then

                    startCircle(
                        targetPlayer
                    )

                end

            end
        )

    end
}
