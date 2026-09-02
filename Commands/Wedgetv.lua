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

        -- JANGAN UBAH URUTAN INI
        --
        -- Bot 1 = 11611503633
        -- Bot 2 = 11611534165
        -- Bot 3 = 11611567975
        -- Bot 4 = 11611562042
        -- Bot 5 = 11611591921
        -- Bot 6 = 11122806815
        -- Bot 7 = 11122806817
        -- Bot 8 = 11122687468
        -- Bot 9 = 11122854402
        --
        -- Bot 9 tidak digunakan dalam formasi Wedgetv.

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

        -- Jarak dasar formasi dari player
        local baseBackDistance = 5

        -- Jarak antar baris
        local rowSpacing = 3

        -- Jarak kiri / kanan
        local sideSpacing = 3

        -- Jarak minimum sebelum bot dianggap sampai
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
        -- GET WEDGE POSITION
        ----------------------------------------------------------------

        local function getWedgePosition(
            myIndex,
            targetHRP,
            distance
        )

            ------------------------------------------------------------
            -- BOT 1
            --
            -- Bot 1                    Bot 8
            ------------------------------------------------------------

            if myIndex == 1 then

                return
                    targetHRP.Position

                    -
                    (
                        targetHRP.CFrame.LookVector
                        *
                        (
                            baseBackDistance
                            + distance
                        )
                    )

                    -
                    (
                        targetHRP.CFrame.RightVector
                        *
                        (
                            sideSpacing * 3
                        )
                    )

            end

            ------------------------------------------------------------
            -- BOT 8
            --
            -- Bot 1                    Bot 8
            ------------------------------------------------------------

            if myIndex == 8 then

                return
                    targetHRP.Position

                    -
                    (
                        targetHRP.CFrame.LookVector
                        *
                        (
                            baseBackDistance
                            + distance
                        )
                    )

                    +
                    (
                        targetHRP.CFrame.RightVector
                        *
                        (
                            sideSpacing * 3
                        )
                    )

            end

            ------------------------------------------------------------
            -- BOT 7
            --
            --     Bot 7            Bot 6
            ------------------------------------------------------------

            if myIndex == 7 then

                return
                    targetHRP.Position

                    -
                    (
                        targetHRP.CFrame.LookVector
                        *
                        (
                            baseBackDistance
                            + rowSpacing
                            + distance
                        )
                    )

                    -
                    (
                        targetHRP.CFrame.RightVector
                        *
                        (
                            sideSpacing * 2
                        )
                    )

            end

            ------------------------------------------------------------
            -- BOT 6
            --
            --     Bot 7            Bot 6
            ------------------------------------------------------------

            if myIndex == 6 then

                return
                    targetHRP.Position

                    -
                    (
                        targetHRP.CFrame.LookVector
                        *
                        (
                            baseBackDistance
                            + rowSpacing
                            + distance
                        )
                    )

                    +
                    (
                        targetHRP.CFrame.RightVector
                        *
                        (
                            sideSpacing * 2
                        )
                    )

            end

            ------------------------------------------------------------
            -- BOT 5
            --
            --         Bot 5      Bot 4
            ------------------------------------------------------------

            if myIndex == 5 then

                return
                    targetHRP.Position

                    -
                    (
                        targetHRP.CFrame.LookVector
                        *
                        (
                            baseBackDistance
                            + (rowSpacing * 2)
                            + distance
                        )
                    )

                    -
                    (
                        targetHRP.CFrame.RightVector
                        *
                        sideSpacing
                    )

            end

            ------------------------------------------------------------
            -- BOT 4
            --
            --         Bot 5      Bot 4
            ------------------------------------------------------------

            if myIndex == 4 then

                return
                    targetHRP.Position

                    -
                    (
                        targetHRP.CFrame.LookVector
                        *
                        (
                            baseBackDistance
                            + (rowSpacing * 2)
                            + distance
                        )
                    )

                    +
                    (
                        targetHRP.CFrame.RightVector
                        *
                        sideSpacing
                    )

            end

            ------------------------------------------------------------
            -- BOT 3
            --
            --             Bot 3  Bot 2
            ------------------------------------------------------------

            if myIndex == 3 then

                return
                    targetHRP.Position

                    -
                    (
                        targetHRP.CFrame.LookVector
                        *
                        (
                            baseBackDistance
                            + (rowSpacing * 3)
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

            end

            ------------------------------------------------------------
            -- BOT 2
            --
            --             Bot 3  Bot 2
            ------------------------------------------------------------

            if myIndex == 2 then

                return
                    targetHRP.Position

                    -
                    (
                        targetHRP.CFrame.LookVector
                        *
                        (
                            baseBackDistance
                            + (rowSpacing * 3)
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

            ------------------------------------------------------------
            -- BOT 9
            ------------------------------------------------------------

            -- Bot 9 tidak digunakan.
            -- Jika LocalPlayer adalah Bot 9,
            -- bot akan diam dalam mode Wedgetv.

            return nil

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
            -- ACTIVE MODE
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
            -- CARI INDEX BOT
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
            -- BOT 9 TIDAK IKUT FORMASI
            ------------------------------------------------------------

            if myIndex == 9 then

                return
            end

            ------------------------------------------------------------
            -- HEARTBEAT
            ------------------------------------------------------------

            wedgeConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- CEK MODE
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
                        -- GET POSITION
                        ------------------------------------------------

                        local targetPosition =
                            getWedgePosition(
                                myIndex,
                                targetHRP,
                                distance
                            )

                        if not targetPosition then
                            return
                        end

                        ------------------------------------------------
                        -- JARAK KE POSISI
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