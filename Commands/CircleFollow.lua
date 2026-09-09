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
        -- GLOBAL MODE SYSTEM
        --------------------------------------------------

        _G.BotVars = _G.BotVars or {}

        _G.BotVars.ModeControllers =
            _G.BotVars.ModeControllers or {}

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

        local circleFollowActive = false
        local circleFollowConnection = nil
        local targetPlayer = nil

        --------------------------------------------------
        -- BOT ORDER
        --------------------------------------------------
        -- BOT 1 - BOT 11 IKUT FORMASI
        -- BOT 12+ TIDAK IKUT
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
            "11641280895", -- Bot 10
            "11641342530", -- Bot 11

        }

        --------------------------------------------------
        -- FORMATION SETTINGS
        --------------------------------------------------

        local baseDistance = 5

        local stopThreshold = 1.5

        --------------------------------------------------
        -- CIRCLE SETTINGS
        --------------------------------------------------

        -- Jarak bot dari player
        local circleRadius = 8

        -- Kecepatan putaran lingkaran
        -- Semakin besar = semakin cepat
        local orbitSpeed = 1

        -- Posisi awal lingkaran
        local startingAngle = 0

        --------------------------------------------------
        -- UPDATE CHARACTER
        --------------------------------------------------

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
                    TextChatService.TextChannels
                    :FindFirstChild("RBXGeneral")

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
                        ReplicatedStorage
                        :FindFirstChild(
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
        -- STOP CIRCLE FOLLOW
        --------------------------------------------------

        local function stopCircleFollow()

            circleFollowActive = false
            targetPlayer = nil

            if circleFollowConnection then

                circleFollowConnection:Disconnect()
                circleFollowConnection = nil

            end

            if humanoid then

                humanoid.AutoRotate = true

            end

        end

        --------------------------------------------------
        -- REGISTER CONTROLLER
        --------------------------------------------------

        vars.ModeControllers.circlefollow =
            stopCircleFollow

        --------------------------------------------------
        -- STOP OTHER MODES
        --------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in
                pairs(vars.ModeControllers) do

                if name ~= "circlefollow"
                    and type(stopFunction) == "function" then

                    pcall(stopFunction)

                end

            end

        end

        --------------------------------------------------
        -- FIND PLAYER
        --------------------------------------------------

        local function findPlayerByName(name)

            if not name or name == "" then
                return nil
            end

            name = name:lower()

            --------------------------------------------------
            -- EXACT MATCH
            --------------------------------------------------

            for _, player in
                ipairs(Players:GetPlayers()) do

                if player.Name:lower() == name
                    or player.DisplayName:lower() == name then

                    return player

                end

            end

            --------------------------------------------------
            -- PARTIAL MATCH
            --------------------------------------------------

            for _, player in
                ipairs(Players:GetPlayers()) do

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

        --------------------------------------------------
        -- GET DISTANCE
        --------------------------------------------------

        local function getBotDistance(player)

            local distance = baseDistance

            --------------------------------------------------
            -- ADMIN DISTANCE
            --------------------------------------------------

            if Admin:IsAdmin(player) then

                distance = baseDistance

            end

            --------------------------------------------------
            -- SPECIAL DISTANCE
            --------------------------------------------------

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
        -- GET CIRCLE POSITION
        --------------------------------------------------
        --
        -- BOT AKAN MEMBENTUK LINGKARAN
        -- DAN POSISI LINGKARAN AKAN BERPUTAR.
        --
        --                    B1
        --
        --              B11       B2
        --
        --          B10             B3
        --
        --        B9      PLAYER      B4
        --
        --          B8             B5
        --
        --              B7       B6
        --
        --------------------------------------------------

        local function getCircleFollowPosition(
            myIndex,
            targetHRP,
            distance,
            currentTime
        )

            if not myIndex
                or not targetHRP
                or not distance
                or not currentTime then

                return nil

            end

            --------------------------------------------------
            -- TOTAL BOT
            --------------------------------------------------

            local totalBots =
                #botOrder

            if totalBots <= 0 then
                return nil
            end

            --------------------------------------------------
            -- LOCAL AXIS
            --------------------------------------------------

            local forward =
                targetHRP.CFrame.LookVector

            local right =
                targetHRP.CFrame.RightVector

            local origin =
                targetHRP.Position

            --------------------------------------------------
            -- ORBIT ANGLE
            --------------------------------------------------

            local botAngle =
                ((myIndex - 1) / totalBots)
                * math.pi
                * 2

            --------------------------------------------------
            -- TOTAL ROTATION
            --------------------------------------------------

            local rotationAngle =
                startingAngle
                + currentTime
                * orbitSpeed

            --------------------------------------------------
            -- FINAL ANGLE
            --------------------------------------------------

            local finalAngle =
                botAngle
                + rotationAngle

            --------------------------------------------------
            -- RADIUS
            --------------------------------------------------

            local radius =
                circleRadius

            --------------------------------------------------
            -- CIRCLE OFFSET
            --------------------------------------------------

            local forwardOffset =
                math.cos(finalAngle)
                * radius

            local rightOffset =
                math.sin(finalAngle)
                * radius

            --------------------------------------------------
            -- FINAL POSITION
            --------------------------------------------------

            return origin
                + forward * forwardOffset
                + right * rightOffset

        end

        --------------------------------------------------
        -- START CIRCLE FOLLOW
        --------------------------------------------------

        local function startCircleFollow(player)

            if not player then
                return
            end

            --------------------------------------------------
            -- STOP MODE LAIN
            --------------------------------------------------

            stopOtherModes()

            --------------------------------------------------
            -- ACTIVE MODE
            --------------------------------------------------

            vars.ActiveMode =
                "circlefollow"

            --------------------------------------------------
            -- DISCONNECT OLD LOOP
            --------------------------------------------------

            if circleFollowConnection then

                circleFollowConnection:Disconnect()
                circleFollowConnection = nil

            end

            --------------------------------------------------
            -- STATE
            --------------------------------------------------

            circleFollowActive = true
            targetPlayer = player

            --------------------------------------------------
            -- CHAT
            --------------------------------------------------

            sendChat("Yes, Sir!")

            --------------------------------------------------
            -- FIND BOT INDEX
            --------------------------------------------------

            local myIndex =
                table.find(
                    botOrder,
                    tostring(LocalPlayer.UserId)
                )

            --------------------------------------------------
            -- BOT TIDAK TERDAFTAR
            --------------------------------------------------

            if not myIndex then

                print(
                    "[CIRCLE FOLLOW]",
                    "Bot tidak termasuk formasi:",
                    LocalPlayer.Name,
                    LocalPlayer.UserId
                )

                stopCircleFollow()

                return

            end

            --------------------------------------------------
            -- DEBUG
            --------------------------------------------------

            print(
                "[CIRCLE FOLLOW]",
                "Bot Index:",
                myIndex,
                "UserId:",
                LocalPlayer.UserId
            )

            --------------------------------------------------
            -- HEARTBEAT
            --------------------------------------------------

            circleFollowConnection =
                RunService.Heartbeat:Connect(
                    function()

                        --------------------------------------------------
                        -- MODE CHANGED
                        --------------------------------------------------

                        if vars.ActiveMode
                            ~= "circlefollow" then

                            stopCircleFollow()

                            return

                        end

                        --------------------------------------------------
                        -- ACTIVE CHECK
                        --------------------------------------------------

                        if not circleFollowActive then
                            return
                        end

                        --------------------------------------------------
                        -- CHARACTER CHECK
                        --------------------------------------------------

                        if not humanoid
                            or not myHRP then

                            return

                        end

                        --------------------------------------------------
                        -- TARGET CHECK
                        --------------------------------------------------

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
                        -- CURRENT TIME
                        --------------------------------------------------

                        local currentTime =
                            os.clock()

                        --------------------------------------------------
                        -- CIRCLE POSITION
                        --------------------------------------------------

                        local targetPosition =
                            getCircleFollowPosition(
                                myIndex,
                                targetHRP,
                                distance,
                                currentTime
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

                        if distanceToTarget
                            > stopThreshold then

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
                        -- FACE PLAYER
                        --------------------------------------------------

                        local lookPosition =
                            targetHRP.Position

                        myHRP.CFrame =
                            CFrame.lookAt(
                                myHRP.Position,
                                Vector3.new(
                                    lookPosition.X,
                                    myHRP.Position.Y,
                                    lookPosition.Z
                                )
                            )

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
            -- !CIRCLEFOLLOW
            --------------------------------------------------

            if lower == "!circlefollow" then

                startCircleFollow(
                    sender
                )

                return

            end

            --------------------------------------------------
            -- !CIRCLEFOLLOW PLAYER
            --------------------------------------------------

            local targetName =
                lower:match(
                    "^!circlefollow%s+(.+)$"
                )

            if targetName then

                local target =
                    findPlayerByName(
                        targetName
                    )

                if target then

                    startCircleFollow(
                        target
                    )

                end

                return

            end

            --------------------------------------------------
            -- !STOP
            --------------------------------------------------

            if lower == "!stop"
                or lower == "!uncirclefollow" then

                vars.ActiveMode = nil

                stopCircleFollow()

                return

            end

        end

        --------------------------------------------------
        -- TEXT CHAT SERVICE
        --------------------------------------------------

        if TextChatService
            and TextChatService.TextChannels then

            local channel =
                TextChatService.TextChannels
                :FindFirstChild("RBXGeneral")

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
        -- OLD CHAT FALLBACK
        --------------------------------------------------

        for _, player in
            ipairs(Players:GetPlayers()) do

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
        -- PLAYER ADDED
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
                -- RESTART CIRCLE FOLLOW
                --------------------------------------------------

                if vars.ActiveMode
                    == "circlefollow"
                    and targetPlayer then

                    startCircleFollow(
                        targetPlayer
                    )

                end

            end
        )

        --------------------------------------------------
        -- READY
        --------------------------------------------------

        print(
            "[CIRCLE FOLLOW] CircleFollow.lua aktif!"
        )

    end
}