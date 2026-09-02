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
        -- LOAD MODULES
        ----------------------------------------------------------------

        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        local Distance = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
        ))()

        ----------------------------------------------------------------
        -- STATE
        ----------------------------------------------------------------

        local positioning = false
        local targetPlayer = nil
        local followConnection = nil

        local humanoid = nil
        local myHRP = nil

        local hasChatted = false

        ----------------------------------------------------------------
        -- DISTANCE CONFIG
        ----------------------------------------------------------------

        -- Jarak baris pertama dari Admin
        local adminFrontDistance = 3

        -- Jarak default jika target bukan Admin
        local defaultBotFrontDistance = 2

        ----------------------------------------------------------------
        -- FORMATION CONFIG
        ----------------------------------------------------------------

        -- Jarak antar Bot kiri-kanan
        local sideSpacing = 3

        -- Jarak antar baris
        local rowSpacing = 3

        ----------------------------------------------------------------
        -- JUMLAH KOLOM
        ----------------------------------------------------------------

        local columns = 3

        ----------------------------------------------------------------
        -- BATAS BOT
        ----------------------------------------------------------------

        local stopThreshold = 1.5

        ----------------------------------------------------------------
        -- BOT ORDER
        --
        -- FORMASI:
        --
        -- BOT 1   BOT 2   BOT 3
        -- BOT 4   BOT 5   BOT 6
        -- BOT 7   BOT 8   BOT 9
        --
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

            "11122806815", -- Bot 10
            "11122806817", -- Bot 11
            "11122687468", -- Bot 12
            "11122854402", -- Bot 13
        }

        ----------------------------------------------------------------
        -- UPDATE CHARACTER
        ----------------------------------------------------------------

        local function updateCharacter()

            local char =
                LocalPlayer.Character
                or LocalPlayer.CharacterAdded:Wait()

            humanoid =
                char:WaitForChild("Humanoid")

            myHRP =
                char:WaitForChild("HumanoidRootPart")

            humanoid.AutoRotate = true

        end

        updateCharacter()

        ----------------------------------------------------------------
        -- SEND CHAT
        ----------------------------------------------------------------

        local function sendChat(msg)

            pcall(function()

                --------------------------------------------------------
                -- TEXT CHAT
                --------------------------------------------------------

                if TextChatService
                    and TextChatService.TextChannels then

                    local ch =
                        TextChatService.TextChannels:FindFirstChild(
                            "RBXGeneral"
                        )

                    if ch then

                        ch:SendAsync(msg)

                        return

                    end

                end

                --------------------------------------------------------
                -- LEGACY CHAT
                --------------------------------------------------------

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
                            msg,
                            "All"
                        )

                    end

                end

            end)

        end

        ----------------------------------------------------------------
        -- STOP THREELINE
        ----------------------------------------------------------------

        local function stopThreeline()

            positioning = false
            targetPlayer = nil
            hasChatted = false

            ------------------------------------------------------------
            -- DISCONNECT FOLLOW LOOP
            ------------------------------------------------------------

            if followConnection then

                followConnection:Disconnect()
                followConnection = nil

            end

            ------------------------------------------------------------
            -- KEMBALIKAN AUTOROTATE
            ------------------------------------------------------------

            if humanoid then

                humanoid.AutoRotate = true

            end

        end

        ----------------------------------------------------------------
        -- FIND PLAYER BY NAME / DISPLAY NAME
        ----------------------------------------------------------------

        local function findPlayerByName(name)

            name = name:lower()

            for _, p in ipairs(
                Players:GetPlayers()
            ) do

                if p.Name:lower() == name
                    or p.DisplayName:lower() == name then

                    return p

                end

            end

            return nil

        end

        ----------------------------------------------------------------
        -- START THREELINE
        ----------------------------------------------------------------

        local function startThreeline(player)

            if not player then
                return
            end

            ------------------------------------------------------------
            -- STOP CONNECTION LAMA
            ------------------------------------------------------------

            if followConnection then

                followConnection:Disconnect()
                followConnection = nil

            end

            ------------------------------------------------------------
            -- SET STATE
            ------------------------------------------------------------

            positioning = true
            targetPlayer = player
            hasChatted = false

            ------------------------------------------------------------
            -- CARI INDEX BOT
            ------------------------------------------------------------

            local myIndex =
                table.find(
                    botOrder,
                    tostring(LocalPlayer.UserId)
                )

            ------------------------------------------------------------
            -- JIKA BUKAN BOT
            ------------------------------------------------------------

            if not myIndex then

                positioning = false
                targetPlayer = nil

                return

            end

            ------------------------------------------------------------
            -- HITUNG BARIS
            --
            -- 1 2 3 = Row 1
            -- 4 5 6 = Row 2
            -- 7 8 9 = Row 3
            ------------------------------------------------------------

            local row =
                math.ceil(
                    myIndex / columns
                )

            ------------------------------------------------------------
            -- HITUNG KOLOM
            --
            -- 1 = kiri
            -- 2 = tengah
            -- 3 = kanan
            ------------------------------------------------------------

            local column =
                ((myIndex - 1) % columns) + 1

            ------------------------------------------------------------
            -- HITUNG POSISI KIRI / KANAN
            --
            -- Column 1 = -3
            -- Column 2 =  0
            -- Column 3 = +3
            --
            ------------------------------------------------------------

            local horizontalOffset =
                (
                    column
                    -
                    ((columns + 1) / 2)
                )
                *
                sideSpacing

            ----------------------------------------------------------------
            -- FOLLOW LOOP
            ----------------------------------------------------------------

            followConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- VALIDASI STATE
                        ------------------------------------------------

                        if not positioning then
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

                        ------------------------------------------------
                        -- TARGET HUMANOID ROOT PART
                        ------------------------------------------------

                        local hrp =
                            targetCharacter:FindFirstChild(
                                "HumanoidRootPart"
                            )

                        if not hrp then
                            return
                        end

                        ------------------------------------------------
                        -- DISTANCE DASAR
                        ------------------------------------------------

                        local distance =
                            defaultBotFrontDistance

                        ------------------------------------------------
                        -- JIKA TARGET ADALAH ADMIN
                        ------------------------------------------------

                        if Admin:IsAdmin(
                            targetPlayer
                        ) then

                            distance =
                                adminFrontDistance

                        end

                        ------------------------------------------------
                        -- SPECIAL DISTANCE
                        ------------------------------------------------

                        local special =
                            Distance:GetDistance(
                                tostring(
                                    LocalPlayer.UserId
                                ),
                                tostring(
                                    targetPlayer.UserId
                                )
                            )

                        if special then

                            distance =
                                special

                        end

                        ------------------------------------------------
                        -- HITUNG JARAK DEPAN
                        --
                        -- Row 1 = 3 studs
                        -- Row 2 = 6 studs
                        -- Row 3 = 9 studs
                        --
                        ------------------------------------------------

                        local forwardDistance =
                            distance
                            +
                            ((row - 1) * rowSpacing)

                        ------------------------------------------------
                        -- ARAH DEPAN ADMIN
                        ------------------------------------------------

                        local forwardOffset =
                            hrp.CFrame.LookVector
                            *
                            forwardDistance

                        ------------------------------------------------
                        -- ARAH KIRI / KANAN ADMIN
                        ------------------------------------------------

                        local sideOffset =
                            hrp.CFrame.RightVector
                            *
                            horizontalOffset

                        ------------------------------------------------
                        -- POSISI AKHIR
                        ------------------------------------------------

                        local targetPosition =
                            hrp.Position
                            +
                            forwardOffset
                            +
                            sideOffset

                        ------------------------------------------------
                        -- CHAT SEKALI
                        ------------------------------------------------

                        if not hasChatted then

                            sendChat(
                                "Yes, Sir!"
                            )

                            hasChatted = true

                        end

                        ------------------------------------------------
                        -- HITUNG JARAK BOT KE POSISI
                        ------------------------------------------------

                        local distanceToTarget =
                            (
                                myHRP.Position
                                -
                                targetPosition
                            ).Magnitude

                        ------------------------------------------------
                        -- BOT MASIH JAUH
                        ------------------------------------------------

                        if distanceToTarget > stopThreshold then

                            humanoid.AutoRotate = true

                            humanoid:MoveTo(
                                targetPosition
                            )

                            return

                        end

                        ------------------------------------------------
                        -- BOT SUDAH SAMPAI
                        ------------------------------------------------

                        humanoid.AutoRotate = false

                        ------------------------------------------------
                        -- SAMAKAN ARAH DENGAN ADMIN
                        ------------------------------------------------

                        local adminRotation =
                            hrp.CFrame
                            -
                            hrp.Position

                        myHRP.CFrame =
                            CFrame.new(
                                myHRP.Position
                            )
                            *
                            adminRotation

                    end
                )

        end

        ----------------------------------------------------------------
        -- COMMAND HANDLER
        ----------------------------------------------------------------

        local function handleCommand(
            msg,
            sender
        )

            ------------------------------------------------------------
            -- ADMIN ONLY
            ------------------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end

            local lower =
                msg:lower()

            ------------------------------------------------------------
            -- !THREELINE
            ------------------------------------------------------------

            if lower == "!threeline" then

                startThreeline(
                    sender
                )

                return

            end

            ------------------------------------------------------------
            -- !THREELINE <NAME>
            ------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!threeline%s+(.+)$"
                )

            if targetName then

                local target =
                    findPlayerByName(
                        targetName
                    )

                if target then

                    startThreeline(
                        target
                    )

                end

                return

            end

            ------------------------------------------------------------
            -- STOP
            ------------------------------------------------------------

            if lower == "!stop"
                or lower == "!unthreeline" then

                stopThreeline()

            end

        end

        ----------------------------------------------------------------
        -- TEXT CHAT SERVICE
        ----------------------------------------------------------------

        if TextChatService
            and TextChatService.TextChannels then

            local ch =
                TextChatService.TextChannels:FindFirstChild(
                    "RBXGeneral"
                )

            if ch then

                ch.OnIncomingMessage =
                    function(message)

                        local uid =
                            message.TextSource
                            and message.TextSource.UserId

                        local sender =
                            uid
                            and Players:GetPlayerByUserId(
                                uid
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

        for _, p in ipairs(
            Players:GetPlayers()
        ) do

            p.Chatted:Connect(
                function(msg)

                    handleCommand(
                        msg,
                        p
                    )

                end
            )

        end

        ----------------------------------------------------------------
        -- PLAYER ADDED
        ----------------------------------------------------------------

        Players.PlayerAdded:Connect(
            function(p)

                p.Chatted:Connect(
                    function(msg)

                        handleCommand(
                            msg,
                            p
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
                -- JIKA SEBELUMNYA SEDANG THREELINE
                --------------------------------------------------------

                if positioning
                    and targetPlayer then

                    startThreeline(
                        targetPlayer
                    )

                end

            end
        )

    end
}
