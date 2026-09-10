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
        -- VARIABLES
        ----------------------------------------------------------------

        local humanoid
        local myHRP

        local following = false
        local targetPlayer = nil
        local followConnection = nil

        ----------------------------------------------------------------
        -- DISTANCE
        ----------------------------------------------------------------

        local adminFollowDistance = 3
        local defaultBotFollowDistance = 2

        ----------------------------------------------------------------
        -- TWOLINE CONFIG
        ----------------------------------------------------------------

        -- Jarak antar bot kiri dan kanan
        local sideSpacing = 2.5

        -- Jarak minimum sebelum bot berhenti
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

            if not message then
                return
            end

            local success = false

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

                    pcall(function()

                        channel:SendAsync(message)

                    end)

                    success = true

                end

            end

            ----------------------------------------------------------------
            -- OLD CHAT FALLBACK
            ----------------------------------------------------------------

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
        -- STOP TWOLINE
        ----------------------------------------------------------------

        local function stopTwoline()

            following = false
            targetPlayer = nil

            if followConnection then

                followConnection:Disconnect()
                followConnection = nil

            end

            if humanoid then

                humanoid.AutoRotate = true

            end

            ----------------------------------------------------------------
            -- HANYA CLEAR ACTIVE MODE JIKA MEMANG TWOLINE
            ----------------------------------------------------------------

            if vars.ActiveMode == "twoline" then
                vars.ActiveMode = nil
            end

        end

        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        vars.ModeControllers.twoline =
            stopTwoline

        ----------------------------------------------------------------
        -- STOP SEMUA MODE LAIN
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                vars.ModeControllers
            ) do

                if name ~= "twoline"
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

            ----------------------------------------------------------------
            -- EXACT MATCH
            ----------------------------------------------------------------

            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if player.Name:lower() == name
                    or player.DisplayName:lower() == name then

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
                    ) then

                    return player

                end

            end

            return nil

        end

        ----------------------------------------------------------------
        -- CONNECT TWOLINE LOOP
        ----------------------------------------------------------------
        -- Digunakan untuk start awal dan respawn.
        --
        -- Fungsi ini TIDAK memanggil stopOtherModes().
        -- Jadi reconnect setelah respawn tidak akan menghentikan Sync.

        local function connectTwolineLoop(myIndex)

            ----------------------------------------------------------------
            -- DISCONNECT CONNECTION LAMA
            ----------------------------------------------------------------

            if followConnection then

                followConnection:Disconnect()
                followConnection = nil

            end

            if not myIndex then
                return
            end

            ----------------------------------------------------------------
            -- TWOLINE HEARTBEAT
            ----------------------------------------------------------------

            followConnection =
                RunService.Heartbeat:Connect(
                    function()

                        ----------------------------------------------------------------
                        -- ACTIVE CHECK
                        ----------------------------------------------------------------
                        -- Jangan cek vars.ActiveMode di sini.
                        --
                        -- Sync menggunakan ActiveMode = "sync",
                        -- tetapi Twoline tetap harus berjalan.
                        ----------------------------------------------------------------

                        if not following then
                            return
                        end

                        ----------------------------------------------------------------
                        -- VALIDASI CHARACTER
                        ----------------------------------------------------------------

                        if not humanoid
                            or not myHRP then

                            return

                        end

                        ----------------------------------------------------------------
                        -- VALIDASI TARGET
                        ----------------------------------------------------------------

                        if not targetPlayer then
                            return
                        end

                        ----------------------------------------------------------------
                        -- TARGET CHARACTER
                        ----------------------------------------------------------------

                        local targetCharacter =
                            targetPlayer.Character

                        if not targetCharacter then
                            return
                        end

                        ----------------------------------------------------------------
                        -- TARGET HRP
                        ----------------------------------------------------------------

                        local targetHRP =
                            targetCharacter:FindFirstChild(
                                "HumanoidRootPart"
                            )

                        if not targetHRP then
                            return
                        end

                        ----------------------------------------------------------------
                        -- DISTANCE
                        ----------------------------------------------------------------
                        -- SAMA SEPERTI FOLLOW.LUA
                        ----------------------------------------------------------------

                        local distance =
                            defaultBotFollowDistance

                        if Admin:IsAdmin(targetPlayer) then

                            distance =
                                adminFollowDistance

                        end

                        ----------------------------------------------------------------
                        -- SPECIAL DISTANCE
                        ----------------------------------------------------------------
                        -- SAMA SEPERTI FOLLOW.LUA
                        ----------------------------------------------------------------

                        local specialDistance =
                            Distance:GetDistance(
                                tostring(LocalPlayer.UserId),
                                tostring(targetPlayer.UserId)
                            )

                        if specialDistance then

                            distance =
                                specialDistance

                        end

                        ----------------------------------------------------------------
                        -- HITUNG BARIS
                        ----------------------------------------------------------------

                        local row =
                            math.ceil(myIndex / 2)

                        ----------------------------------------------------------------
                        -- HITUNG SISI
                        ----------------------------------------------------------------

                        local side

                        if myIndex % 2 == 1 then

                            -- BOT GANJIL = KIRI
                            side = -1

                        else

                            -- BOT GENAP = KANAN
                            side = 1

                        end

                        ----------------------------------------------------------------
                        -- POSISI BELAKANG
                        ----------------------------------------------------------------
                        -- KONSEP SAMA DENGAN FOLLOW.LUA
                        ----------------------------------------------------------------

                        local backDistance =
                            distance * row

                        local backOffset =
                            targetHRP.CFrame.LookVector
                            * -backDistance

                        ----------------------------------------------------------------
                        -- POSISI KIRI / KANAN
                        ----------------------------------------------------------------

                        local sideOffset =
                            targetHRP.CFrame.RightVector
                            * (sideSpacing * side)

                        ----------------------------------------------------------------
                        -- POSISI AKHIR
                        ----------------------------------------------------------------

                        local targetPosition =
                            targetHRP.Position
                            + backOffset
                            + sideOffset

                        ----------------------------------------------------------------
                        -- JARAK BOT KE POSISI
                        ----------------------------------------------------------------

                        local distanceToTarget =
                            (
                                myHRP.Position
                                - targetPosition
                            ).Magnitude

                        ----------------------------------------------------------------
                        -- JALAN
                        ----------------------------------------------------------------

                        if distanceToTarget > stopThreshold then

                            humanoid.AutoRotate = true

                            humanoid:MoveTo(
                                targetPosition
                            )

                            return

                        end

                        ----------------------------------------------------------------
                        -- SUDAH SAMPAI
                        ----------------------------------------------------------------

                        humanoid.AutoRotate = false

                        ----------------------------------------------------------------
                        -- ROTASI SAMA SEPERTI FOLLOW.LUA
                        ----------------------------------------------------------------

                        local adminRotation =
                            targetHRP.CFrame
                            - targetHRP.Position

                        myHRP.CFrame =
                            CFrame.new(
                                myHRP.Position
                            )
                            * adminRotation

                    end
                )

        end

        ----------------------------------------------------------------
        -- START TWOLINE
        ----------------------------------------------------------------

        local function startTwoline(player)

            if not player then
                return
            end

            ----------------------------------------------------------------
            -- STOP MODE LAIN
            ----------------------------------------------------------------

            stopOtherModes()

            ----------------------------------------------------------------
            -- SET ACTIVE MODE
            ----------------------------------------------------------------

            vars.ActiveMode = "twoline"

            ----------------------------------------------------------------
            -- STATE
            ----------------------------------------------------------------

            following = true
            targetPlayer = player

            ----------------------------------------------------------------
            -- CHAT
            ----------------------------------------------------------------

            sendChat("Yes, Sir!")

            ----------------------------------------------------------------
            -- CARI INDEX BOT
            ----------------------------------------------------------------

            local myIndex =
                table.find(
                    botOrder,
                    tostring(LocalPlayer.UserId)
                )

            ----------------------------------------------------------------
            -- BOT TIDAK TERDAFTAR
            ----------------------------------------------------------------

            if not myIndex then

                print(
                    "[TWOLINE] Bot tidak termasuk formasi:",
                    LocalPlayer.Name,
                    LocalPlayer.UserId
                )

                stopTwoline()

                return

            end

            ----------------------------------------------------------------
            -- DEBUG
            ----------------------------------------------------------------

            print(
                "[TWOLINE]",
                "Bot Index:",
                myIndex,
                "UserId:",
                LocalPlayer.UserId
            )

            ----------------------------------------------------------------
            -- CONNECT LOOP
            ----------------------------------------------------------------

            connectTwolineLoop(myIndex)

        end

        ----------------------------------------------------------------
        -- COMMAND HANDLER
        ----------------------------------------------------------------

        local function handleCommand(
            message,
            sender
        )

            ----------------------------------------------------------------
            -- ADMIN ONLY
            ----------------------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end

            local lower =
                message:lower()

            ----------------------------------------------------------------
            -- !TWOLINE
            ----------------------------------------------------------------

            if lower == "!twoline" then

                startTwoline(sender)

                return

            end

            ----------------------------------------------------------------
            -- !TWOLINE PLAYER
            ----------------------------------------------------------------

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

                    startTwoline(
                        target
                    )

                end

                return

            end

            ----------------------------------------------------------------
            -- !STOP
            ----------------------------------------------------------------

            if lower == "!stop"
                or lower == "!untwoline" then

                stopTwoline()

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

                ----------------------------------------------------------------
                -- RECONNECT TWOLINE
                ----------------------------------------------------------------
                -- Jangan panggil startTwoline().
                --
                -- startTwoline() memanggil stopOtherModes(),
                -- yang dapat menghentikan Sync.
                ----------------------------------------------------------------

                if following
                    and targetPlayer then

                    local myIndex =
                        table.find(
                            botOrder,
                            tostring(LocalPlayer.UserId)
                        )

                    if myIndex then

                        connectTwolineLoop(
                            myIndex
                        )

                    end

                end

            end
        )

    end
}