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

        local triangle2Active = false
        local triangle2Connection = nil
        local targetPlayer = nil

        --------------------------------------------------
        -- BOT ORDER
        --------------------------------------------------
        --
        -- BOT 1  BOT 2
        -- BOT 3  BOT 4
        -- BOT 5  BOT 6
        -- BOT 7  BOT 8
        -- BOT 9  BOT 10
        -- BOT 11
        --
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

        -- Jarak BOT dari PLAYER
        local baseDistance = 5

        -- Jarak antar baris
        local rowSpacing = 3

        -- Jarak kiri / kanan
        local sideSpacing = 3

        -- Jarak minimum untuk dianggap sudah sampai
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

                    local ok = pcall(function()

                        channel:SendAsync(message)

                    end)

                    if ok then
                        success = true
                    end

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
        -- STOP TRIANGLE2
        --------------------------------------------------

        local function stopTriangle2()

            triangle2Active = false
            targetPlayer = nil

            --------------------------------------------------
            -- DISCONNECT LOOP
            --------------------------------------------------

            if triangle2Connection then

                triangle2Connection:Disconnect()
                triangle2Connection = nil

            end

            --------------------------------------------------
            -- RESET CHARACTER
            --------------------------------------------------

            if humanoid then

                humanoid.AutoRotate = true

            end

        end

        --------------------------------------------------
        -- REGISTER TRIANGLE2 CONTROLLER
        --------------------------------------------------

        vars.ModeControllers.triangle2 =
            stopTriangle2

        --------------------------------------------------
        -- STOP OTHER MODES
        --------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in
                pairs(vars.ModeControllers) do

                if name ~= "triangle2"
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
        -- GET TRIANGLE2 POSITION
        --------------------------------------------------
        --
        -- FORMASI:
        --
        --                 PLAYER
        --                   👤
        --
        --              BOT1   BOT2
        --               🧍     🧍
        --
        --           BOT3       BOT4
        --            🧍         🧍
        --
        --           BOT5       BOT6
        --            🧍         🧍
        --
        --           BOT7       BOT8
        --            🧍         🧍
        --
        --           BOT9      BOT10
        --            🧍        🧍
        --
        --                 BOT11
        --                   🧍
        --
        --------------------------------------------------

        local function getTriangle2Position(
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
            -- PLAYER AXIS
            --------------------------------------------------

            local forward =
                targetHRP.CFrame.LookVector

            local right =
                targetHRP.CFrame.RightVector

            local origin =
                targetHRP.Position

            --------------------------------------------------
            -- ROW
            --------------------------------------------------
            --
            -- BOT1  BOT2  = row 0
            -- BOT3  BOT4  = row 1
            -- BOT5  BOT6  = row 2
            -- BOT7  BOT8  = row 3
            -- BOT9 BOT10  = row 4
            -- BOT11       = row 5
            --
            --------------------------------------------------

            local row =
                math.floor(
                    (myIndex - 1) / 2
                )

            --------------------------------------------------
            -- FORWARD DISTANCE
            --------------------------------------------------

            local forwardDistance =
                distance
                - (
                    row
                    * rowSpacing
                )

            --------------------------------------------------
            -- BOT 11
            --------------------------------------------------
            --
            -- BOT11 berada di tengah.
            --
            --------------------------------------------------

            if myIndex == #botOrder
                and myIndex % 2 == 1 then

                return origin
                    + forward
                    * forwardDistance

            end

            --------------------------------------------------
            -- KIRI / KANAN
            --------------------------------------------------

            local sideOffset

            if myIndex % 2 == 1 then

                -- GANJIL = KIRI

                sideOffset =
                    -sideSpacing

            else

                -- GENAP = KANAN

                sideOffset =
                    sideSpacing

            end

            --------------------------------------------------
            -- RETURN
            --------------------------------------------------

            return origin
                + forward
                * forwardDistance
                + right
                * sideOffset

        end

        --------------------------------------------------
        -- START TRIANGLE2
        --------------------------------------------------

        local function startTriangle2(player)

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

            vars.ActiveMode = "triangle2"

            --------------------------------------------------
            -- DISCONNECT LOOP LAMA
            --------------------------------------------------

            if triangle2Connection then

                triangle2Connection:Disconnect()
                triangle2Connection = nil

            end

            --------------------------------------------------
            -- STATE
            --------------------------------------------------

            triangle2Active = true
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
            -- BOT TIDAK ADA DI FORMASI
            --------------------------------------------------

            if not myIndex then

                print(
                    "[TRIANGLE2] Bot tidak termasuk formasi:",
                    LocalPlayer.Name,
                    LocalPlayer.UserId
                )

                stopTriangle2()

                return

            end

            --------------------------------------------------
            -- DEBUG
            --------------------------------------------------

            print(
                "[TRIANGLE2]",
                "Bot Index:",
                myIndex,
                "UserId:",
                LocalPlayer.UserId
            )

            --------------------------------------------------
            -- HEARTBEAT
            --------------------------------------------------

            triangle2Connection =
                RunService.Heartbeat:Connect(
                    function()

                        --------------------------------------------------
                        -- MODE CHECK
                        --------------------------------------------------

                        if vars.ActiveMode
                            ~= "triangle2" then

                            stopTriangle2()

                            return

                        end

                        --------------------------------------------------
                        -- ACTIVE CHECK
                        --------------------------------------------------

                        if not triangle2Active then
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
                        -- FORMATION POSITION
                        --------------------------------------------------

                        local targetPosition =
                            getTriangle2Position(
                                myIndex,
                                targetHRP,
                                distance
                            )

                        if not targetPosition then
                            return
                        end

                        --------------------------------------------------
                        -- DISTANCE TO TARGET
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
                        -- SUDAH SAMPAI
                        --------------------------------------------------

                        humanoid.AutoRotate = false

                        --------------------------------------------------
                        -- IKUT ROTASI PLAYER
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

            if not message then
                return
            end

            local lower =
                message:lower()

            --------------------------------------------------
            -- !TRIANGLE2
            --------------------------------------------------

            if lower == "!triangle2" then

                startTriangle2(sender)

                return

            end

            --------------------------------------------------
            -- !TRIANGLE2 PLAYER
            --------------------------------------------------

            local targetName =
                lower:match(
                    "^!triangle2%s+(.+)$"
                )

            if targetName then

                local target =
                    findPlayerByName(
                        targetName
                    )

                if target then

                    startTriangle2(
                        target
                    )

                else

                    print(
                        "[TRIANGLE2] Player tidak ditemukan:",
                        targetName
                    )

                end

                return

            end

            --------------------------------------------------
            -- STOP TRIANGLE2
            --------------------------------------------------

            if lower == "!stoptriangle2"
                or lower == "!untriangle2" then

                if vars.ActiveMode
                    == "triangle2" then

                    vars.ActiveMode = nil

                    stopTriangle2()

                end

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
                -- RESTART TRIANGLE2
                --------------------------------------------------

                if vars.ActiveMode
                    == "triangle2"
                    and targetPlayer then

                    startTriangle2(
                        targetPlayer
                    )

                end

            end
        )

        --------------------------------------------------
        -- READY
        --------------------------------------------------

        print(
            "[TRIANGLE2] Loaded successfully."
        )

    end
}