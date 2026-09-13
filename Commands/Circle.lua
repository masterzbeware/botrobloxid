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
            warn("[Circle] LocalPlayer tidak ditemukan")
            return
        end

        ----------------------------------------------------------------
        -- GLOBAL
        ----------------------------------------------------------------

        _G.BotVars = _G.BotVars or {}

        _G.BotVars.ModeControllers =
            _G.BotVars.ModeControllers or {}

        local vars = _G.BotVars

        ----------------------------------------------------------------
        -- LOAD ADMIN
        ----------------------------------------------------------------

        local Admin

        do
            local success, result = pcall(function()
                return loadstring(game:HttpGet(
                    "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
                ))()
            end)

            if not success or not result then
                warn("[Circle] Gagal load Admin.lua")
                return
            end

            Admin = result
        end

        ----------------------------------------------------------------
        -- LOAD DISTANCE
        ----------------------------------------------------------------

        local Distance

        do
            local success, result = pcall(function()
                return loadstring(game:HttpGet(
                    "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
                ))()
            end)

            if not success or not result then
                warn("[Circle] Gagal load Distance.lua")
                return
            end

            Distance = result
        end

        ----------------------------------------------------------------
        -- CHARACTER
        ----------------------------------------------------------------

        local humanoid
        local myHRP

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
        -- STATE
        ----------------------------------------------------------------

        local circleActive = false
        local circleConnection = nil
        local targetPlayer = nil

        ----------------------------------------------------------------
        -- SETTINGS
        ----------------------------------------------------------------

        local circleRadius = 8
        local stopThreshold = 1.5

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
            "11641280895", -- Bot 10
            "11641342530", -- Bot 11

        }

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
                    TextChatService.TextChannels:FindFirstChild(
                        "RBXGeneral"
                    )

                if channel then

                    local sent = pcall(function()

                        channel:SendAsync(message)

                    end)

                    if sent then
                        success = true
                    end

                end

            end

            ------------------------------------------------------------
            -- OLD CHAT
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
        -- STOP CIRCLE
        ----------------------------------------------------------------

        local function stopCircle()

            circleActive = false
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

        vars.ModeControllers.circle =
            stopCircle

        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                vars.ModeControllers
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

            if not name or name == "" then
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
        -- GET DISTANCE
        ----------------------------------------------------------------

        local function getBotDistance(player)

            local distance = circleRadius

            local specialDistance =
                Distance:GetDistance(
                    tostring(LocalPlayer.UserId),
                    tostring(player.UserId)
                )

            if specialDistance then
                distance = math.max(
                    circleRadius,
                    specialDistance
                )
            end

            return distance

        end

        ----------------------------------------------------------------
        -- GET CIRCLE POSITION
        ----------------------------------------------------------------

        local function getCirclePosition(
            myIndex,
            targetHRP,
            radius
        )

            if not myIndex
                or not targetHRP
                or not radius then

                return nil

            end

            local totalBots = #botOrder

            if totalBots <= 0 then
                return nil
            end

            ------------------------------------------------------------
            -- ANGLE
            ------------------------------------------------------------

            local angle =
                ((myIndex - 1) / totalBots)
                * math.pi
                * 2

            ------------------------------------------------------------
            -- PLAYER AXIS
            ------------------------------------------------------------

            local forward =
                targetHRP.CFrame.LookVector

            local right =
                targetHRP.CFrame.RightVector

            ------------------------------------------------------------
            -- CIRCLE OFFSET
            ------------------------------------------------------------

            local forwardOffset =
                math.cos(angle) * radius

            local rightOffset =
                math.sin(angle) * radius

            ------------------------------------------------------------
            -- POSITION
            ------------------------------------------------------------

            return targetHRP.Position
                + forward * forwardOffset
                + right * rightOffset

        end

        ----------------------------------------------------------------
        -- START CIRCLE
        ----------------------------------------------------------------

        local function startCircle(player)

            if not player then
                return
            end

            ------------------------------------------------------------
            -- STOP OTHER MODES
            ------------------------------------------------------------

            stopOtherModes()

            ------------------------------------------------------------
            -- ACTIVE MODE
            ------------------------------------------------------------

            vars.ActiveMode = "circle"

            ------------------------------------------------------------
            -- STOP OLD CONNECTION
            ------------------------------------------------------------

            if circleConnection then

                circleConnection:Disconnect()
                circleConnection = nil

            end

            ------------------------------------------------------------
            -- STATE
            ------------------------------------------------------------

            circleActive = true
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
                    tostring(LocalPlayer.UserId)
                )

            if not myIndex then

                warn(
                    "[Circle] Bot tidak ada di botOrder:",
                    LocalPlayer.Name,
                    LocalPlayer.UserId
                )

                stopCircle()

                return

            end

            print(
                "[Circle] Started | Bot:",
                myIndex,
                "| Target:",
                player.Name
            )

            ----------------------------------------------------------------
            -- HEARTBEAT
            ----------------------------------------------------------------

            circleConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- MODE CHECK
                        ------------------------------------------------

                        if vars.ActiveMode ~= "circle" then

                            stopCircle()

                            return

                        end

                        ------------------------------------------------
                        -- ACTIVE CHECK
                        ------------------------------------------------

                        if not circleActive then
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
                        -- TARGET CHECK
                        ------------------------------------------------

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

                        ------------------------------------------------
                        -- TARGET HRP
                        ------------------------------------------------

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
                            getBotDistance(
                                targetPlayer
                            )

                        ------------------------------------------------
                        -- POSITION
                        ------------------------------------------------

                        local targetPosition =
                            getCirclePosition(
                                myIndex,
                                targetHRP,
                                radius
                            )

                        if not targetPosition then
                            return
                        end

                        ------------------------------------------------
                        -- DISTANCE TO POSITION
                        ------------------------------------------------

                        local distanceToTarget =
                            (
                                myHRP.Position
                                - targetPosition
                            ).Magnitude

                        ------------------------------------------------
                        -- MOVE
                        ------------------------------------------------

                        if distanceToTarget
                            > stopThreshold then

                            humanoid.AutoRotate = true

                            humanoid:MoveTo(
                                targetPosition
                            )

                            return

                        end

                        ------------------------------------------------
                        -- ARRIVED
                        ------------------------------------------------

                        humanoid.AutoRotate = false

                        ------------------------------------------------
                        -- FACE TARGET
                        ------------------------------------------------

                        local lookPosition =
                            targetHRP.Position

                        local flatLook =
                            Vector3.new(
                                lookPosition.X,
                                myHRP.Position.Y,
                                lookPosition.Z
                            )

                        myHRP.CFrame =
                            CFrame.lookAt(
                                myHRP.Position,
                                flatLook
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

            ------------------------------------------------------------
            -- ADMIN
            ------------------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end

            if not message then
                return
            end

            local lower =
                message:lower():match("^%s*(.-)%s*$")

            ------------------------------------------------------------
            -- !CIRCLE
            ------------------------------------------------------------

            if lower == "!circle" then

                startCircle(sender)

                return

            end

            ------------------------------------------------------------
            -- !CIRCLE PLAYER
            ------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!circle%s+(.+)$"
                )

            if targetName then

                local target =
                    findPlayerByName(
                        targetName
                    )

                if target then

                    startCircle(
                        target
                    )

                else

                    warn(
                        "[Circle] Target tidak ditemukan:",
                        targetName
                    )

                end

                return

            end

            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if lower == "!stop"
                or lower == "!uncircle" then

                vars.ActiveMode = nil

                stopCircle()

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

                print("[Circle] TextChat listener aktif")

            end

        end

        ----------------------------------------------------------------
        -- OLD CHAT FALLBACK
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
        -- RESPAWN
        ----------------------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(
            function()

                task.wait(1)

                updateCharacter()

                if vars.ActiveMode == "circle"
                    and targetPlayer then

                    startCircle(
                        targetPlayer
                    )

                end

            end
        )

        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[Circle] Circle.lua aktif!"
        )

    end
}