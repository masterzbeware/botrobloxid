
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
        -- LOAD ADMIN
        ------------------------------------------------------------

        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        ------------------------------------------------------------
        -- LOAD DISTANCE
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
        -- DISTANCE
        ------------------------------------------------------------

        local adminFollowDistance = 3
        local defaultBotFollowDistance = 2

        ------------------------------------------------------------
        -- BOT ORDER
        -- URUTAN DARI PALING DEPAN KE PALING BELAKANG
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

        local function sendChat(message)

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
                        channel:SendAsync(message)
                    end)

                    success = true

                end
            end

            --------------------------------------------------------
            -- LEGACY CHAT
            --------------------------------------------------------

            if not success then

                pcall(function()

                    ReplicatedStorage
                        .DefaultChatSystemChatEvents
                        .SayMessageRequest
                        :FireServer(
                            message,
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
        -- FIND PLAYER
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
        -- START FOLLOW
        ------------------------------------------------------------

        local function startFollow(player)

            if not player then
                return
            end

            --------------------------------------------------------
            -- HAPUS FOLLOW LOOP SEBELUMNYA
            --------------------------------------------------------

            if followConnection then

                followConnection:Disconnect()
                followConnection = nil

            end

            --------------------------------------------------------
            -- SET TARGET
            --------------------------------------------------------

            targetPlayer = player
            following = true

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
            -- FOLLOW LOOP
            --------------------------------------------------------

            followConnection =
                RunService.Heartbeat:Connect(function()

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
                    -- ADMIN CHARACTER
                    ------------------------------------------------

                    local targetCharacter =
                        targetPlayer.Character

                    if not targetCharacter then
                        return
                    end

                    ------------------------------------------------
                    -- ADMIN HRP
                    ------------------------------------------------

                    local targetHRP =
                        targetCharacter:FindFirstChild(
                            "HumanoidRootPart"
                        )

                    if not targetHRP then
                        return
                    end

                    ------------------------------------------------
                    -- JARAK ANTAR BOT
                    ------------------------------------------------

                    local distance =
                        defaultBotFollowDistance

                    ------------------------------------------------
                    -- KALAU TARGET ADMIN
                    ------------------------------------------------

                    if Admin:IsAdmin(targetPlayer) then

                        distance =
                            adminFollowDistance

                    end

                    ------------------------------------------------
                    -- CEK DISTANCE KHUSUS
                    ------------------------------------------------

                    local specialDistance =
                        Distance:GetDistance(
                            tostring(LocalPlayer.UserId),
                            tostring(targetPlayer.UserId)
                        )

                    if specialDistance then

                        distance =
                            specialDistance

                    end

                    ------------------------------------------------
                    -- HITUNG POSISI BOT
                    ------------------------------------------------
                    --
                    -- Admin
                    --   ↓
                    -- Bot 1 = 3
                    -- Bot 2 = 6
                    -- Bot 3 = 9
                    -- dst.
                    --
                    ------------------------------------------------

                    local targetPosition =
                        targetHRP.Position
                        -
                        (
                            targetHRP.CFrame.LookVector
                            *
                            (distance * myIndex)
                        )

                    ------------------------------------------------
                    -- HITUNG JARAK BOT KE TARGET
                    ------------------------------------------------

                    local distanceToTarget =
                        (
                            myHRP.Position
                            -
                            targetPosition
                        ).Magnitude

                    ------------------------------------------------
                    -- BOT JAUH DARI ADMIN
                    ------------------------------------------------

                    if distanceToTarget > 1.5 then

                        ------------------------------------------------
                        -- AUTOROTATE AKTIF
                        ------------------------------------------------

                        humanoid.AutoRotate = true

                        ------------------------------------------------
                        -- SURUH BOT BERJALAN
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
                    -- SAMAKAN ARAH DENGAN ADMIN
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

                end)

        end

        ------------------------------------------------------------
        -- COMMAND HANDLER
        ------------------------------------------------------------

        local function handleCommand(
            message,
            sender
        )

            --------------------------------------------------------
            -- HANYA ADMIN YANG BOLEH
            --------------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end

            local lower =
                message:lower()

            --------------------------------------------------------
            -- !FOLLOW
            --------------------------------------------------------

            if lower == "!follow" then

                startFollow(sender)

                return
            end

            --------------------------------------------------------
            -- !FOLLOW PLAYER
            --------------------------------------------------------

            local targetName =
                lower:match(
                    "^!follow%s+(.+)$"
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
        -- TEXT CHAT
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
        -- LEGACY CHAT
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
        -- RESPawn
        ------------------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(
            function()

                task.wait(1)

                updateCharacter()

                ------------------------------------------------
                -- FOLLOW AKAN TETAP BERJALAN
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
