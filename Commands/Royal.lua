:::writing{variant="document" id="58321" title="Royal.lua"}
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
        -- GLOBAL VARIABLES
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
        -- CHARACTER
        ----------------------------------------------------------------

        local humanoid
        local myHRP

        ----------------------------------------------------------------
        -- STATE
        ----------------------------------------------------------------

        local royalActive = false
        local royalConnection = nil
        local targetPlayer = nil

        ----------------------------------------------------------------
        -- ROYAL FORMATION SETTINGS
        ----------------------------------------------------------------

        -- Jarak dasar Bot dari Player
        local baseDistance = 4

        -- Jarak antar Bot ke belakang
        local rowSpacing = 3

        -- Jarak kiri / kanan dari Player
        local sideSpacing = 4

        -- Jarak Bot 13 dan 14 di belakang tengah
        local centerSpacing = 2

        -- Jarak minimum sebelum berhenti MoveTo
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
            "11001607521", -- Bot 12
            "11001608049", -- Bot 13
            "11001625681", -- Bot 14

        }

        ----------------------------------------------------------------
        -- ROYAL FORMATION
        ----------------------------------------------------------------
        --
        --                 ARAH DEPAN
        --
        --        B1                  B2
        --        B3                  B4
        --        B5                  B6
        --        B7                  B8
        --        B9                  B10
        --        B11                 B12
        --
        --             B13       B14
        --
        --                 👑 PLAYER
        --
        ----------------------------------------------------------------

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

            ------------------------------------------------------------
            -- OLD CHAT FALLBACK
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
        -- STOP ROYAL
        ----------------------------------------------------------------

        local function stopRoyal()

            royalActive = false
            targetPlayer = nil

            if royalConnection then

                royalConnection:Disconnect()
                royalConnection = nil

            end

            if humanoid then

                humanoid.AutoRotate = true

            end

        end

        ----------------------------------------------------------------
        -- REGISTER MODE CONTROLLER
        ----------------------------------------------------------------

        vars.ModeControllers.royal =
            stopRoyal

        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                vars.ModeControllers
            ) do

                if name ~= "royal"
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
            -- EXACT MATCH
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
            -- PARTIAL MATCH
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
        -- GET BOT DISTANCE
        ----------------------------------------------------------------

        local function getBotDistance(player)

            local distance = 1

            ------------------------------------------------------------
            -- ADMIN DEFAULT DISTANCE
            ------------------------------------------------------------

            if Admin:IsAdmin(player) then

                distance = 1

            end

            ------------------------------------------------------------
            -- SPECIAL DISTANCE
            ------------------------------------------------------------

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
        -- GET ROYAL POSITION
        ----------------------------------------------------------------
        --
        -- BOT 1 - 12
        --
        -- Membentuk dua kolom kiri / kanan.
        --
        -- Bot ganjil  = kanan
        -- Bot genap   = kiri
        --
        ----------------------------------------------------------------

        local function getRoyalPosition(
            myIndex,
            targetHRP,
            distance
        )

            if not myIndex
                or not targetHRP
                or not distance then

                return nil

            end

            ------------------------------------------------------------
            -- BOT 1 - 12
            ------------------------------------------------------------

            if myIndex >= 1
                and myIndex <= 12 then

                --------------------------------------------------------
                -- HITUNG ROW
                --------------------------------------------------------

                local row =
                    math.floor(
                        (myIndex - 1) / 2
                    )

                --------------------------------------------------------
                -- JARAK KE DEPAN
                --
                -- Row 0 paling dekat Player
                -- Row 5 paling jauh
                --------------------------------------------------------

                local forwardDistance =
                    baseDistance
                    + distance
                    + (
                        rowSpacing * row
                    )

                --------------------------------------------------------
                -- SISI
                --
                -- GANJIL = KANAN
                -- GENAP  = KIRI
                --------------------------------------------------------

                local side

                if myIndex % 2 == 1 then

                    side = 1

                else

                    side = -1

                end

                --------------------------------------------------------
                -- POSISI SAMPING
                --------------------------------------------------------

                local sideDistance =
                    sideSpacing

                --------------------------------------------------------
                -- FINAL POSITION
                --
                -- Bot berada DI DEPAN target.
                --------------------------------------------------------

                return targetHRP.Position

                    + (
                        targetHRP.CFrame.LookVector
                        * forwardDistance
                    )

                    + (
                        targetHRP.CFrame.RightVector
                        * (
                            sideDistance
                            * side
                        )
                    )

            end

            ------------------------------------------------------------
            -- BOT 13
            --
            -- BELAKANG TENGAH KIRI
            ------------------------------------------------------------

            if myIndex == 13 then

                local row = 6

                local forwardDistance =
                    baseDistance
                    + distance
                    + (
                        rowSpacing * row
                    )

                return targetHRP.Position

                    + (
                        targetHRP.CFrame.LookVector
                        * forwardDistance
                    )

                    - (
                        targetHRP.CFrame.RightVector
                        * centerSpacing
                    )

            end

            ------------------------------------------------------------
            -- BOT 14
            --
            -- BELAKANG TENGAH KANAN
            ------------------------------------------------------------

            if myIndex == 14 then

                local row = 6

                local forwardDistance =
                    baseDistance
                    + distance
                    + (
                        rowSpacing * row
                    )

                return targetHRP.Position

                    + (
                        targetHRP.CFrame.LookVector
                        * forwardDistance
                    )

                    + (
                        targetHRP.CFrame.RightVector
                        * centerSpacing
                    )

            end

            return nil

        end

        ----------------------------------------------------------------
        -- COPY TARGET ROTATION
        ----------------------------------------------------------------

        local function copyTargetRotation(
            targetHRP
        )

            if not targetHRP
                or not myHRP then

                return

            end

            ------------------------------------------------------------
            -- COPY ROTATION SAJA
            --
            -- POSISI BOT TETAP.
            --
            ------------------------------------------------------------

            local targetRotation =
                targetHRP.CFrame
                - targetHRP.Position

            myHRP.CFrame =
                CFrame.new(
                    myHRP.Position
                )
                * targetRotation

        end

        ----------------------------------------------------------------
        -- START ROYAL
        ----------------------------------------------------------------

        local function startRoyal(player)

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

            vars.ActiveMode = "royal"

            ------------------------------------------------------------
            -- DISCONNECT OLD CONNECTION
            ------------------------------------------------------------

            if royalConnection then

                royalConnection:Disconnect()
                royalConnection = nil

            end

            ------------------------------------------------------------
            -- STATE
            ------------------------------------------------------------

            royalActive = true
            targetPlayer = player

            ------------------------------------------------------------
            -- CHAT
            ------------------------------------------------------------

            sendChat("Yes, Sir!")

            ------------------------------------------------------------
            -- GET BOT INDEX
            ------------------------------------------------------------

            local myIndex =
                table.find(
                    botOrder,
                    tostring(LocalPlayer.UserId)
                )

            ------------------------------------------------------------
            -- BOT TIDAK TERDAFTAR
            ------------------------------------------------------------

            if not myIndex then

                stopRoyal()

                return

            end

            ------------------------------------------------------------
            -- DEBUG
            ------------------------------------------------------------

            print(
                "[ROYAL]",
                "Bot Index:",
                myIndex,
                "UserId:",
                LocalPlayer.UserId
            )

            ------------------------------------------------------------
            -- HEARTBEAT
            ------------------------------------------------------------

            royalConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- MODE CHECK
                        ------------------------------------------------

                        if vars.ActiveMode
                            ~= "royal" then

                            stopRoyal()

                            return

                        end

                        ------------------------------------------------
                        -- ACTIVE CHECK
                        ------------------------------------------------

                        if not royalActive then
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

                        local botDistance =
                            getBotDistance(
                                targetPlayer
                            )

                        ------------------------------------------------
                        -- GET FORMATION POSITION
                        ------------------------------------------------

                        local targetPosition =
                            getRoyalPosition(
                                myIndex,
                                targetHRP,
                                botDistance
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
                                -
                                targetPosition
                            ).Magnitude

                        ------------------------------------------------
                        -- MOVE
                        ------------------------------------------------

                        if distanceToTarget
                            > stopThreshold then

                            ------------------------------------------------
                            -- SAAT BERJALAN
                            ------------------------------------------------

                            humanoid.AutoRotate = true

                            humanoid:MoveTo(
                                targetPosition
                            )

                            return

                        end

                        ------------------------------------------------
                        -- SUDAH SAMPAI
                        ------------------------------------------------

                        humanoid.AutoRotate = false

                        ------------------------------------------------
                        -- COPY ROTASI TARGET
                        ------------------------------------------------

                        copyTargetRotation(
                            targetHRP
                        )

                    end
                )

        end

        ----------------------------------------------------------------
        -- HANDLE COMMAND
        ----------------------------------------------------------------

        local function handleCommand(
            message,
            sender
        )

            ------------------------------------------------------------
            -- ADMIN ONLY
            ------------------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end

            local lower =
                message:lower()

            ------------------------------------------------------------
            -- !ROYAL
            ------------------------------------------------------------

            if lower == "!royal" then

                startRoyal(sender)

                return

            end

            ------------------------------------------------------------
            -- !ROYAL PLAYER
            ------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!royal%s+(.+)$"
                )

            if targetName then

                local target =
                    findPlayerByName(
                        targetName
                    )

                if target then

                    startRoyal(
                        target
                    )

                end

                return

            end

            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if lower == "!stop"
                or lower == "!unroyal" then

                vars.ActiveMode = nil

                stopRoyal()

                return

            end

        end

        ----------------------------------------------------------------
        -- TEXT CHAT SERVICE
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

            end

        end

        ----------------------------------------------------------------
        -- OLD CHAT
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

                --------------------------------------------------------
                -- RESTART ROYAL
                --------------------------------------------------------

                if vars.ActiveMode == "royal"
                    and targetPlayer then

                    startRoyal(
                        targetPlayer
                    )

                end

            end
        )

    end
}
:::