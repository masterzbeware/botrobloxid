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

        local triangleActive = false
        local triangleConnection = nil
        local targetPlayer = nil

        --------------------------------------------------
        -- BOT ORDER
        --------------------------------------------------
        -- HANYA BOT 1 - BOT 11
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

        -- Jarak dasar dari Player
        local baseDistance = 5

        -- Jarak antar baris
        local rowSpacing = 3

        -- Jarak kiri / kanan utama
        local sideSpacing = 3

        -- Jarak B10 dan B11 dari tengah
        local centerSpacing = 2

        -- Jarak minimum sebelum berhenti
        local stopThreshold = 1.5

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
                character:WaitForChild("HumanoidRootPart")

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
        -- STOP TRIANGLE
        --------------------------------------------------

        local function stopTriangle()

            triangleActive = false
            targetPlayer = nil

            if triangleConnection then

                triangleConnection:Disconnect()
                triangleConnection = nil

            end

            if humanoid then

                humanoid.AutoRotate = true

            end

        end

        --------------------------------------------------
        -- REGISTER CONTROLLER
        --------------------------------------------------

        vars.ModeControllers.triangle =
            stopTriangle

        --------------------------------------------------
        -- STOP OTHER MODES
        --------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in
                pairs(vars.ModeControllers) do

                if name ~= "triangle"
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
        -- GET TRIANGLE POSITION
        --------------------------------------------------
        --
        -- FORMASI 11 BOT:
        --
        --
        --                         B1
        --                          ▲
        --
        --                    B2         B3
        --                     ▲         ▲
        --
        --                B4                 B5
        --                 ▲                 ▲
        --
        --           B6                              B7
        --            ▲                              ▲
        --
        --      B8                              B9
        --       ▲                              ▲
        --
        --                    B10      B11
        --                      ▲        ▲
        --
        --                          👤
        --                        PLAYER
        --                          ▲
        --                     Arah Player
        --
        --------------------------------------------------

        local function getTrianglePosition(
            myIndex,
            targetHRP,
            distance
        )

            if not myIndex
                or not targetHRP
                or not distance then

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
            -- BOT 1
            -- FRONT CENTER
            --------------------------------------------------

            if myIndex == 1 then

                return origin
                    + forward
                    * distance

            end

            --------------------------------------------------
            -- BOT 2
            -- FRONT LEFT
            --------------------------------------------------

            if myIndex == 2 then

                return origin
                    + forward
                    * (distance - rowSpacing)
                    - right
                    * sideSpacing

            end

            --------------------------------------------------
            -- BOT 3
            -- FRONT RIGHT
            --------------------------------------------------

            if myIndex == 3 then

                return origin
                    + forward
                    * (distance - rowSpacing)
                    + right
                    * sideSpacing

            end

            --------------------------------------------------
            -- BOT 4
            -- MIDDLE LEFT
            --------------------------------------------------

            if myIndex == 4 then

                return origin
                    + forward
                    * (distance - rowSpacing * 2)
                    - right
                    * (sideSpacing * 1.8)

            end

            --------------------------------------------------
            -- BOT 5
            -- MIDDLE RIGHT
            --------------------------------------------------

            if myIndex == 5 then

                return origin
                    + forward
                    * (distance - rowSpacing * 2)
                    + right
                    * (sideSpacing * 1.8)

            end

            --------------------------------------------------
            -- BOT 6
            -- BACK ROW OUTER LEFT
            --------------------------------------------------

            if myIndex == 6 then

                return origin
                    + forward
                    * (distance - rowSpacing * 3)
                    - right
                    * (sideSpacing * 2.5)

            end

            --------------------------------------------------
            -- BOT 7
            -- BACK ROW OUTER RIGHT
            --------------------------------------------------

            if myIndex == 7 then

                return origin
                    + forward
                    * (distance - rowSpacing * 3)
                    + right
                    * (sideSpacing * 2.5)

            end

            --------------------------------------------------
            -- BOT 8
            -- SAMA SEPERTI BOT 6
            -- OUTER LEFT
            --------------------------------------------------

            if myIndex == 8 then

                return origin
                    + forward
                    * (
                        distance
                        - rowSpacing * 3
                        - backSpacing
                    )
                    - right
                    * (sideSpacing * 2.5)

            end

            --------------------------------------------------
            -- BOT 9
            -- SAMA SEPERTI BOT 7
            -- OUTER RIGHT
            --------------------------------------------------

            if myIndex == 9 then

                return origin
                    + forward
                    * (
                        distance
                        - rowSpacing * 3
                        - backSpacing
                    )
                    + right
                    * (sideSpacing * 2.5)

            end

            --------------------------------------------------
            -- BOT 10
            -- TENGAH KIRI
            -- POSISI PENGGANTI BOT 12
            --------------------------------------------------

            if myIndex == 10 then

                return origin
                    + forward
                    * (
                        distance
                        - rowSpacing * 3
                        - backSpacing
                    )
                    - right
                    * centerSpacing

            end

            --------------------------------------------------
            -- BOT 11
            -- TENGAH KANAN
            -- POSISI PENGGANTI BOT 14
            --------------------------------------------------

            if myIndex == 11 then

                return origin
                    + forward
                    * (
                        distance
                        - rowSpacing * 3
                        - backSpacing
                    )
                    + right
                    * centerSpacing

            end

            return nil

        end

        --------------------------------------------------
        -- START TRIANGLE
        --------------------------------------------------

        local function startTriangle(player)

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

            vars.ActiveMode = "triangle"

            --------------------------------------------------
            -- DISCONNECT OLD LOOP
            --------------------------------------------------

            if triangleConnection then

                triangleConnection:Disconnect()
                triangleConnection = nil

            end

            --------------------------------------------------
            -- STATE
            --------------------------------------------------

            triangleActive = true
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

            if not myIndex then

                stopTriangle()

                return

            end

            --------------------------------------------------
            -- DEBUG
            --------------------------------------------------

            print(
                "[TRIANGLE]",
                "Bot Index:",
                myIndex,
                "UserId:",
                LocalPlayer.UserId
            )

            --------------------------------------------------
            -- HEARTBEAT
            --------------------------------------------------

            triangleConnection =
                RunService.Heartbeat:Connect(
                    function()

                        --------------------------------------------------
                        -- MODE CHANGED
                        --------------------------------------------------

                        if vars.ActiveMode
                            ~= "triangle" then

                            stopTriangle()

                            return

                        end

                        --------------------------------------------------
                        -- ACTIVE CHECK
                        --------------------------------------------------

                        if not triangleActive then
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
                        -- POSITION
                        --------------------------------------------------

                        local targetPosition =
                            getTrianglePosition(
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

                        if distanceToTarget
                            > stopThreshold then

                            humanoid.AutoRotate = true

                            humanoid:MoveTo(
                                targetPosition
                            )

                            return

                        end

                        --------------------------------------------------
                        -- REACHED
                        --------------------------------------------------

                        humanoid.AutoRotate = false

                        --------------------------------------------------
                        -- COPY PLAYER ROTATION
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
            -- !TRIANGLE
            --------------------------------------------------

            if lower == "!triangle" then

                startTriangle(sender)

                return

            end

            --------------------------------------------------
            -- !TRIANGLE PLAYER
            --------------------------------------------------

            local targetName =
                lower:match(
                    "^!triangle%s+(.+)$"
                )

            if targetName then

                local target =
                    findPlayerByName(
                        targetName
                    )

                if target then

                    startTriangle(
                        target
                    )

                end

                return

            end

            --------------------------------------------------
            -- !STOP
            --------------------------------------------------

            if lower == "!stop"
                or lower == "!untriangle" then

                vars.ActiveMode = nil

                stopTriangle()

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
                -- RESTART TRIANGLE
                --------------------------------------------------

                if vars.ActiveMode
                    == "triangle"
                    and targetPlayer then

                    startTriangle(
                        targetPlayer
                    )

                end

            end
        )

    end
}