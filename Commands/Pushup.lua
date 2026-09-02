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
        -- GLOBAL
        ----------------------------------------------------------------

        _G.BotVars = _G.BotVars or {}

        local vars = _G.BotVars

        vars.ModeControllers = vars.ModeControllers or {}

        ----------------------------------------------------------------
        -- LOAD ADMIN
        ----------------------------------------------------------------

        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        ----------------------------------------------------------------
        -- ANIMATION REMOTE
        ----------------------------------------------------------------

        local animationHandler =
            ReplicatedStorage
                :WaitForChild("Connections")
                :WaitForChild("dataProviders")
                :WaitForChild("animationHandler")

        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        vars.PushupActive = false
        vars.PushupConnection = nil

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
                    TextChatService.TextChannels
                        :FindFirstChild("RBXGeneral")

                if channel then

                    pcall(function()
                        channel:SendAsync(text)
                    end)

                    return
                end
            end

            ------------------------------------------------------------
            -- OLD CHAT FALLBACK
            ------------------------------------------------------------

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
                    chatEvents
                        :FindFirstChild(
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
        -- STOP PUSH UP ANIMATION
        ----------------------------------------------------------------
        --
        -- Mencari AnimationTrack Push Up yang sedang dimainkan
        -- lalu menghentikannya secara langsung.
        ----------------------------------------------------------------

        local function stopPushupAnimation()

            local character =
                LocalPlayer.Character

            if not character then
                return
            end

            local humanoid =
                character:FindFirstChildOfClass(
                    "Humanoid"
                )

            if not humanoid then
                return
            end

            local animator =
                humanoid:FindFirstChildOfClass(
                    "Animator"
                )

            if not animator then
                return
            end

            ------------------------------------------------------------
            -- CARI ANIMATION TRACK
            ------------------------------------------------------------

            for _, track in ipairs(
                animator:GetPlayingAnimationTracks()
            ) do

                local trackName =
                    tostring(track.Name):lower()

                --------------------------------------------------------
                -- PUSH UP
                --------------------------------------------------------

                if trackName == "push up"
                    or trackName:find("push") then

                    pcall(function()

                        track:Stop(0.15)

                    end)

                end

            end

        end

        ----------------------------------------------------------------
        -- PLAY PUSH UP
        ----------------------------------------------------------------
        --
        -- DIPANGGIL HANYA SATU KALI.
        ----------------------------------------------------------------

        local function playPushup()

            pcall(function()

                animationHandler:InvokeServer(
                    "playAnimation",
                    "Push Up"
                )

            end)

        end

        ----------------------------------------------------------------
        -- STOP PUSHUP
        ----------------------------------------------------------------

        local function stopPushup()

            ------------------------------------------------------------
            -- MATIKAN STATUS
            ------------------------------------------------------------

            vars.PushupActive = false

            ------------------------------------------------------------
            -- STOP LOOP
            ------------------------------------------------------------

            if vars.PushupConnection then

                task.cancel(
                    vars.PushupConnection
                )

                vars.PushupConnection = nil

            end

            ------------------------------------------------------------
            -- STOP ANIMATION
            ------------------------------------------------------------

            stopPushupAnimation()

        end

        ----------------------------------------------------------------
        -- REGISTER PUSHUP CONTROLLER
        ----------------------------------------------------------------

        vars.ModeControllers.pushup =
            stopPushup

        ----------------------------------------------------------------
        -- STOP SEMUA MODE LAIN
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                vars.ModeControllers
            ) do

                if name ~= "pushup"
                    and type(stopFunction) == "function" then

                    pcall(stopFunction)

                end

            end

        end

        ----------------------------------------------------------------
        -- START PUSHUP
        ----------------------------------------------------------------

        local function startPushup(jumlah)

            if not jumlah then
                return
            end

            ------------------------------------------------------------
            -- BATAS MINIMUM
            ------------------------------------------------------------

            if jumlah < 1 then
                return
            end

            ------------------------------------------------------------
            -- BATAS MAKSIMUM
            ------------------------------------------------------------

            if jumlah > 1000 then
                jumlah = 1000
            end

            ------------------------------------------------------------
            -- STOP SEMUA MODE LAIN
            ------------------------------------------------------------

            stopOtherModes()

            ------------------------------------------------------------
            -- SET ACTIVE MODE
            ------------------------------------------------------------

            vars.ActiveMode = "pushup"

            ------------------------------------------------------------
            -- STOP PUSHUP LAMA
            ------------------------------------------------------------

            stopPushup()

            ------------------------------------------------------------
            -- AKTIFKAN PUSHUP
            ------------------------------------------------------------

            vars.PushupActive = true

            ------------------------------------------------------------
            -- YES SIR
            ------------------------------------------------------------

            sendChat("Yes, Sir!")

            ------------------------------------------------------------
            -- TUNGGU SEBELUM MULAI
            ------------------------------------------------------------

            task.wait(2)

            ------------------------------------------------------------
            -- CEK MASIH AKTIF
            ------------------------------------------------------------

            if not vars.PushupActive then
                return
            end

            if vars.ActiveMode ~= "pushup" then
                return
            end

            ------------------------------------------------------------
            -- MULAI ANIMASI
            ------------------------------------------------------------
            --
            -- PENTING:
            -- Hanya dipanggil SATU KALI.
            ------------------------------------------------------------

            playPushup()

            ------------------------------------------------------------
            -- MULAI HITUNG
            ------------------------------------------------------------

            vars.PushupConnection =
                task.spawn(function()

                    ----------------------------------------------------
                    -- HITUNG 1 SAMPAI JUMLAH
                    ----------------------------------------------------

                    for i = 1, jumlah do

                        ------------------------------------------------
                        -- CEK AKTIF
                        ------------------------------------------------

                        if not vars.PushupActive then
                            return
                        end

                        if vars.ActiveMode ~= "pushup" then
                            return
                        end

                        ------------------------------------------------
                        -- TUNGGU SATU HITUNGAN
                        ------------------------------------------------

                        task.wait(5)

                        ------------------------------------------------
                        -- CEK LAGI
                        ------------------------------------------------

                        if not vars.PushupActive then
                            return
                        end

                        if vars.ActiveMode ~= "pushup" then
                            return
                        end

                        ------------------------------------------------
                        -- KIRIM ANGKA
                        ------------------------------------------------

                        sendChat(
                            tostring(i)
                        )

                    end

                    ----------------------------------------------------
                    -- SUDAH SELESAI
                    ----------------------------------------------------

                    ----------------------------------------------------
                    -- STOP ANIMATION
                    ----------------------------------------------------

                    stopPushupAnimation()

                    ----------------------------------------------------
                    -- MATIKAN STATUS
                    ----------------------------------------------------

                    vars.PushupActive = false

                    vars.PushupConnection = nil

                    ----------------------------------------------------
                    -- RESET ACTIVE MODE
                    ----------------------------------------------------

                    if vars.ActiveMode == "pushup" then
                        vars.ActiveMode = nil
                    end

                end)

        end

        ----------------------------------------------------------------
        -- COMMAND HANDLER
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

            local msg =
                message:lower()

            ------------------------------------------------------------
            -- !PUSHUP JUMLAH
            ------------------------------------------------------------

            local jumlah =
                tonumber(
                    msg:match(
                        "^!pushup%s+(%d+)$"
                    )
                )

            if jumlah then

                startPushup(jumlah)

                return
            end

            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if msg == "!stop" then

                --------------------------------------------------------
                -- RESET ACTIVE MODE
                --------------------------------------------------------

                vars.ActiveMode = nil

                --------------------------------------------------------
                -- STOP PUSHUP
                --------------------------------------------------------

                stopPushup()

                --------------------------------------------------------
                -- STOP SEMUA MODE
                --------------------------------------------------------

                for name, stopFunction in pairs(
                    vars.ModeControllers
                ) do

                    if type(stopFunction) == "function" then

                        pcall(stopFunction)

                    end

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
                TextChatService.TextChannels
                    :FindFirstChild(
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

    end
}
