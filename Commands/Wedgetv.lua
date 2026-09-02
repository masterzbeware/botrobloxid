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

        local wedgeActive = false
        local wedgeConnection = nil
        local targetPlayer = nil

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
        -- WEDGE SETTINGS
        ----------------------------------------------------------------

        -- Jarak baris pertama dari player
        local backDistance = 6

        -- Jarak kiri / kanan baris pertama
        local sideSpacing = 3

        -- Jarak baris kedua dari player
        local rowSpacing = 3

        -- Jarak minimum sebelum bot dianggap sudah sampai
        local stopThreshold = 1.5

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
                    TextChatService.TextChannels
                        :FindFirstChild("RBXGeneral")

                if channel then

                    pcall(function()
                        channel:SendAsync(message)
                    end)

                    success = true
                end
            end

            ------------------------------------------------------------
            -- FALLBACK CHAT
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
        -- STOP WEDGETV
        ----------------------------------------------------------------

        local function stopWedge()

            wedgeActive = false
            targetPlayer = nil

            if wedgeConnection then

                wedgeConnection:Disconnect()
                wedgeConnection = nil

            end

            if humanoid then
                humanoid.AutoRotate = true
            end

        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        vars.ModeControllers.wedgetv = stopWedge

        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                vars.ModeControllers
            ) do

                if name ~= "wedgetv"
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
        -- GET DISTANCE
        ----------------------------------------------------------------

        local function getBotDistance(player)

            local distance = 2

            if Admin:IsAdmin(player) then
                distance = 3
            end

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
        -- START WEDGETV
        ----------------------------------------------------------------

        local function startWedge(player)

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

            vars.ActiveMode = "wedgetv"

            ------------------------------------------------------------
            -- STOP CONNECTION LAMA
            ------------------------------------------------------------

            if wedgeConnection then

                wedgeConnection:Disconnect()
                wedgeConnection = nil

            end

            ------------------------------------------------------------
            -- TARGET
            ------------------------------------------------------------

            wedgeActive = true
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
                    tostring(
                        LocalPlayer.UserId
                    )
                )

            if not myIndex then

                stopWedge()

                return
            end

            ------------------------------------------------------------
            -- HANYA 4 BOT PERTAMA
            ------------------------------------------------------------

            if myIndex > 4 then

                stopWedge()

                return
            end

            ------------------------------------------------------------
            -- HEARTBEAT
            ------------------------------------------------------------

            wedgeConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- CEK ACTIVE MODE
                        ------------------------------------------------

                        if vars.ActiveMode ~= "wedgetv" then

                            stopWedge()

                            return
                        end

                        if not wedgeActive then
                            return
                        end

                        ------------------------------------------------
                        -- CEK CHARACTER
                        ------------------------------------------------

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
                            getBotDistance(
                                targetPlayer
                            )

                        ------------------------------------------------
                        -- FORMATION
                        ------------------------------------------------
                        --
                        -- BOT 1           BOT 2
                        --
                        --    BOT 3     BOT 4
                        --
                        --        PLAYER
                        --
                        ------------------------------------------------

                        local targetPosition

                        ------------------------------------------------
                        -- BOT 1
                        -- KIRI ATAS
                        ------------------------------------------------

                        if myIndex == 1 then

                            targetPosition =
                                targetHRP.Position

                                -
                                (
                                    targetHRP.CFrame.LookVector
                                    *
                                    (
                                        backDistance
                                        + distance
                                    )
                                )

                                -
                                (
                                    targetHRP.CFrame.RightVector
                                    *
                                    sideSpacing
                                )

                        ------------------------------------------------
                        -- BOT 2
                        -- KANAN ATAS
                        ------------------------------------------------

                        elseif myIndex == 2 then

                            targetPosition =
                                targetHRP.Position

                                -
                                (
                                    targetHRP.CFrame.LookVector
                                    *
                                    (
                                        backDistance
                                        + distance
                                    )
                                )

                                +
                                (
                                    targetHRP.CFrame.RightVector
                                    *
                                    sideSpacing
                                )

                        ------------------------------------------------
                        -- BOT 3
                        -- KIRI BAWAH
                        ------------------------------------------------

                        elseif myIndex == 3 then

                            targetPosition =
                                targetHRP.Position

                                -
                                (
                                    targetHRP.CFrame.LookVector
                                    *
                                    (
                                        rowSpacing
                                        + distance
                                    )
                                )

                                -
                                (
                                    targetHRP.CFrame.RightVector
                                    *
                                    (
                                        sideSpacing * 0.5
                                    )
                                )

                        ------------------------------------------------
                        -- BOT 4
                        -- KANAN BAWAH
                        ------------------------------------------------

                        elseif myIndex == 4 then

                            targetPosition =
                                targetHRP.Position

                                -
                                (
                                    targetHRP.CFrame.LookVector
                                    *
                                    (
                                        rowSpacing
                                        + distance
                                    )
                                )

                                +
                                (
                                    targetHRP.CFrame.RightVector
                                    *
                                    (
                                        sideSpacing * 0.5
                                    )
                                )

                        end

                        if not targetPosition then
                            return
                        end

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
                        -- MOVE
                        ------------------------------------------------

                        if distanceToTarget > stopThreshold then

                            humanoid.AutoRotate = true

                            humanoid:MoveTo(
                                targetPosition
                            )

                            return
                        end

                        ------------------------------------------------
                        -- SUDAH DI POSISI
                        ------------------------------------------------

                        humanoid.AutoRotate = false

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
            -- !WEDGETV
            ------------------------------------------------------------

            if lower == "!wedgetv" then

                startWedge(sender)

                return
            end

            ------------------------------------------------------------
            -- !WEDGETV PLAYER
            ------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!wedgetv%s+(.+)$"
                )

            if targetName then

                local target =
                    findPlayerByName(
                        targetName
                    )

                if target then

                    startWedge(target)

                end

                return
            end

            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if lower == "!stop" then

                vars.ActiveMode = nil

                stopWedge()

                return
            end

        end

        ----------------------------------------------------------------
        -- TEXT CHAT
        ----------------------------------------------------------------

        if TextChatService
            and TextChatService.TextChannels then

            local channel =
                TextChatService.TextChannels
                    :FindFirstChild(
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

                if vars.ActiveMode == "wedgetv"
                    and targetPlayer then

                    startWedge(
                        targetPlayer
                    )

                end

            end
        )

    end
}