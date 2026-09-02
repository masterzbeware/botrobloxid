return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")
        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            return
        end

        ----------------------------------------------------------------
        -- LOAD ADMIN
        ----------------------------------------------------------------

        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        ----------------------------------------------------------------
        -- GLOBAL VARIABLES
        ----------------------------------------------------------------

        _G.BotVars = _G.BotVars or {}

        local vars = _G.BotVars

        vars.PushupActive = false
        vars.PushupThread = nil

        ----------------------------------------------------------------
        -- ANIMATION HANDLER
        ----------------------------------------------------------------

        local animationHandler =
            ReplicatedStorage
                :WaitForChild("Connections")
                :WaitForChild("dataProviders")
                :WaitForChild("animationHandler")

        ----------------------------------------------------------------
        -- SEND CHAT
        ----------------------------------------------------------------

        local function sendChat(text)

            if not text then
                return
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

                    pcall(function()

                        channel:SendAsync(text)

                    end)

                    return

                end

            end

            ------------------------------------------------------------
            -- LEGACY CHAT FALLBACK
            ------------------------------------------------------------

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
                        text,
                        "All"
                    )

                end

            end)

        end

        ----------------------------------------------------------------
        -- PLAY PUSH UP
        ----------------------------------------------------------------

        local function playPushup()

            local success, result =
                pcall(function()

                    return animationHandler:InvokeServer(
                        "playAnimation",
                        "Push Up"
                    )

                end)

            if not success then

                warn(
                    "[Pushup] Gagal menjalankan Push Up:",
                    result
                )

                return false

            end

            return true

        end

        ----------------------------------------------------------------
        -- STOP PUSHUP LOOP
        ----------------------------------------------------------------

        local function stopPushup()

            vars.PushupActive = false

            vars.PushupThread = nil

        end

        ----------------------------------------------------------------
        -- START PUSHUP
        ----------------------------------------------------------------

        local function startPushup(jumlah)

            ------------------------------------------------------------
            -- VALIDASI JUMLAH
            ------------------------------------------------------------

            if not jumlah then
                return
            end

            jumlah = math.floor(jumlah)

            if jumlah <= 0 then
                return
            end

            ------------------------------------------------------------
            -- BATASI ANGKA TERLALU BESAR
            ------------------------------------------------------------

            if jumlah > 1000 then

                jumlah = 1000

            end

            ------------------------------------------------------------
            -- STOP PUSHUP LAMA
            ------------------------------------------------------------

            stopPushup()

            task.wait()

            ------------------------------------------------------------
            -- ACTIVE
            ------------------------------------------------------------

            vars.PushupActive = true

            ------------------------------------------------------------
            -- CHAT
            ------------------------------------------------------------

            sendChat("Yes, Sir!")

            ------------------------------------------------------------
            -- TUNGGU SEBELUM MULAI
            ------------------------------------------------------------

            task.wait(2)

            ------------------------------------------------------------
            -- JALANKAN LOOP
            ------------------------------------------------------------

            vars.PushupThread = task.spawn(
                function()

                    for i = 1, jumlah do

                        ------------------------------------------------
                        -- CEK APAKAH DI-STOP
                        ------------------------------------------------

                        if not vars.PushupActive then

                            return

                        end

                        ------------------------------------------------
                        -- PLAY ANIMATION
                        --
                        -- SESUAI HASIL RSPY:
                        --
                        -- InvokeServer(
                        --     "playAnimation",
                        --     "Push Up"
                        -- )
                        ------------------------------------------------

                        local success =
                            playPushup()

                        if not success then

                            vars.PushupActive = false
                            vars.PushupThread = nil

                            return

                        end

                        ------------------------------------------------
                        -- TUNGGU SATU PUSH UP
                        ------------------------------------------------

                        task.wait(5)

                        ------------------------------------------------
                        -- CEK LAGI
                        ------------------------------------------------

                        if not vars.PushupActive then

                            return

                        end

                        ------------------------------------------------
                        -- CHAT JUMLAH
                        ------------------------------------------------

                        if i == jumlah then

                            sendChat(
                                i .. " push up, Sir!"
                            )

                        else

                            sendChat(
                                i .. " push up!"
                            )

                        end

                    end

                    ----------------------------------------------------
                    -- SELESAI
                    ----------------------------------------------------

                    vars.PushupActive = false
                    vars.PushupThread = nil

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

            if not sender then
                return
            end

            ------------------------------------------------------------
            -- ADMIN CHECK
            ------------------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end

            if not message then
                return
            end

            local lower =
                message:lower()

            ------------------------------------------------------------
            -- !PUSHUP ANGKA
            ------------------------------------------------------------

            local jumlah =
                tonumber(
                    lower:match(
                        "^!pushup%s+(%d+)$"
                    )
                )

            if jumlah then

                startPushup(jumlah)

                return

            end

            ------------------------------------------------------------
            -- !PUSHUP STOP
            ------------------------------------------------------------

            if lower == "!pushup stop"
                or lower == "!stop pushup" then

                stopPushup()

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
        -- DONE
        ----------------------------------------------------------------

        print("✅ Pushup.lua loaded")

    end
}
