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

            "11641280895", -- Bot 10
            "11641342530", -- Bot 11
            "11001607521", -- Bot 12
            "11001608049", -- Bot 13
            "11001625681", -- Bot 14

        }

        --------------------------------------------------
        -- FORMATION SETTINGS
        --------------------------------------------------

        -- Jarak dasar dari PLAYER
        local baseBackDistance = 1

        -- Jarak antar baris
        local rowSpacing = 3

        -- Jarak kiri / kanan
        local sideSpacing = 3

        -- Jarak Bot 13 dan 14 dari titik tengah
        local centerSpacing = 1.5

        -- Jarak minimum sebelum berhenti MoveTo
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
                    TextChatService.TextChannels:FindFirstChild(
                        "RBXGeneral"
                    )

                if channel then

                    pcall(function()

                        channel:SendAsync(
                            message
                        )

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

        vars.ModeControllers.wedgetv =
            stopWedge

        --------------------------------------------------
        -- STOP OTHER MODES
        --------------------------------------------------

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

            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if player.Name:lower() == name
                    or player.DisplayName:lower() == name then

                    return player

                end

            end

            --------------------------------------------------
            -- PARTIAL MATCH
            --------------------------------------------------

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

        --------------------------------------------------
        -- GET BOT DISTANCE
        --------------------------------------------------

        local function getBotDistance(player)

            local distance = 1

            --------------------------------------------------
            -- ADMIN DEFAULT DISTANCE
            --------------------------------------------------

            if Admin:IsAdmin(player) then

                distance = 1

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
        -- GET WEDGE POSITION
        --------------------------------------------------
        --
        -- FORMASI:
        --
        --                         PLAYER
        --                           👤
        --
        --                    B2          B1
        --
        --                 B4              B3
        --
        --              B6                    B5
        --
        --           B8                          B7
        --
        --        B10                              B9
        --
        --      B12                                  B11
        --
        --                    B13    B14
        --
        --------------------------------------------------

        local function getWedgePosition(
            myIndex,
            targetHRP,
            distance
        )

            --------------------------------------------------
            -- VALIDASI
            --------------------------------------------------

            if not myIndex
                or not targetHRP
                or not distance then

                return nil

            end

            --------------------------------------------------
            -- BOT 1-12
            --
            -- SETIAP 2 BOT = 1 BARIS
            --------------------------------------------------

            if myIndex >= 1
                and myIndex <= 12 then

                --------------------------------------------------
                -- HITUNG BARIS
                --
                -- 1,2   = row 0
                -- 3,4   = row 1
                -- 5,6   = row 2
                -- 7,8   = row 3
                -- 9,10  = row 4
                -- 11,12 = row 5
                --------------------------------------------------

                local row =
                    math.floor(
                        (myIndex - 1) / 2
                    )

                --------------------------------------------------
                -- JARAK KE BELAKANG
                --------------------------------------------------

                local backDistance =
                    baseBackDistance
                    + (rowSpacing * row)
                    + distance

                --------------------------------------------------
                -- HITUNG SISI
                --------------------------------------------------

                local side

                if myIndex % 2 == 1 then

                    -- GANJIL = KANAN

                    side = 1

                else

                    -- GENAP = KIRI

                    side = -1

                end

                --------------------------------------------------
                -- LEBAR FORMASI
                --
                -- Row 0 = 0.5
                -- Row 1 = 1
                -- Row 2 = 1.5
                -- Row 3 = 2
                -- Row 4 = 2.5
                -- Row 5 = 3
                --------------------------------------------------

                local sideMultiplier =
                    0.5 + (row * 0.5)

                local sideDistance =
                    sideSpacing
                    * sideMultiplier
                    * side

                --------------------------------------------------
                -- POSISI AKHIR
                --------------------------------------------------

                return targetHRP.Position

                    - (
                        targetHRP.CFrame.LookVector
                        * backDistance
                    )

                    + (
                        targetHRP.CFrame.RightVector
                        * sideDistance
                    )

            end

            --------------------------------------------------
            -- BOT 13
            --
            -- TENGAH KIRI
            --
            -- SEJAJAR DENGAN BARIS TERAKHIR
            --------------------------------------------------

            if myIndex == 13 then

                local row = 6

                local backDistance =
                    baseBackDistance
                    + (rowSpacing * row)
                    + distance

                return targetHRP.Position

                    - (
                        targetHRP.CFrame.LookVector
                        * backDistance
                    )

                    - (
                        targetHRP.CFrame.RightVector
                        * centerSpacing
                    )

            end

            --------------------------------------------------
            -- BOT 14
            --
            -- TENGAH KANAN
            --
            -- SEJAJAR DENGAN BARIS TERAKHIR
            --------------------------------------------------

            if myIndex == 14 then

                local row = 6

                local backDistance =
                    baseBackDistance
                    + (rowSpacing * row)
                    + distance

                return targetHRP.Position

                    - (
                        targetHRP.CFrame.LookVector
                        * backDistance
                    )

                    + (
                        targetHRP.CFrame.RightVector
                        * centerSpacing
                    )

            end

            --------------------------------------------------
            -- FALLBACK
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

            --------------------------------------------------
            -- USERID TIDAK TERDAFTAR
            --------------------------------------------------

            if not myIndex then

                stopWedge()

                return

            end

            --------------------------------------------------
            -- DEBUG
            --------------------------------------------------

            print(
                "[WEDGETV] Bot Index:",
                myIndex,
                "UserId:",
                LocalPlayer.UserId
            )

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

                        if not humanoid
                            or not myHRP then

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

                        local botDistance =
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
                                botDistance
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

                    startWedge(
                        target
                    )

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