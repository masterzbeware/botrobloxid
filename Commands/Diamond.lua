-- Administrator/Diamond.lua
-- Diamond Formation untuk VIP + 10 Bot
--
-- Command:
--   !diamond       -> Bot membentuk diamond mengelilingi target/admin
--   !stop          -> Menghentikan semua mode
--
-- Formasi:
--
--                    B1
--              B2          B3
--
--          B4                B5
--
--             B6    VIP    B7
--
--              B8          B9
--                    B10
--
-- Semua posisi mengikuti arah hadap VIP.
-- Jarak dibuat lebih rapat agar formasi terlihat compact.

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
        _G.BotVars.ModeControllers = _G.BotVars.ModeControllers or {}

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

        local diamonding = false
        local targetPlayer = nil
        local diamondConnection = nil

        ----------------------------------------------------------------
        -- DIAMOND SETTINGS
        ----------------------------------------------------------------
        --
        -- Angka kecil = formasi lebih rapat.
        -- Semua offset dihitung relatif terhadap VIP.
        --
        -- Forward  = arah depan VIP
        -- Right    = sisi kanan VIP
        --
        -- Posisi:
        --
        --                    B1
        --              B2          B3
        --          B4                B5
        --             B6    VIP    B7
        --              B8          B9
        --                    B10
        --
        ----------------------------------------------------------------

        local formationForward = 4.0
        local formationSide = 2.2
        local formationDepth = 2.0

        ----------------------------------------------------------------
        -- BOT ORDER
        ----------------------------------------------------------------

        local botOrder = {

            "11611503633", -- Bot 1
            "11611591921", -- Bot 2
            "11611597741", -- Bot 3
            "11672413029", -- Bot 4
            "11122806815", -- Bot 5
            "11122806817", -- Bot 6
            "11122687468", -- Bot 7
            "11122854402", -- Bot 8
            "11774472805", -- Bot 9
            "11774494628", -- Bot 10

        }

        ----------------------------------------------------------------
        -- DIAMOND OFFSETS
        ----------------------------------------------------------------
        --
        -- x = kiri/kanan
        -- z = depan/belakang
        --
        -- Posisi dibuat berdasarkan jumlah 10 bot.
        -- B1/B10 berada di ujung depan/belakang.
        -- B2-B9 membentuk sisi diamond.
        --
        ----------------------------------------------------------------

        local diamondPositions = {

            [1] = Vector3.new(0, 0, formationForward + formationDepth),
            [2] = Vector3.new(-formationSide, 0, formationForward),
            [3] = Vector3.new(formationSide, 0, formationForward),

            [4] = Vector3.new(
                -(formationSide * 1.65),
                0,
                formationDepth
            ),

            [5] = Vector3.new(
                formationSide * 1.65,
                0,
                formationDepth
            ),

            [6] = Vector3.new(
                -formationSide,
                0,
                0
            ),

            [7] = Vector3.new(
                formationSide,
                0,
                0
            ),

            [8] = Vector3.new(
                -formationSide,
                0,
                -formationForward
            ),

            [9] = Vector3.new(
                formationSide,
                0,
                -formationForward
            ),

            [10] = Vector3.new(
                0,
                0,
                -(formationForward + formationDepth)
            ),

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
                character:WaitForChild("HumanoidRootPart")

            humanoid.AutoRotate = true

        end

        updateCharacter()

        ----------------------------------------------------------------
        -- SEND CHAT
        ----------------------------------------------------------------

        local function sendChat(message)

            local success = false

            if TextChatService
                and TextChatService.TextChannels then

                local channel =
                    TextChatService.TextChannels:FindFirstChild(
                        "RBXGeneral"
                    )

                if channel then

                    pcall(function()
                        channel:SendAsync(message)
                    end)

                    success = true

                end
            end

            if not success then

                pcall(function()

                    local chatEvents =
                        ReplicatedStorage:FindFirstChild(
                            "DefaultChatSystemChatEvents"
                        )

                    if chatEvents then

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
                    end

                end)

            end

        end

        ----------------------------------------------------------------
        -- STOP DIAMOND
        ----------------------------------------------------------------

        local function stopDiamond()

            diamonding = false
            targetPlayer = nil

            if diamondConnection then

                diamondConnection:Disconnect()
                diamondConnection = nil

            end

            if humanoid then
                humanoid.AutoRotate = true
            end

        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.diamond = stopDiamond

        ----------------------------------------------------------------
        -- STOP SEMUA MODE LAIN
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "diamond"
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
        -- GET TARGET POSITION
        ----------------------------------------------------------------

        local function getFormationPosition(
            targetHRP,
            offset
        )

            -- Offset Z positif = depan VIP.
            -- Offset X positif = kanan VIP.

            return targetHRP.Position
                + (targetHRP.CFrame.RightVector * offset.X)
                + (targetHRP.CFrame.LookVector * offset.Z)

        end

        ----------------------------------------------------------------
        -- START DIAMOND
        ----------------------------------------------------------------

        local function startDiamond(player)

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

            _G.BotVars.ActiveMode = "diamond"

            ------------------------------------------------------------
            -- STOP CONNECTION LAMA
            ------------------------------------------------------------

            if diamondConnection then

                diamondConnection:Disconnect()
                diamondConnection = nil

            end

            diamonding = true
            targetPlayer = player

            _G.BotVars.CommandTarget = player

            sendChat("Yes, Sir!")

            ------------------------------------------------------------
            -- CARI INDEX BOT
            ------------------------------------------------------------

            local myIndex =
                table.find(
                    botOrder,
                    tostring(LocalPlayer.UserId)
                )

            if not myIndex then

                stopDiamond()

                return

            end

            ------------------------------------------------------------
            -- AMBIL OFFSET BOT
            ------------------------------------------------------------

            local myOffset =
                diamondPositions[myIndex]

            if not myOffset then

                stopDiamond()

                return

            end

            ------------------------------------------------------------
            -- DIAMOND LOOP
            ------------------------------------------------------------

            diamondConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- JIKA MODE SUDAH BERGANTI
                        ------------------------------------------------

                        if _G.BotVars.ActiveMode ~= "diamond" then

                            stopDiamond()

                            return

                        end

                        ------------------------------------------------
                        -- VALIDASI
                        ------------------------------------------------

                        if not diamonding then
                            return
                        end

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
                        -- FORMATION POSITION
                        ------------------------------------------------

                        local targetPosition =
                            getFormationPosition(
                                targetHRP,
                                myOffset
                            )

                        ------------------------------------------------
                        -- JARAK KE POSISI FORMASI
                        ------------------------------------------------

                        local distanceToTarget =
                            (
                                myHRP.Position
                                - targetPosition
                            ).Magnitude

                        ------------------------------------------------
                        -- JALAN MENUJU POSISI
                        ------------------------------------------------

                        if distanceToTarget > 1.5 then

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

                        -- Semua bot menghadap arah yang sama
                        -- dengan VIP.

                        local targetRotation =
                            targetHRP.CFrame
                            - targetHRP.Position

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

            if not message or not sender then
                return
            end

            local isAdmin = false

            pcall(function()
                isAdmin = Admin:IsAdmin(sender)
            end)

            local lower =
                message
                :lower()
                :gsub("^%s+", "")
                :gsub("%s+$", "")

            local commandTarget =
                _G.BotVars.CommandTarget

            ------------------------------------------------------------
            -- !STOP
            --
            -- Hanya admin yang boleh menghentikan formasi.
            ------------------------------------------------------------

            if lower == "!stop" then

                if not isAdmin then
                    return
                end

                _G.BotVars.ActiveMode = nil
                _G.BotVars.CommandTarget = nil

                for _, stopFunction in pairs(
                    _G.BotVars.ModeControllers
                ) do

                    if type(stopFunction) == "function" then

                        pcall(stopFunction)

                    end

                end

                return

            end

            ------------------------------------------------------------
            -- !DIAMOND
            --
            -- Admin dapat menjalankan diamond kapan saja.
            --
            -- Target yang sedang aktif juga dapat mengetik
            -- !diamond untuk mengaktifkan kembali formasi dirinya.
            ------------------------------------------------------------

            if lower == "!diamond" then

                if not isAdmin
                    and sender ~= commandTarget then

                    return

                end

                _G.BotVars.CommandTarget = sender

                startDiamond(sender)

                return

            end

            ------------------------------------------------------------
            -- !DIAMOND PLAYER
            --
            -- Hanya admin yang boleh menentukan target lain.
            --
            ------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!diamond%s+(.+)$"
                )

            if targetName then

                if not isAdmin then
                    return
                end

                local target =
                    findPlayerByName(
                        targetName
                    )

                if target then

                    _G.BotVars.CommandTarget = target

                    startDiamond(target)

                end

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

                channel.MessageReceived:Connect(
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
                )

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

                if _G.BotVars.ActiveMode == "diamond"
                    and targetPlayer then

                    startDiamond(
                        targetPlayer
                    )

                end

            end
        )

    end
}
