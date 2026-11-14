return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")

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
        -- FE ANIMATION ID
        ----------------------------------------------------------------

        local STANDBY_ANIMATION_ID =
            "119830241096049"


        ----------------------------------------------------------------
        -- CARA KERJA (TANPA PERINTAH)
        --
        -- Standby selalu aktif otomatis:
        --
        -- Diam + tidak ada animasi lain + tidak ada perintah
        --     -> animasi Standby dimainkan
        --
        -- Bergerak / jalan / ada animasi lain / ada perintah
        --     -> animasi Standby berhenti
        --
        -- Setelah bot kembali diam dan tidak ada perintah aktif,
        -- animasi Standby dimainkan lagi.
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
        -- VARIABLES
        ----------------------------------------------------------------

        local standbyTrack = nil

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
            -- ADA PERINTAH / MODE AKTIF
            ------------------------------------------------------------

            if _G.BotVars.ActiveMode ~= nil then
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

            if standbyTrack then

                local oldTrack =
                    standbyTrack

                standbyTrack = nil

                pcall(function()
                    oldTrack:Stop(fadeTime or 0.15)
                end)

            end

        end


        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        --
        -- Dipanggil mode lain (follow, dance, salute, dll) saat
        -- perintah baru dimulai, supaya animasi Standby langsung
        -- berhenti. Standby tetap aktif dan akan dimainkan lagi
        -- setelah tidak ada perintah dan bot kembali diam.
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.standby =
            function()

                stopTrack(0.1)

            end


        ----------------------------------------------------------------
        -- PLAY STANDBY TRACK (SATU KALI COBA)
        ----------------------------------------------------------------

        local function playStandbyTrack(humanoid)

            local ok, track =
                pcall(function()

                    return humanoid:
                        PlayEmoteAndGetAnimTrackById(
                            STANDBY_ANIMATION_ID
                        )

                end)

            if not ok or not track then

                if not playFailureWarned then

                    playFailureWarned = true

                    warn(
                        "[Standby] FE Animation gagal dimainkan.",
                        "| Bot:",
                        LocalPlayer.Name,
                        "| Error:",
                        track
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
        -- Diam + tidak ada animasi lain + tidak ada perintah
        --     -> mainkan Standby
        -- Bergerak / ada animasi lain / ada perintah
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
