return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")
        local TextChatService = game:GetService("TextChatService")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[Pushup] LocalPlayer tidak ditemukan.")
            return
        end


        ----------------------------------------------------------------
        -- GLOBAL MODE SYSTEM
        ----------------------------------------------------------------

        _G.BotVars = _G.BotVars or {}

        _G.BotVars.ModeControllers =
            _G.BotVars.ModeControllers or {}


        ----------------------------------------------------------------
        -- LOAD ADMIN
        ----------------------------------------------------------------

        local Admin

        do
            local success, result = pcall(function()

                return loadstring(game:HttpGet(
                    "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
                ))()

            end)

            if success and result then

                Admin = result

            else

                warn("[Pushup] Gagal load Admin.lua.")
                return

            end
        end


        ----------------------------------------------------------------
        -- NATURAL LANGUAGE (TANPA PREFIX)
        --
        -- Parser berasal dari Perfix.lua (_G.BotVars.NLP).
        -- Perfix.lua belum memiliki intent pushup, jadi modul ini
        -- mendaftarkan intent-nya sendiri ke NLP.Intents.
        --
        -- Push up dengan hitungan (HANYA Admin):
        --   pushup 4 / pushup 4 kali / pushup sebanyak 4
        --   ("push up" dua kata juga dikenali)
        --   -> semua bot push up serentak sambil berhitung
        --      (tiap bot mengirim angka ke chat), lalu berhenti
        --      di angka 4.
        --
        -- Push up tanpa hitungan (HANYA Admin):
        --   pushup / push up
        --   -> bot push up terus sampai ada perintah berhenti.
        --
        -- Berhenti:
        --   siap grak / tegak grak (Admin atau CommandTarget)
        --   berhenti / stop        (HANYA Admin)
        ----------------------------------------------------------------

        local NLP = _G.BotVars.NLP

        if not NLP then

            warn(
                "[Pushup] NLP tidak ditemukan. "
                .. "Pastikan Perfix.lua dimuat lebih dulu."
            )

        else

            -- "pushup" cukup satu kata. "push up" (dua kata) juga
            -- dikenali karena push (1) + up (1) mencapai threshold.
            -- Angka (misalnya "10") tidak ada di kamus, sehingga
            -- otomatis masuk ke args.
            NLP.Intents.pushup =
                NLP.Intents.pushup
                or {
                    Threshold = 2,

                    Words = {
                        pushup = 2,
                        pushups = 2,
                        push = 1,
                        up = 1,
                        ups = 1,
                    },
                }

            -- Siap grak / tegak grak: menghentikan push up.
            -- Definisi sama dengan Rest.lua, Salute.lua dan Carry.lua,
            -- supaya tidak bentrok siapa pun yang dimuat lebih dulu.
            NLP.Intents.carrystop =
                NLP.Intents.carrystop
                or {
                    Threshold = 2,
                    Priority = -1,
                    StrictRemainder = true,

                    Words = {
                        grak = 2,
                        tegak = 0,
                    },
                }

        end


        ----------------------------------------------------------------
        -- FE ANIMATION ID
        ----------------------------------------------------------------

        local PUSHUP_ANIMATION_ID =
            "11810283308"


        ----------------------------------------------------------------
        -- SETTINGS
        ----------------------------------------------------------------

        -- Bot mengirim angka hitungan ke chat umum.
        local COUNT_IN_CHAT = true

        -- Batas angka supaya tidak berjalan tanpa akhir karena salah ketik.
        local MAX_COUNT = 1000

        -- Berapa kali animasi boleh dimainkan ulang jika terputus.
        -- Hanya berlaku pada mode berhitung. Mode tanpa angka tidak
        -- pernah berhenti sendiri, hanya lewat perintah berhenti.
        local MAX_INTERRUPT_RETRIES = 3

        -- Sinkronisasi antar bot (serentak).
        -- Semua bot mulai di kelipatan SYNC_GRID detik pada jam server
        -- yang sama, sehingga animasi dan hitungan berjalan bersamaan.
        -- SYNC_LEAD = jeda minimum agar semua bot sempat menerima perintah.
        local SYNC_GRID = 2
        local SYNC_LEAD = 0.5


        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local pushupTrack = nil
        local pushupActive = false

        local pushupGeneration = 0

        local targetCount = nil   -- nil = tanpa batas (tunggu perintah stop)
        local repCount = 0
        local interruptRetries = 0

        local trackConnections = {}


        ----------------------------------------------------------------
        -- GET CHARACTER
        ----------------------------------------------------------------

        local function getCharacter()

            return LocalPlayer.Character
                or LocalPlayer.CharacterAdded:Wait()

        end


        ----------------------------------------------------------------
        -- SERVER TIME (JAM BERSAMA SEMUA BOT)
        ----------------------------------------------------------------

        local function getServerTime()

            local ok, now = pcall(function()

                return workspace:GetServerTimeNow()

            end)

            if ok and type(now) == "number" then
                return now
            end

            return os.time()

        end


        ----------------------------------------------------------------
        -- SEND CHAT (HITUNGAN)
        ----------------------------------------------------------------

        local function sendChat(message)

            if not COUNT_IN_CHAT then
                return
            end

            if not message or message == "" then
                return
            end

            task.spawn(function()

                local ok, err = pcall(function()

                    local textChannels =
                        TextChatService:FindFirstChild(
                            "TextChannels"
                        )

                    if not textChannels then
                        error("TextChannels tidak ditemukan")
                    end

                    local generalChannel =
                        textChannels:FindFirstChild(
                            "RBXGeneral"
                        )

                    if not generalChannel then
                        error("RBXGeneral tidak ditemukan")
                    end

                    generalChannel:SendAsync(message)

                end)

                if not ok then

                    warn(
                        "[Pushup] Gagal mengirim hitungan:",
                        err
                    )

                end

            end)

        end


        ----------------------------------------------------------------
        -- DISCONNECT TRACK EVENTS
        ----------------------------------------------------------------

        local function disconnectTrackEvents()

            for _, connection in ipairs(
                trackConnections
            ) do

                pcall(function()
                    connection:Disconnect()
                end)

            end

            trackConnections = {}

        end


        ----------------------------------------------------------------
        -- RESTORE NORMAL ANIMATION
        ----------------------------------------------------------------

        local function restoreNormalAnimation(generation)

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


            ------------------------------------------------------------
            -- VALIDATE GENERATION
            ------------------------------------------------------------

            if generation
                and generation ~= pushupGeneration then

                return
            end


            ------------------------------------------------------------
            -- STOP PUSHUP TRACK
            ------------------------------------------------------------

            if pushupTrack then

                local oldTrack =
                    pushupTrack

                pushupTrack = nil

                pcall(function()
                    oldTrack:Stop(0.15)
                end)

            end


            ------------------------------------------------------------
            -- STOP ACTION TRACKS
            ------------------------------------------------------------

            local animator =
                humanoid:FindFirstChildOfClass(
                    "Animator"
                )

            if animator then

                for _, track in ipairs(
                    animator:GetPlayingAnimationTracks()
                ) do

                    if track.Priority
                        == Enum.AnimationPriority.Action
                        or track.Priority
                        == Enum.AnimationPriority.Action2
                        or track.Priority
                        == Enum.AnimationPriority.Action3
                        or track.Priority
                        == Enum.AnimationPriority.Action4 then

                        pcall(function()
                            track:Stop(0.15)
                        end)

                    end

                end

            end


            ------------------------------------------------------------
            -- RESTART DEFAULT ANIMATE SCRIPT
            ------------------------------------------------------------

            local animateScript =
                character:FindFirstChild("Animate")

            if animateScript
                and animateScript:IsA("LocalScript") then

                pcall(function()
                    animateScript.Enabled = false
                end)

                task.wait()


                --------------------------------------------------------
                -- VALIDATE GENERATION AGAIN
                --------------------------------------------------------

                if generation
                    and generation ~= pushupGeneration then

                    return
                end

                pcall(function()
                    animateScript.Enabled = true
                end)

            end


            ------------------------------------------------------------
            -- FORCE HUMANOID BACK TO RUNNING
            ------------------------------------------------------------

            if generation
                and generation ~= pushupGeneration then

                return
            end

            pcall(function()

                humanoid:ChangeState(
                    Enum.HumanoidStateType.Running
                )

            end)


            ------------------------------------------------------------
            -- DELAYED RUNNING STATE
            ------------------------------------------------------------

            local cleanupGeneration =
                generation or pushupGeneration

            task.defer(function()

                task.wait(0.1)

                if cleanupGeneration
                    ~= pushupGeneration then

                    return
                end

                if humanoid
                    and humanoid.Parent then

                    pcall(function()

                        humanoid:ChangeState(
                            Enum.HumanoidStateType.Running
                        )

                    end)

                end

            end)


            print(
                "[Pushup] Animasi normal dipulihkan."
            )

        end


        ----------------------------------------------------------------
        -- STOP PUSHUP
        ----------------------------------------------------------------

        local function stopPushup()

            ------------------------------------------------------------
            -- INVALIDATE SEMUA PROSES LAMA
            ------------------------------------------------------------

            pushupGeneration =
                pushupGeneration + 1

            local generation =
                pushupGeneration

            pushupActive = false

            disconnectTrackEvents()


            ------------------------------------------------------------
            -- STOP TRACK
            ------------------------------------------------------------

            if pushupTrack then

                local oldTrack =
                    pushupTrack

                pushupTrack = nil

                pcall(function()
                    oldTrack:Stop(0.15)
                end)

            end


            ------------------------------------------------------------
            -- RESTORE ANIMATION
            ------------------------------------------------------------

            restoreNormalAnimation(
                generation
            )

            ------------------------------------------------------------
            -- PENTING:
            -- JANGAN CLEAR CommandTarget DI SINI
            --
            -- Supaya setelah Pushup:
            -- Target masih bisa follow
            -- Target masih bisa frontline
            -- Target masih bisa circle
            -- dll.
            ------------------------------------------------------------

        end


        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.pushup =
            stopPushup


        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "pushup"
                    and type(stopFunction) == "function" then

                    pcall(function()
                        stopFunction()
                    end)

                end

            end

        end


        ----------------------------------------------------------------
        -- FINISH PUSHUP (HITUNGAN SELESAI)
        ----------------------------------------------------------------

        local function finishPushup(generation)

            if generation ~= pushupGeneration then
                return
            end

            print(
                "[Pushup] Selesai:",
                repCount,
                "kali | Bot:",
                LocalPlayer.Name
            )

            if _G.BotVars.ActiveMode == "pushup" then

                _G.BotVars.ActiveMode = nil

            end

            stopPushup()

        end


        ----------------------------------------------------------------
        -- REP COMPLETED
        ----------------------------------------------------------------

        local function onRepCompleted(generation)

            if generation ~= pushupGeneration
                or not pushupActive then

                return
            end

            repCount = repCount + 1
            interruptRetries = 0

            -- Mode tanpa hitungan: hanya terus push up.
            if not targetCount then
                return
            end

            print(
                "[Pushup] Hitungan:",
                repCount,
                "/",
                targetCount,
                "| Bot:",
                LocalPlayer.Name
            )

            sendChat(tostring(repCount))

            if repCount >= targetCount then

                finishPushup(generation)

            end

        end


        ----------------------------------------------------------------
        -- ATTACH TRACK (PLAY FE ANIMATION WITH RETRY)
        ----------------------------------------------------------------

        local attachTrack

        attachTrack = function(generation, startAt)

            local character =
                getCharacter()

            local humanoid =
                character:FindFirstChildOfClass(
                    "Humanoid"
                )

            if not humanoid then

                warn(
                    "[Pushup] Humanoid tidak ditemukan."
                )

                return false

            end


            local maxAttempts = 3
            local success = false
            local result = nil

            for attempt = 1, maxAttempts do

                --------------------------------------------------------
                -- COMMAND SUDAH BERGANTI
                --------------------------------------------------------

                if generation
                    ~= pushupGeneration then

                    return false

                end


                --------------------------------------------------------
                -- PLAY FE ANIMATION
                --------------------------------------------------------

                local ok, track =
                    pcall(function()

                        return humanoid:
                            PlayEmoteAndGetAnimTrackById(
                                PUSHUP_ANIMATION_ID
                            )

                    end)

                if ok and track then

                    success = true
                    result = track

                    break

                end

                result = track


                --------------------------------------------------------
                -- RETRY
                --------------------------------------------------------

                if attempt < maxAttempts then

                    task.wait(0.1)

                end

            end


            ----------------------------------------------------------------
            -- VALIDATE GENERATION AFTER RETRY
            ----------------------------------------------------------------

            if generation
                ~= pushupGeneration then

                if result then

                    pcall(function()
                        result:Stop(0)
                    end)

                end

                return false

            end


            if not (success and result) then

                warn(
                    "[Pushup] FE Animation gagal dimainkan setelah",
                    maxAttempts,
                    "percobaan.",
                    "| Bot:",
                    LocalPlayer.Name,
                    "| Last Error:",
                    result
                )

                return false

            end


            ----------------------------------------------------------------
            -- TRACK BERHASIL
            ----------------------------------------------------------------

            local track = result

            pushupTrack = track
            pushupActive = true

            -- Sinkronkan fase animasi dengan jam bersama: bot yang
            -- terlambat mulai (misalnya karena loading animasi)
            -- menyusul ke posisi yang sama dengan bot lain.
            if startAt then

                pcall(function()

                    local late =
                        getServerTime() - startAt

                    local length =
                        track.Length

                    if late > 0.05
                        and length
                        and length > 0
                        and late < length then

                        track.TimePosition = late

                    end

                end)

            end

            -- Diulang terus; setiap satu putaran penuh = satu push up.
            pcall(function()
                track.Looped = true
            end)

            print(
                "[Pushup] FE Animation berhasil dimainkan:",
                PUSHUP_ANIMATION_ID,
                "| Bot:",
                LocalPlayer.Name,
                "| Target:",
                _G.BotVars.CommandTarget
                    and _G.BotVars.CommandTarget.Name
                    or "None"
            )


            ----------------------------------------------------------------
            -- HITUNG SETIAP PUTARAN
            ----------------------------------------------------------------

            local loopConnection

            local okLoop = pcall(function()

                loopConnection =
                    track.DidLoop:Connect(function()

                        onRepCompleted(generation)

                    end)

            end)

            if okLoop and loopConnection then

                table.insert(
                    trackConnections,
                    loopConnection
                )

            end


            ----------------------------------------------------------------
            -- JIKA TRACK TERPUTUS SENDIRI (BUKAN KARENA STOP)
            --
            -- stopPushup() mengosongkan pushupTrack lebih dulu,
            -- jadi blok ini hanya jalan jika animasi benar-benar
            -- terputus (misalnya karakter melompat atau bergerak).
            ----------------------------------------------------------------

            local stoppedConnection

            local okStopped = pcall(function()

                stoppedConnection =
                    track.Stopped:Connect(function()

                        if generation ~= pushupGeneration
                            or pushupTrack ~= track
                            or not pushupActive then

                            return

                        end

                        pushupTrack = nil

                        if targetCount
                            and interruptRetries
                            >= MAX_INTERRUPT_RETRIES then

                            warn(
                                "[Pushup] Animasi terus terputus.",
                                "Push up dihentikan | Bot:",
                                LocalPlayer.Name
                            )

                            if _G.BotVars.ActiveMode == "pushup" then

                                _G.BotVars.ActiveMode = nil

                            end

                            stopPushup()

                            return

                        end

                        interruptRetries = interruptRetries + 1

                        task.spawn(function()

                            task.wait(0.3)

                            if generation ~= pushupGeneration then
                                return
                            end

                            disconnectTrackEvents()

                            attachTrack(generation)

                        end)

                    end)

            end)

            if okStopped and stoppedConnection then

                table.insert(
                    trackConnections,
                    stoppedConnection
                )

            end

            return true

        end


        ----------------------------------------------------------------
        -- PLAY PUSHUP
        --
        -- totalCount = nil  -> tanpa batas (tunggu perintah stop)
        -- totalCount = angka -> berhitung sampai angka tersebut
        --
        -- syncStart = true -> semua bot menunggu waktu mulai yang sama
        --                     (serentak). Dipakai untuk command baru,
        --                     bukan untuk lanjut setelah respawn.
        ----------------------------------------------------------------

        local function playPushup(
            targetPlayer,
            totalCount,
            startRep,
            syncStart
        )

            ------------------------------------------------------------
            -- NEW GENERATION
            ------------------------------------------------------------

            pushupGeneration =
                pushupGeneration + 1

            local generation =
                pushupGeneration


            ------------------------------------------------------------
            -- SET ACTIVE MODE
            ------------------------------------------------------------

            _G.BotVars.ActiveMode =
                "pushup"


            ------------------------------------------------------------
            -- SET COMMAND TARGET
            ------------------------------------------------------------

            if targetPlayer then

                _G.BotVars.CommandTarget =
                    targetPlayer

            end


            ------------------------------------------------------------
            -- STOP MODE LAIN
            ------------------------------------------------------------

            stopOtherModes()


            ------------------------------------------------------------
            -- VALIDATE GENERATION
            ------------------------------------------------------------

            if generation
                ~= pushupGeneration then

                return

            end


            ------------------------------------------------------------
            -- RESET HITUNGAN
            ------------------------------------------------------------

            targetCount = totalCount
            repCount = startRep or 0
            interruptRetries = 0

            disconnectTrackEvents()


            ------------------------------------------------------------
            -- STOP PREVIOUS PUSHUP
            ------------------------------------------------------------

            if pushupTrack then

                local oldTrack =
                    pushupTrack

                pushupTrack = nil

                pcall(function()
                    oldTrack:Stop(0.1)
                end)

            end


            ------------------------------------------------------------
            -- PLAY (SERENTAK DI JAM SERVER YANG SAMA)
            ------------------------------------------------------------

            local startAt = nil

            if syncStart then

                startAt =
                    math.ceil(
                        (getServerTime() + SYNC_LEAD)
                        / SYNC_GRID
                    ) * SYNC_GRID

                local waitTime =
                    startAt - getServerTime()

                if waitTime > 0 then
                    task.wait(waitTime)
                end


                --------------------------------------------------------
                -- COMMAND SUDAH BERGANTI SELAMA MENUNGGU
                --------------------------------------------------------

                if generation
                    ~= pushupGeneration then

                    return

                end

            end

            attachTrack(generation, startAt)

        end


        ----------------------------------------------------------------
        -- PARSE ANGKA DARI ARGS
        --
        -- Mengembalikan:
        --   nil, true   -> tanpa angka (pushup saja)
        --   angka, true -> angka valid
        --   nil, false  -> argumen tidak valid (diabaikan)
        ----------------------------------------------------------------

        -- Kata pendamping angka yang boleh ada di sekitar hitungan:
        --   "pushup 4 kali", "pushup sebanyak 4", "pushup 4x"
        local COUNT_FILLER_WORDS = {
            kali = true,
            x = true,
            sebanyak = true,
            sebanyaknya = true,
            banyak = true,
            set = true,
            rep = true,
            reps = true,
        }

        local function parseCount(args)

            if not args or #args == 0 then
                return nil, true
            end

            -- Cari angka di antara kata pendamping, misalnya:
            --   "4" | "4 kali" | "sebanyak 4" | "sebanyak 4 kali"
            local numberText = nil

            for _, token in ipairs(args) do

                local word = tostring(token):lower()

                local digits = word:match("^(%d+)x?$")

                if digits then

                    -- Dua angka sekaligus dianggap tidak valid.
                    if numberText then
                        return nil, false
                    end

                    numberText = digits

                elseif not COUNT_FILLER_WORDS[word] then

                    -- Kata lain yang tidak dikenal: abaikan perintah.
                    return nil, false

                end

            end

            -- Hanya kata pendamping tanpa angka ("pushup sebanyak").
            if not numberText then
                return nil, false
            end

            local number = tonumber(numberText)

            if not number
                or number ~= math.floor(number)
                or number < 1 then

                return nil, false

            end

            if number > MAX_COUNT then

                number = MAX_COUNT

            end

            return number, true

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


            ------------------------------------------------------------
            -- ABAIKAN CHAT BOT SENDIRI (HITUNGAN)
            ------------------------------------------------------------

            if sender == LocalPlayer then
                return
            end


            ------------------------------------------------------------
            -- ADMIN CHECK
            ------------------------------------------------------------

            local isAdmin = false

            pcall(function()

                isAdmin =
                    Admin:IsAdmin(sender)

            end)


            ------------------------------------------------------------
            -- COMMAND TARGET CHECK
            ------------------------------------------------------------

            local isCommandTarget =
                (_G.BotVars.CommandTarget == sender)


            ------------------------------------------------------------
            -- HANYA ADMIN / COMMAND TARGET YANG DIPROSES
            ------------------------------------------------------------

            if not isAdmin and not isCommandTarget then
                return
            end


            ------------------------------------------------------------
            -- ANALISA PESAN (BAHASA NATURAL)
            ------------------------------------------------------------

            local intent, args

            if NLP then

                intent, args = NLP.Classify(
                    message,
                    NLP.Intents
                )

            end

            if not intent then
                return
            end


            ----------------------------------------------------------------
            -- TEGAK GRAK / SIAP GRAK
            --
            -- ADMIN atau COMMAND TARGET: hentikan push up saja.
            -- CommandTarget dan mode lain tidak dihentikan.
            ----------------------------------------------------------------

            if intent == "carrystop" then

                if pushupActive
                    or _G.BotVars.ActiveMode == "pushup" then

                    print(
                        "[Pushup] Tegak grak | Sender:",
                        sender.Name
                    )

                    if _G.BotVars.ActiveMode == "pushup" then

                        _G.BotVars.ActiveMode = nil

                    end

                    stopPushup()

                end

                return

            end


            ----------------------------------------------------------------
            -- STOP (berhenti / stop)
            --
            -- HANYA ADMIN
            ----------------------------------------------------------------

            if intent == "stop" then

                if not isAdmin then

                    print(
                        "[Pushup] stop ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end


                if pushupActive
                    or _G.BotVars.ActiveMode == "pushup" then

                    print(
                        "[Pushup] Stop | Admin:",
                        sender.Name
                    )

                    if _G.BotVars.ActiveMode == "pushup" then

                        _G.BotVars.ActiveMode = nil

                    end

                    stopPushup()

                end

                return

            end


            ----------------------------------------------------------------
            -- PUSHUP / PUSH UP [ANGKA]
            --
            -- HANYA ADMIN
            --
            --   pushup 10 -> push up sambil berhitung sampai 10
            --   pushup    -> push up terus sampai ada perintah stop
            ----------------------------------------------------------------

            if intent == "pushup" then

                if not isAdmin then

                    print(
                        "[Pushup] pushup ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end


                local count, valid =
                    parseCount(args)

                if not valid then

                    warn(
                        "[Pushup] Angka tidak valid:",
                        table.concat(args, " ")
                    )

                    return

                end


                print(
                    "[Pushup] Command diterima | Sender:",
                    sender.Name,
                    "| Hitungan:",
                    count or "tanpa batas"
                )


                playPushup(sender, count, 0, true)

                return

            end

        end


        ----------------------------------------------------------------
        -- CHAT HANDLER
        ----------------------------------------------------------------

        local connectedPlayers = {}


        local function connectPlayerChat(player)

            if connectedPlayers[player] then
                return
            end

            connectedPlayers[player] = true

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
        -- EXISTING PLAYERS
        ----------------------------------------------------------------

        for _, player in ipairs(
            Players:GetPlayers()
        ) do

            connectPlayerChat(player)

        end


        ----------------------------------------------------------------
        -- PLAYER ADDED
        ----------------------------------------------------------------

        Players.PlayerAdded:Connect(
            function(player)

                connectPlayerChat(player)

            end
        )


        ----------------------------------------------------------------
        -- PLAYER REMOVING
        ----------------------------------------------------------------

        Players.PlayerRemoving:Connect(
            function(player)

                connectedPlayers[player] = nil

            end
        )


        ----------------------------------------------------------------
        -- CHARACTER RESPAWN
        ----------------------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(
            function()

                task.wait(1)


                --------------------------------------------------------
                -- INVALIDATE TRACK LAMA
                --------------------------------------------------------

                pushupGeneration =
                    pushupGeneration + 1

                local generation =
                    pushupGeneration

                disconnectTrackEvents()

                pushupTrack = nil
                pushupActive = false


                --------------------------------------------------------
                -- JIKA MASIH MODE PUSHUP
                --------------------------------------------------------

                if _G.BotVars.ActiveMode
                    == "pushup" then

                    task.wait(0.5)


                    ----------------------------------------------------
                    -- PASTIKAN BELUM ADA COMMAND BARU
                    ----------------------------------------------------

                    if generation
                        ~= pushupGeneration then

                        return

                    end


                    ----------------------------------------------------
                    -- LANJUTKAN SISA HITUNGAN
                    ----------------------------------------------------

                    if targetCount
                        and repCount >= targetCount then

                        _G.BotVars.ActiveMode = nil

                        return

                    end

                    playPushup(
                        _G.BotVars.CommandTarget,
                        targetCount,
                        repCount
                    )

                end

            end
        )


        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[Pushup] Loaded untuk:",
            LocalPlayer.Name,
            "| FE Animation:",
            PUSHUP_ANIMATION_ID
        )

    end
}
