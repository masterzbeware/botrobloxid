

return {
    Execute = function()

        --------------------------------------------------
        -- SERVICES
        --------------------------------------------------

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer
        if not LocalPlayer then
            return
        end

        --------------------------------------------------
        -- GLOBAL VARIABLES
        --------------------------------------------------

        _G.BotVars = _G.BotVars or {}
        _G.BotVars.ModeControllers = _G.BotVars.ModeControllers or {}

        local vars = _G.BotVars

        --------------------------------------------------
        -- LOAD ADMIN
        --------------------------------------------------

        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        --------------------------------------------------
        -- LOAD DISTANCE
        --------------------------------------------------

        local Distance = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
        ))()

        --------------------------------------------------
        -- CHARACTER
        --------------------------------------------------

        local humanoid
        local myHRP

        --------------------------------------------------
        -- STATE
        --------------------------------------------------

        local wedgeActive = false
        local wedgeConnection = nil
        local targetPlayer = nil

        --------------------------------------------------
        -- BOT ORDER
        --------------------------------------------------

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

        --------------------------------------------------
        -- FORMATION SETTINGS
        --------------------------------------------------

        -- Jarak dasar dari PLAYER
        local baseBackDistance = 2

        -- Jarak antar baris
        local rowSpacing = 3

        -- Jarak kiri/kanan
        local sideSpacing = 3

        -- Jarak minimum sebelum berhenti MoveTo
        local stopThreshold = 1.5

        --------------------------------------------------
        -- UPDATE CHARACTER
        --------------------------------------------------

        local function updateCharacter()

            local character =
                LocalPlayer.Character
                or LocalPlayer.CharacterAdded:Wait()

            humanoid = character:WaitForChild("Humanoid")
            myHRP = character:WaitForChild("HumanoidRootPart")

            humanoid.AutoRotate = true
        end

        updateCharacter()

        --------------------------------------------------
        -- SEND CHAT
        --------------------------------------------------

        local function sendChat(message)

            if not message then
                return
            end

            local success = false

            --------------------------------------------------
            -- TEXT CHAT
            --------------------------------------------------

            if TextChatService
                and TextChatService.TextChannels then

                local channel =
                    TextChatService.TextChannels:FindFirstChild("RBXGeneral")

                if channel then

                    pcall(function()
                        channel:SendAsync(message)
                    end)

                    success = true
                end
            end

            --------------------------------------------------
            -- OLD CHAT FALLBACK
            --------------------------------------------------

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

        --------------------------------------------------
        -- STOP WEDGE
        --------------------------------------------------

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

        --------------------------------------------------
        -- REGISTER MODE CONTROLLER
        --------------------------------------------------

        vars.ModeControllers.wedgetv = stopWedge

        --------------------------------------------------
        -- STOP OTHER MODES
        --------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(vars.ModeControllers) do

                if name ~= "wedgetv"
                    and type(stopFunction) == "function" then

                    pcall(stopFunction)

                end

            end

        end

        --------------------------------------------------
        -- FIND PLAYER
        --------------------------------------------------

        local function findPlayerByName(name)

            name = name:lower()

            for _, player in ipairs(Players:GetPlayers()) do

                if player.Name:lower() == name
                    or player.DisplayName:lower() == name then

                    return player

                end

            end

            return nil
        end

        --------------------------------------------------
        -- GET BOT DISTANCE
        --------------------------------------------------

        local function getBotDistance(player)

            local distance = 1

            if Admin:IsAdmin(player) then
                distance = 1
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

        --------------------------------------------------
        -- GET WEDGE POSITION
        --------------------------------------------------
        --
        -- FORMASI:
        --
        -- BOT 8                 BOT 7
        --    BOT 6           BOT 5
        --       BOT 4     BOT 3
        --          BOT 2  BOT 1
        --              PLAYER
        --
        --------------------------------------------------

        local function getWedgePosition(
            myIndex,
            targetHRP,
            distance
        )

            --------------------------------------------------
            -- BOT 1
            -- PALING DEKAT - KANAN
            --------------------------------------------------

            if myIndex == 1 then

                return targetHRP.Position

                    - (
                        targetHRP.CFrame.LookVector
                        * (
                            baseBackDistance
                            + distance
                        )
                    )

                    + (
                        targetHRP.CFrame.RightVector
                        * (
                            sideSpacing * 0.5
                        )
                    )

            end

            --------------------------------------------------
            -- BOT 2
            -- PALING DEKAT - KIRI
            --------------------------------------------------

            if myIndex == 2 then

                return targetHRP.Position

                    - (
                        targetHRP.CFrame.LookVector
                        * (
                            baseBackDistance
                            + distance
                        )
                    )

                    - (
                        targetHRP.CFrame.RightVector
                        * (
                            sideSpacing * 0.5
                        )
                    )

            end

            --------------------------------------------------
            -- BOT 3
            -- BARIS 2 - KANAN
            --------------------------------------------------

            if myIndex == 3 then

                return targetHRP.Position

                    - (
                        targetHRP.CFrame.LookVector
                        * (
                            baseBackDistance
                            + rowSpacing
                            + distance
                        )
                    )

                    + (
                        targetHRP.CFrame.RightVector
                        * sideSpacing
                    )

            end

            --------------------------------------------------
            -- BOT 4
            -- BARIS 2 - KIRI
            --------------------------------------------------

            if myIndex == 4 then

                return targetHRP.Position

                    - (
                        targetHRP.CFrame.LookVector
                        * (
                            baseBackDistance
                            + rowSpacing
                            + distance
                        )
                    )

                    - (
                        targetHRP.CFrame.RightVector
                        * sideSpacing
                    )

            end

            --------------------------------------------------
            -- BOT 5
            -- BARIS 3 - KANAN
            --------------------------------------------------

            if myIndex == 5 then

                return targetHRP.Position

                    - (
                        targetHRP.CFrame.LookVector
                        * (
                            baseBackDistance
                            + (rowSpacing * 2)
                            + distance
                        )
                    )

                    + (
                        targetHRP.CFrame.RightVector
                        * (sideSpacing * 1.5)
                    )

            end

            --------------------------------------------------
            -- BOT 6
            -- BARIS 3 - KIRI
            --------------------------------------------------

            if myIndex == 6 then

                return targetHRP.Position

                    - (
                        targetHRP.CFrame.LookVector
                        * (
                            baseBackDistance
                            + (rowSpacing * 2)
                            + distance
                        )
                    )

                    - (
                        targetHRP.CFrame.RightVector
                        * (sideSpacing * 1.5)
                    )

            end

            --------------------------------------------------
            -- BOT 7
            -- BARIS 4 - KANAN
            --------------------------------------------------

            if myIndex == 7 then

                return targetHRP.Position

                    - (
                        targetHRP.CFrame.LookVector
                        * (
                            baseBackDistance
                            + (rowSpacing * 3)
                            + distance
                        )
                    )

                    + (
                        targetHRP.CFrame.RightVector
                        * (sideSpacing * 2)
                    )

            end

            --------------------------------------------------
            -- BOT 8
            -- BARIS 4 - KIRI
            --------------------------------------------------

            if myIndex == 8 then

                return targetHRP.Position

                    - (
                        targetHRP.CFrame.LookVector
                        * (
                            baseBackDistance
                            + (rowSpacing * 3)
                            + distance
                        )
                    )

                    - (
                        targetHRP.CFrame.RightVector
                        * (sideSpacing * 2)
                    )

            end

            --------------------------------------------------
            -- BOT 9 TIDAK DIPAKAI
            --------------------------------------------------

            return nil

        end

        --------------------------------------------------
        -- START WEDGE
        --------------------------------------------------

        local function startWedge(player)

            if not player then
                return
            end

            --------------------------------------------------
            -- STOP MODE LAIN
            --------------------------------------------------

            stopOtherModes()

            --------------------------------------------------
            -- SET ACTIVE MODE
            --------------------------------------------------

            vars.ActiveMode = "wedgetv"

            --------------------------------------------------
            -- DISCONNECT OLD LOOP
            --------------------------------------------------

            if wedgeConnection then

                wedgeConnection:Disconnect()
                wedgeConnection = nil

            end

            --------------------------------------------------
            -- START
            --------------------------------------------------

            wedgeActive = true
            targetPlayer = player

            sendChat("Yes, Sir!")

            --------------------------------------------------
            -- FIND BOT INDEX
            --------------------------------------------------

            local myIndex =
                table.find(
                    botOrder,
                    tostring(LocalPlayer.UserId)
                )

            if not myIndex then

                stopWedge()
                return

            end

            --------------------------------------------------
            -- BOT 9 NOT USED
            --------------------------------------------------

            if myIndex == 9 then
                return
            end

            --------------------------------------------------
            -- HEARTBEAT
            --------------------------------------------------

            wedgeConnection =
                RunService.Heartbeat:Connect(
                    function()

                        --------------------------------------------------
                        -- MODE CHANGED
                        --------------------------------------------------

                        if vars.ActiveMode ~= "wedgetv" then

                            stopWedge()
                            return

                        end

                        --------------------------------------------------
                        -- BASIC VALIDATION
                        --------------------------------------------------

                        if not wedgeActive then
                            return
                        end

                        if not humanoid or not myHRP then
                            return
                        end

                        if not targetPlayer then
                            return
                        end

                        --------------------------------------------------
                        -- TARGET CHARACTER
                        --------------------------------------------------

                        local targetCharacter =
                            targetPlayer.Character

                        if not targetCharacter then
                            return
                        end

                        --------------------------------------------------
                        -- TARGET HRP
                        --------------------------------------------------

                        local targetHRP =
                            targetCharacter:FindFirstChild(
                                "HumanoidRootPart"
                            )

                        if not targetHRP then
                            return
                        end

                        --------------------------------------------------
                        -- DISTANCE
                        --------------------------------------------------

                        local distance =
                            getBotDistance(
                                targetPlayer
                            )

                        --------------------------------------------------
                        -- POSITION
                        --------------------------------------------------

                        local targetPosition =
                            getWedgePosition(
                                myIndex,
                                targetHRP,
                                distance
                            )

                        if not targetPosition then
                            return
                        end

                        --------------------------------------------------
                        -- DISTANCE TO POSITION
                        --------------------------------------------------

                        local distanceToTarget =
                            (
                                myHRP.Position
                                - targetPosition
                            ).Magnitude

                        --------------------------------------------------
                        -- MOVE
                        --------------------------------------------------

                        if distanceToTarget > stopThreshold then

                            humanoid.AutoRotate = true

                            humanoid:MoveTo(
                                targetPosition
                            )

                            return
                        end

                        --------------------------------------------------
                        -- REACHED POSITION
                        --------------------------------------------------

                        humanoid.AutoRotate = false

                        --------------------------------------------------
                        -- COPY TARGET ROTATION
                        --------------------------------------------------

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

        --------------------------------------------------
        -- HANDLE COMMAND
        --------------------------------------------------

        local function handleCommand(
            message,
            sender
        )

            --------------------------------------------------
            -- ADMIN ONLY
            --------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end

            local lower =
                message:lower()

            --------------------------------------------------
            -- !wedgetv
            --------------------------------------------------

            if lower == "!wedgetv" then

                startWedge(sender)
                return

            end

            --------------------------------------------------
            -- !wedgetv PlayerName
            --------------------------------------------------

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

            --------------------------------------------------
            -- !stop
            --------------------------------------------------

            if lower == "!stop" then

                vars.ActiveMode = nil

                stopWedge()

                return
            end

        end

        --------------------------------------------------
        -- TEXT CHAT SERVICE
        --------------------------------------------------

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

        --------------------------------------------------
        -- OLD CHAT
        --------------------------------------------------

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

        --------------------------------------------------
        -- NEW PLAYER
        --------------------------------------------------

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

        --------------------------------------------------
        -- RESPAWN
        --------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(
            function()

                task.wait(1)

                updateCharacter()

                --------------------------------------------------
                -- RESTART WEDGE
                --------------------------------------------------

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