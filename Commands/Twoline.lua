return {
    Execute = function()

        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            return
        end

        ------------------------------------------------------------
        -- LOAD ADMIN MODULE
        ------------------------------------------------------------

        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        ------------------------------------------------------------
        -- LOAD DISTANCE MODULE
        ------------------------------------------------------------

        local Distance = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Distance.lua"
        ))()

        ------------------------------------------------------------
        -- VARIABLES
        ------------------------------------------------------------

        local humanoid
        local myHRP

        local following = false
        local targetPlayer = nil
        local followConnection = nil

        ------------------------------------------------------------
        -- DISTANCE CONFIG
        ------------------------------------------------------------

        -- Jarak antar baris
        local adminFollowDistance = 3

        -- Default jika target bukan Admin
        local defaultBotFollowDistance = 2

        -- Jarak kiri / kanan
        local sideSpacing = 2.5

        ------------------------------------------------------------
        -- FORMATION CONFIG
        ------------------------------------------------------------

        -- Jarak maksimal sebelum bot dianggap sudah sampai
        local stopThreshold = 1.5

        ------------------------------------------------------------
        -- BOT ORDER
        --
        -- Urutan:
        --
        -- BOT 1    BOT 2
        -- BOT 3    BOT 4
        -- BOT 5    BOT 6
        -- BOT 7    BOT 8
        -- BOT 9
        --
        ------------------------------------------------------------

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

        ------------------------------------------------------------
        -- UPDATE CHARACTER
        ------------------------------------------------------------

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

        ------------------------------------------------------------
        -- SEND CHAT
        ------------------------------------------------------------

        local function sendChat(msg)

            local success = false

            --------------------------------------------------------
            -- TEXT CHAT
            --------------------------------------------------------

            if TextChatService
                and TextChatService.TextChannels then

                local channel =
                    TextChatService.TextChannels:FindFirstChild(
                        "RBXGeneral"
                    )

                if channel then

                    pcall(function()
                        channel:SendAsync(msg)
                    end)

                    success = true

                end

            end

            --------------------------------------------------------
            -- LEGACY CHAT FALLBACK
            --------------------------------------------------------

            if not success then

                pcall(function()

                    ReplicatedStorage
                        .DefaultChatSystemChatEvents
                        .SayMessageRequest
                        :FireServer(
                            msg,
                            "All"
                        )

                end)

            end

        end

        ------------------------------------------------------------
        -- STOP FOLLOW
        ------------------------------------------------------------

        local function stopFollow()

            following = false
            targetPlayer = nil

            --------------------------------------------------------
            -- HENTIKAN CONNECTION
            --------------------------------------------------------

            if followConnection then

                followConnection:Disconnect()
                followConnection = nil

            end

            --------------------------------------------------------
            -- KEMBALIKAN AUTOROTATE
            --------------------------------------------------------

            if humanoid then

                humanoid.AutoRotate = true

            end

        end

        ------------------------------------------------------------
        -- FIND PLAYER BY NAME / DISPLAY NAME
        ------------------------------------------------------------

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

        ------------------------------------------------------------
        -- START TWO COLUMN FOLLOW
        ------------------------------------------------------------

        local function startFollow(player)

            if not player then
                return
            end

            --------------------------------------------------------
            -- HENTIKAN FOLLOW LAMA
            --------------------------------------------------------

            if followConnection then

                followConnection:Disconnect()
                followConnection = nil

            end

            --------------------------------------------------------
            -- SET TARGET
            --------------------------------------------------------

            following = true
            targetPlayer = player

            sendChat("Yes, Sir!")

            --------------------------------------------------------
            -- CARI INDEX BOT
            --------------------------------------------------------

            local myIndex =
                table.find(
                    botOrder,
                    tostring(LocalPlayer.UserId)
                )

            --------------------------------------------------------
            -- BUKAN BOT
            --------------------------------------------------------

            if not myIndex then

                following = false
                targetPlayer = nil

                return

            end

            --------------------------------------------------------
            -- HITUNG POSISI DALAM 2 KOLOM
            --------------------------------------------------------
            --
            -- Index:
            --
            -- 1  2
            -- 3  4
            -- 5  6
            -- 7  8
            -- 9
            --
            --------------------------------------------------------

            local column
            local row

            if myIndex % 2 == 1 then

                -- KIRI

                column = -1

                row =
                    math.ceil(
                        myIndex / 2
                    )

            else

                -- KANAN

                column = 1

                row =
                    myIndex / 2

            end

            --------------------------------------------------------
            -- FOLLOW LOOP
            --------------------------------------------------------

            followConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ------------------------------------------------
                        -- VALIDASI
                        ------------------------------------------------

                        if not following then
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

                        local distance =
                            defaultBotFollowDistance

                        ------------------------------------------------
                        -- JIKA TARGET ADMIN
                        ------------------------------------------------

                        if Admin:IsAdmin(targetPlayer) then

                            distance =
                                adminFollowDistance

                        end

                        ------------------------------------------------
                        -- SPECIAL DISTANCE
                        ------------------------------------------------

                        local specialDistance =
                            Distance:GetDistance(
                                tostring(
                                    LocalPlayer.UserId
                                ),
                                tostring(
                                    targetPlayer.UserId
                                )
                            )

                        if specialDistance then

                            distance =
                                specialDistance

                        end

                        ------------------------------------------------
                        -- HITUNG OFFSET BELAKANG
                        ------------------------------------------------
                        --
                        -- Row 1 = 3 stud
                        -- Row 2 = 6 stud
                        -- Row 3 = 9 stud
                        -- dst.
                        --
                        ------------------------------------------------

                        local backOffset =
                            targetHRP.CFrame.LookVector
                            *
                            -(
                                distance * row
                            )

                        ------------------------------------------------
                        -- HITUNG OFFSET KIRI / KANAN
                        ------------------------------------------------

                        local sideOffset =
                            targetHRP.CFrame.RightVector
                            *
                            (
                                sideSpacing * column
                            )

                        ------------------------------------------------
                        -- POSISI TUJUAN BOT
                        ------------------------------------------------

                        local targetPosition =
                            targetHRP.Position
                            +
                            backOffset
                            +
                            sideOffset

                        ------------------------------------------------
                        -- JARAK BOT KE POSISI TUJUAN
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

                            ------------------------------------------------
                            -- AUTOROTATE AKTIF SAAT BERJALAN
                            ------------------------------------------------

                            humanoid.AutoRotate = true

                            ------------------------------------------------
                            -- JALAN MENUJU FORMASI
                            ------------------------------------------------

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
                        -- SAMAKAN ROTASI DENGAN ADMIN
                        ------------------------------------------------

                        local adminRotation =
                            targetHRP.CFrame
                            -
                            targetHRP.Position

                        myHRP.CFrame =
                            CFrame.new(
                                myHRP.Position
                            )
                            *
                            adminRotation

                    end
                )

        end

        ------------------------------------------------------------
        -- COMMAND HANDLER
        ------------------------------------------------------------

        local function handleCommand(
            msg,
            sender
        )

            --------------------------------------------------------
            -- HANYA ADMIN
            --------------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end

            local lower =
                msg:lower()

            --------------------------------------------------------
            -- !TWOLINE
            --------------------------------------------------------

            if lower == "!twoline" then

                startFollow(sender)

                return

            end

            --------------------------------------------------------
            -- !TWOLINE <NAME>
            --------------------------------------------------------

            local targetName =
                lower:match(
                    "^!twoline%s+(.+)$"
                )

            if targetName then

                local target =
                    findPlayerByName(
                        targetName
                    )

                if target then

                    startFollow(target)

                end

                return

            end

            --------------------------------------------------------
            -- !STOP
            --------------------------------------------------------

            if lower == "!stop"
                or lower == "!unfollow" then

                stopFollow()

                return

            end

        end

        ------------------------------------------------------------
        -- TEXT CHAT SERVICE
        ------------------------------------------------------------

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

        ------------------------------------------------------------
        -- FALLBACK CHAT
        ------------------------------------------------------------

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

        ------------------------------------------------------------
        -- PLAYER ADDED
        ------------------------------------------------------------

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

        ------------------------------------------------------------
        -- CHARACTER RESPAWN
        ------------------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(
            function()

                task.wait(1)

                updateCharacter()

                ------------------------------------------------
                -- LANJUTKAN FOLLOW SETELAH RESPAWN
                ------------------------------------------------

                if following
                    and targetPlayer then

                    startFollow(
                        targetPlayer
                    )

                end

            end
        )

    end
}