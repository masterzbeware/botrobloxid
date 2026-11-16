return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")
        local TextChatService = game:GetService("TextChatService")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[Standby] LocalPlayer tidak ditemukan.")
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
                warn("[Standby] Gagal load Admin.lua.")
                return
            end
        end


        ----------------------------------------------------------------
        -- NATURAL LANGUAGE (TANPA PREFIX)
        --
        -- Parser berasal dari Perfix.lua (_G.BotVars.NLP).
        -- Perfix.lua belum memiliki intent standby, jadi modul ini
        -- mendaftarkan intent-nya sendiri ke NLP.Intents.
        --
        -- Aktifkan Standby (HANYA Admin):
        --   siap sedia / siaga / bersiap
        --
        -- Catatan: kata "siap" termasuk kata pengisi di Perfix.lua
        -- dan diabaikan parser, jadi "siap sedia" dikenali lewat
        -- kata "sedia".
        ----------------------------------------------------------------

        local NLP = _G.BotVars.NLP

        if not NLP then

            warn(
                "[Standby] NLP tidak ditemukan. "
                .. "Pastikan Perfix.lua dimuat lebih dulu."
            )

        else

            NLP.Intents.standby =
                NLP.Intents.standby
                or {
                    Words = {
                        sedia = 2,
                        siaga = 2,
                        bersiap = 2,
                    },
                }

        end


        ----------------------------------------------------------------
        -- FE ANIMATION ID
        ----------------------------------------------------------------

        local STANDBY_ANIMATION_ID =
            "99340305804606"


        ----------------------------------------------------------------
        -- CARA KERJA
        --
        -- Standby diaktifkan dengan perintah (HANYA Admin):
        --   siap sedia / siaga / bersiap
        --
        -- Setelah aktif:
        --
        -- Diam + tidak ada animasi lain
        --     -> animasi Standby dimainkan
        --
        -- Bergerak / jalan / ada animasi lain
        --     -> animasi Standby berhenti, dan dimainkan lagi
        --        begitu bot diam
        --
        -- Standby berakhir saat ada perintah lain (follow, circle,
        -- salute, sit, dll) atau stop.
        ----------------------------------------------------------------


        ----------------------------------------------------------------
        -- SETTINGS
        ----------------------------------------------------------------

        -- Seberapa sering bot dicek sedang diam atau tidak (detik).
        local MONITOR_INTERVAL = 0.2

        -- Bot harus diam sebesar ini dulu sebelum animasi dimainkan (detik).
        local IDLE_DELAY = 0.3

        -- Jarak waktu antar percobaan jika animasi gagal dimainkan (detik).
        local RETRY_DELAY = 2

        -- Kecepatan horizontal di atas nilai ini dianggap bergerak.
        local MOVE_SPEED_THRESHOLD = 0.5


        ----------------------------------------------------------------
        -- STATE YANG DIANGGAP "DIAM"
        ----------------------------------------------------------------

        local IDLE_STATES = {
            [Enum.HumanoidStateType.Running] = true,
            [Enum.HumanoidStateType.RunningNoPhysics] = true,
            [Enum.HumanoidStateType.Landed] = true,
        }


        ----------------------------------------------------------------
        -- PRIORITY YANG DIANGGAP "ANIMASI LAIN"
        --
        -- Animasi bawaan (Idle / Movement / Core) diabaikan,
        -- hanya animasi Action (emote, dance, dll) yang dihitung.
        ----------------------------------------------------------------

        local ACTION_PRIORITIES = {
            [Enum.AnimationPriority.Action] = true,
            [Enum.AnimationPriority.Action2] = true,
            [Enum.AnimationPriority.Action3] = true,
            [Enum.AnimationPriority.Action4] = true,
        }


        ----------------------------------------------------------------
        -- MODE YANG MEMAINKAN ANIMASI SENDIRI
        --
        -- Selama salah satu mode ini aktif, Standby tidak dimainkan
        -- supaya animasi mode tersebut tidak tertimpa.
        -- Mode gerak/formasi (follow, circle, dll) tidak termasuk.
        ----------------------------------------------------------------

        local ANIMATION_MODES = {
            salute = true,
            sit = true,
            mydawgdance = true,
            agree = true,
            worship = true,
            rest = true,
            glowstick = true,
        }


        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local standbyTrack = nil

        -- True setelah Admin mengetik siap sedia / siaga / bersiap.
        local standbyEnabled = false

        local playFailureWarned = false

        -- Mencegah monitor ganda jika module dijalankan ulang.
        local runId =
            (_G.BotVars.StandbyRunId or 0) + 1

        _G.BotVars.StandbyRunId = runId


        ----------------------------------------------------------------
        -- CEK TRACK MILIK STANDBY
        ----------------------------------------------------------------

        local function isStandbyTrack(track)

            if track == standbyTrack then
                return true
            end

            local ok, matched = pcall(function()

                local animation = track.Animation

                return animation ~= nil
                    and string.find(
                        animation.AnimationId,
                        STANDBY_ANIMATION_ID,
                        1,
                        true
                    ) ~= nil

            end)

            return ok and matched == true

        end


        ----------------------------------------------------------------
        -- CEK ADA ANIMASI LAIN (ACTION) YANG SEDANG DIMAINKAN
        ----------------------------------------------------------------

        local function hasOtherAnimation(humanoid)

            local animator =
                humanoid:FindFirstChildOfClass(
                    "Animator"
                )

            if not animator then
                return false
            end

            for _, track in ipairs(
                animator:GetPlayingAnimationTracks()
            ) do

                if ACTION_PRIORITIES[track.Priority]
                    and not isStandbyTrack(track) then

                    return true

                end

            end

            return false

        end


        ----------------------------------------------------------------
        -- CEK BOT SEDANG DIAM
        ----------------------------------------------------------------

        local function isIdle(humanoid, rootPart)

            ------------------------------------------------------------
            -- STANDBY BELUM DIAKTIFKAN
            ------------------------------------------------------------

            if not standbyEnabled then
                return false
            end


            ------------------------------------------------------------
            -- MODE ANIMASI AKTIF (salute, sit, dance, dll)
            ------------------------------------------------------------

            local activeMode = _G.BotVars.ActiveMode

            if activeMode and ANIMATION_MODES[activeMode] then
                return false
            end

            if humanoid.Health <= 0 then
                return false
            end

            if humanoid.Sit then
                return false
            end

            if not IDLE_STATES[humanoid:GetState()] then
                return false
            end

            if humanoid.MoveDirection.Magnitude > 0.05 then
                return false
            end

            local velocity =
                rootPart.AssemblyLinearVelocity

            local horizontalSpeed =
                Vector3.new(
                    velocity.X,
                    0,
                    velocity.Z
                ).Magnitude

            if horizontalSpeed > MOVE_SPEED_THRESHOLD then
                return false
            end

            if hasOtherAnimation(humanoid) then
                return false
            end

            return true

        end


        ----------------------------------------------------------------
        -- STOP TRACK
        ----------------------------------------------------------------

        local function stopTrack(fadeTime)

            local fade =
                fadeTime or 0.15

            local stopped = false

            if standbyTrack then

                local oldTrack =
                    standbyTrack

                standbyTrack = nil

                stopped = true

                pcall(function()
                    oldTrack:Stop(fade)
                end)

            end


            ------------------------------------------------------------
            -- HENTIKAN JUGA TRACK STANDBY YANG MASIH BERJALAN DI
            -- ANIMATOR (jaga-jaga jika referensi track sudah hilang)
            ------------------------------------------------------------

            local character =
                LocalPlayer.Character

            local humanoid =
                character
                and character:FindFirstChildOfClass(
                    "Humanoid"
                )

            local animator =
                humanoid
                and humanoid:FindFirstChildOfClass(
                    "Animator"
                )

            if animator then

                for _, track in ipairs(
                    animator:GetPlayingAnimationTracks()
                ) do

                    if isStandbyTrack(track) then

                        stopped = true

                        pcall(function()
                            track:Stop(fade)
                        end)

                    end

                end

            end

            return stopped

        end


        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        --
        -- Dipanggil mode lain (follow, dance, salute, dll) saat
        -- perintah baru dimulai, atau saat Admin mengetik stop.
        -- Standby berakhir; ketik siap sedia lagi untuk mengaktifkan.
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.standby =
            function()

                standbyEnabled = false

                -- Berhenti seketika supaya animasi mode berikutnya
                -- (misalnya hormat) bisa langsung dimainkan.
                local wasPlaying =
                    stopTrack(0)

                if wasPlaying then

                    task.wait(0.1)

                end

            end


        ----------------------------------------------------------------
        -- PLAY STANDBY TRACK (SATU KALI COBA)
        ----------------------------------------------------------------

        local function playStandbyTrack(humanoid)

            -- PlayEmoteAndGetAnimTrackById bisa mengembalikan
            -- (berhasil, track). Ambil AnimationTrack yang asli,
            -- bukan nilai pertama yang dikembalikan.
            local results =
                table.pack(
                    pcall(function()

                        return humanoid:
                            PlayEmoteAndGetAnimTrackById(
                                STANDBY_ANIMATION_ID
                            )

                    end)
                )

            local ok = results[1]
            local track = nil

            for index = 2, results.n do

                local value = results[index]

                if typeof(value) == "Instance"
                    and value:IsA("AnimationTrack") then

                    track = value
                    break

                end

            end

            -- Emote dilaporkan berhasil tetapi tidak ada track yang
            -- dikembalikan: cari track Standby di Animator.
            if ok and not track and results[2] == true then

                task.wait()

                local animator =
                    humanoid:FindFirstChildOfClass(
                        "Animator"
                    )

                if animator then

                    for _, candidate in ipairs(
                        animator:GetPlayingAnimationTracks()
                    ) do

                        if isStandbyTrack(candidate) then

                            track = candidate
                            break

                        end

                    end

                end

            end

            if not ok or not track then

                if not playFailureWarned then

                    playFailureWarned = true

                    warn(
                        "[Standby] FE Animation gagal dimainkan.",
                        "| Bot:",
                        LocalPlayer.Name,
                        "| Error:",
                        tostring(results[2])
                    )

                end

                return false

            end

            playFailureWarned = false

            -- Tahan pose selama bot masih diam.
            pcall(function()
                track.Looped = true
            end)

            standbyTrack = track

            print(
                "[Standby] FE Animation dimainkan:",
                STANDBY_ANIMATION_ID,
                "| Bot:",
                LocalPlayer.Name
            )


            ------------------------------------------------------------
            -- MONITOR TRACK
            ------------------------------------------------------------

            task.spawn(function()

                pcall(function()
                    track.Stopped:Wait()
                end)

                ----------------------------------------------------
                -- CLEANUP ONLY IF STILL SAME TRACK
                ----------------------------------------------------

                if standbyTrack == track then

                    standbyTrack = nil

                end

            end)

            return true

        end


        ----------------------------------------------------------------
        -- IDLE MONITOR
        --
        -- Diam + tidak ada animasi lain
        --     -> mainkan Standby (jika sudah diaktifkan)
        -- Bergerak / ada animasi lain / mode animasi aktif
        --     -> hentikan Standby
        ----------------------------------------------------------------

        task.spawn(function()

            local idleTime = 0
            local retryAt = 0

            while true do

                local delta =
                    task.wait(MONITOR_INTERVAL)


                --------------------------------------------------------
                -- MODULE DIJALANKAN ULANG
                --------------------------------------------------------

                if runId ~= _G.BotVars.StandbyRunId then

                    stopTrack(0.1)

                    return

                end


                --------------------------------------------------------
                -- CHARACTER
                --------------------------------------------------------

                local character =
                    LocalPlayer.Character

                local humanoid =
                    character
                    and character:FindFirstChildOfClass(
                        "Humanoid"
                    )

                local rootPart =
                    character
                    and character:FindFirstChild(
                        "HumanoidRootPart"
                    )

                if humanoid
                    and rootPart
                    and humanoid.Parent then

                    if isIdle(humanoid, rootPart) then

                        idleTime =
                            idleTime + delta

                        if not standbyTrack
                            and idleTime >= IDLE_DELAY
                            and os.clock() >= retryAt then

                            if not playStandbyTrack(humanoid) then

                                retryAt =
                                    os.clock() + RETRY_DELAY

                            end

                        end

                    else

                        idleTime = 0

                        if standbyTrack then

                            stopTrack(0.15)

                        end

                    end

                end

            end

        end)


        ----------------------------------------------------------------
        -- START STANDBY
        ----------------------------------------------------------------

        local function startStandby(sender)

            ------------------------------------------------------------
            -- HENTIKAN MODE ANIMASI (salute, sit, dance, dll)
            --
            -- Mode gerak/formasi (follow, circle, dll) TIDAK dihentikan,
            -- bot tetap di posisinya.
            ------------------------------------------------------------

            local activeMode = _G.BotVars.ActiveMode

            if activeMode and ANIMATION_MODES[activeMode] then

                local controller =
                    _G.BotVars.ModeControllers[activeMode]

                _G.BotVars.ActiveMode = nil

                if type(controller) == "function" then

                    pcall(controller)

                end

            end

            standbyEnabled = true

            print(
                "[Standby] Aktif | Bot:",
                LocalPlayer.Name,
                "| Admin:",
                sender.Name
            )

        end


        ----------------------------------------------------------------
        -- COMMAND HANDLER
        --
        -- siap sedia / siaga / bersiap
        -- HANYA ADMIN
        ----------------------------------------------------------------

        local function handleCommand(message, sender)

            if not message or not sender then
                return
            end

            local isAdmin = false

            pcall(function()

                isAdmin =
                    Admin:IsAdmin(sender)

            end)

            if not isAdmin then
                return
            end

            local intent, args

            if NLP then

                intent, args = NLP.Classify(
                    message,
                    NLP.Intents
                )

            end

            if intent == "standby" and #args == 0 then

                startStandby(sender)

            end

        end


        ----------------------------------------------------------------
        -- CHAT CONNECTION
        --
        -- Gunakan chat modern jika tersedia. Fallback Chatted hanya
        -- dipakai jika RBXGeneral tidak ada.
        ----------------------------------------------------------------

        local channel

        if TextChatService
            and TextChatService.TextChannels then

            channel =
                TextChatService.TextChannels:FindFirstChild(
                    "RBXGeneral"
                )

        end

        if channel then

            channel.MessageReceived:Connect(
                function(message)

                    local textSource =
                        message.TextSource

                    if not textSource then
                        return
                    end

                    local sender =
                        Players:GetPlayerByUserId(
                            textSource.UserId
                        )

                    if sender then

                        handleCommand(
                            message.Text,
                            sender
                        )

                    end

                end
            )

        else

            local function connectPlayer(player)

                player.Chatted:Connect(
                    function(message)

                        handleCommand(
                            message,
                            player
                        )

                    end
                )

            end

            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                connectPlayer(player)

            end

            Players.PlayerAdded:Connect(
                connectPlayer
            )

        end


        ----------------------------------------------------------------
        -- CHARACTER RESPAWN
        ----------------------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(
            function()

                -- Track lama sudah hilang bersama character lama.
                standbyTrack = nil

            end
        )


        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[Standby] Loaded untuk:",
            LocalPlayer.Name,
            "| FE Animation:",
            STANDBY_ANIMATION_ID
        )

    end
}
