return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")

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
        -- CHARACTER
        ----------------------------------------------------------------

        local humanoid
        local myHRP

        ----------------------------------------------------------------
        -- STATE
        ----------------------------------------------------------------

        local frontlineLeftActive = false
        local frontlineLeftConnection = nil
        local targetPlayer = nil

        ----------------------------------------------------------------
        -- FORMATION SETTINGS
        ----------------------------------------------------------------

        local formationDistance = 5
        local formationSpacing = 3
        local stopThreshold = 1.5
        local formationHeight = 0

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

            local channel =
                TextChatService.TextChannels:FindFirstChild(
                    "RBXGeneral"
                )

            if not channel then
                warn(
                    "[FRONTLINE LEFT] RBXGeneral tidak ditemukan"
                )
                return
            end

            pcall(function()

                channel:SendAsync(message)

            end)

        end

        ----------------------------------------------------------------
        -- STOP FRONTLINE LEFT
        ----------------------------------------------------------------

        local function stopFrontlineLeft()

            frontlineLeftActive = false
            targetPlayer = nil

            if frontlineLeftConnection then

                frontlineLeftConnection:Disconnect()
                frontlineLeftConnection = nil

            end

            if humanoid then
                humanoid.AutoRotate = true
            end

            ----------------------------------------------------------------
            -- HANYA HAPUS ACTIVE MODE JIKA MODE INI
            ----------------------------------------------------------------

            if vars.ActiveMode == "frontlineleft" then
                vars.ActiveMode = nil
            end

        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        vars.ModeControllers.frontlineleft =
            stopFrontlineLeft

        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                vars.ModeControllers
            ) do

                if name ~= "frontlineleft"
                    and type(stopFunction) == "function"
                then

                    pcall(function()
                        stopFunction()
                    end)

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

            ----------------------------------------------------------------
            -- EXACT MATCH
            ----------------------------------------------------------------

            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if player.Name:lower() == name
                    or player.DisplayName:lower() == name
                then

                    return player

                end

            end

            ----------------------------------------------------------------
            -- PARTIAL MATCH
            ----------------------------------------------------------------

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
                    )
                then

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

            ----------------------------------------------------------------
            -- ADMIN DEFAULT
            ----------------------------------------------------------------

            if Admin:IsAdmin(player) then
                distance = 1
            end

            ----------------------------------------------------------------
            -- SPECIAL DISTANCE
            ----------------------------------------------------------------

            pcall(function()

                local specialDistance =
                    Distance:GetDistance(
                        tostring(LocalPlayer.UserId),
                        tostring(player.UserId)
                    )

                if typeof(specialDistance) == "number" then
                    distance = specialDistance
                end

            end)

            return distance

        end

        ----------------------------------------------------------------
        -- GET FRONTLINE LEFT POSITION
        ----------------------------------------------------------------
        --
        -- Posisi tetap DI DEPAN player.
        --
        -- B1 B2 B3 B4 B5 B6 B7 B8 B9 B10 B11
        --
        --                  PLAYER
        ----------------------------------------------------------------

        local function getFrontlinePosition(
            myIndex,
            targetHRP,
            distance
        )

            if not myIndex
                or not targetHRP
                or not distance
            then

                return nil

            end

            ----------------------------------------------------------------
            -- JUMLAH BOT
            ----------------------------------------------------------------

            local totalBots =
                #botOrder

            ----------------------------------------------------------------
            -- POSISI TENGAH
            ----------------------------------------------------------------

            local center =
                (totalBots + 1) / 2

            ----------------------------------------------------------------
            -- OFFSET KIRI / KANAN
            ----------------------------------------------------------------

            local horizontalOffset =
                (myIndex - center)
                * formationSpacing

            ----------------------------------------------------------------
            -- DEPAN PLAYER
            ----------------------------------------------------------------

            local frontPosition =
                targetHRP.Position
                +
                (
                    targetHRP.CFrame.LookVector
                    *
                    (
                        formationDistance
                        + distance
                    )
                )

            ----------------------------------------------------------------
            -- KIRI / KANAN
            ----------------------------------------------------------------

            local sidePosition =
                targetHRP.CFrame.RightVector
                *
                horizontalOffset

            ----------------------------------------------------------------
            -- FINAL POSITION
            ----------------------------------------------------------------

            return
                frontPosition
                +
                sidePosition
                +
                Vector3.new(
                    0,
                    formationHeight,
                    0
                )

        end

        ----------------------------------------------------------------
        -- FACE LEFT
        ----------------------------------------------------------------
        --
        -- Player menghadap:
        --
        --        DEPAN
        --          ↑
        --          |
        --
        -- LEFT ← PLAYER
        --
        -- Bot akan menghadap 90 derajat ke KIRI
        -- dari arah hadap player.
        ----------------------------------------------------------------

        local function faceLeft(targetHRP)

            if not targetHRP
                or not myHRP
            then

                return

            end

            ----------------------------------------------------------------
            -- ARAH KIRI DARI PLAYER
            ----------------------------------------------------------------

            local leftVector =
                -targetHRP.CFrame.RightVector

            ----------------------------------------------------------------
            -- BUAT CFrame MENGHADAP KIRI
            ----------------------------------------------------------------

            myHRP.CFrame =
                CFrame.lookAt(
                    myHRP.Position,
                    myHRP.Position + leftVector
                )

        end

        ----------------------------------------------------------------
        -- CONNECT FRONTLINE LEFT LOOP
        ----------------------------------------------------------------
        --
        -- Digunakan untuk:
        -- 1. Start awal
        -- 2. Respawn target
        -- 3. Respawn bot
        --
        -- Tidak memanggil startFrontlineLeft()
        -- sehingga Sync tidak ikut mati.
        ----------------------------------------------------------------

        local function connectFrontlineLeftLoop(myIndex)

            if frontlineLeftConnection then

                frontlineLeftConnection:Disconnect()
                frontlineLeftConnection = nil

            end

            if not myIndex then
                return
            end

            frontlineLeftConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- ACTIVE CHECK
                        ------------------------------------------------

                        if not frontlineLeftActive then
                            return
                        end

                        ------------------------------------------------
                        -- CHARACTER CHECK
                        ------------------------------------------------

                        if not humanoid
                            or not myHRP
                        then

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
                        -- POSITION
                        ------------------------------------------------

                        local targetPosition =
                            getFrontlinePosition(
                                myIndex,
                                targetHRP,
                                botDistance
                            )

                        if not targetPosition then
                            return
                        end

                        ------------------------------------------------
                        -- DISTANCE TO FORMATION
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
                            > stopThreshold
                        then

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
                        -- MENGHADAP KIRI
                        ------------------------------------------------

                        faceLeft(
                            targetHRP
                        )

                    end
                )

        end

        ----------------------------------------------------------------
        -- START FRONTLINE LEFT
        ----------------------------------------------------------------

        local function startFrontlineLeft(player)

            if not player then
                return
            end

            ----------------------------------------------------------------
            -- STOP MODE LAIN
            ----------------------------------------------------------------

            stopOtherModes()

            ----------------------------------------------------------------
            -- ACTIVE MODE
            ----------------------------------------------------------------

            vars.ActiveMode =
                "frontlineleft"

            ----------------------------------------------------------------
            -- DISCONNECT LOOP LAMA
            ----------------------------------------------------------------

            if frontlineLeftConnection then

                frontlineLeftConnection:Disconnect()
                frontlineLeftConnection = nil

            end

            ----------------------------------------------------------------
            -- STATE
            ----------------------------------------------------------------

            frontlineLeftActive = true
            targetPlayer = player

            ----------------------------------------------------------------
            -- FIND BOT INDEX
            ----------------------------------------------------------------

            local myIndex =
                table.find(
                    botOrder,
                    tostring(LocalPlayer.UserId)
                )

            ----------------------------------------------------------------
            -- BOT TIDAK ADA DI FRONTLINE
            ----------------------------------------------------------------

            if not myIndex then

                print(
                    "[FRONTLINE LEFT]",
                    "Bot ini bukan Bot 1-11:",
                    LocalPlayer.UserId
                )

                stopFrontlineLeft()

                return

            end

            ----------------------------------------------------------------
            -- CHAT
            ----------------------------------------------------------------

            sendChat("Yes, Sir!")

            ----------------------------------------------------------------
            -- DEBUG
            ----------------------------------------------------------------

            print(
                "[FRONTLINE LEFT]",
                "Bot Index:",
                myIndex,
                "UserId:",
                LocalPlayer.UserId
            )

            ----------------------------------------------------------------
            -- CONNECT LOOP
            ----------------------------------------------------------------

            connectFrontlineLeftLoop(
                myIndex
            )

        end

        ----------------------------------------------------------------
        -- HANDLE COMMAND
        ----------------------------------------------------------------

        local function handleCommand(
            message,
            sender
        )

            if not message then
                return
            end

            ----------------------------------------------------------------
            -- ADMIN ONLY
            ----------------------------------------------------------------

            if not sender then
                return
            end

            if not Admin:IsAdmin(sender) then
                return
            end

            local lower =
                message:lower()

            ----------------------------------------------------------------
            -- !FRONTLINELEFT <PLAYER>
            ----------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!frontlineleft%s+(.+)$"
                )

            if targetName then

                local target =
                    findPlayerByName(
                        targetName
                    )

                if target then

                    startFrontlineLeft(
                        target
                    )

                end

                return

            end

            ----------------------------------------------------------------
            -- !FRONTLINELEFT
            ----------------------------------------------------------------

            if lower == "!frontlineleft" then

                startFrontlineLeft(
                    sender
                )

                return

            end

            ----------------------------------------------------------------
            -- !STOP
            ----------------------------------------------------------------

            if lower == "!stop"
                or lower == "!unfrontlineleft"
            then

                stopFrontlineLeft()

                return

            end

        end

        ----------------------------------------------------------------
        -- TEXT CHAT SERVICE
        ----------------------------------------------------------------

        TextChatService.MessageReceived:Connect(
            function(message)

                if not message.TextSource then
                    return
                end

                local userId =
                    message.TextSource.UserId

                local sender =
                    Players:GetPlayerByUserId(
                        userId
                    )

                if not sender then
                    return
                end

                handleCommand(
                    message.Text,
                    sender
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

                ----------------------------------------------------------------
                -- RECONNECT FORMATION
                --
                -- Jangan gunakan startFrontlineLeft()
                -- karena akan menjalankan stopOtherModes()
                -- dan dapat menghentikan Sync.
                ----------------------------------------------------------------

                if frontlineLeftActive
                    and targetPlayer
                then

                    local myIndex =
                        table.find(
                            botOrder,
                            tostring(LocalPlayer.UserId)
                        )

                    if myIndex then

                        connectFrontlineLeftLoop(
                            myIndex
                        )

                    end

                end

            end
        )

        ----------------------------------------------------------------
        -- LOADED
        ----------------------------------------------------------------

        print(
            "[FRONTLINE LEFT] FrontlineLeft.lua aktif!"
        )

    end
}