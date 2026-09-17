return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[PushUp] LocalPlayer tidak ditemukan.")
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

                warn("[PushUp] Gagal load Admin.lua.")
                return

            end
        end


        ----------------------------------------------------------------
        -- FE ANIMATION ID
        ----------------------------------------------------------------

        local PUSHUP_ANIMATION_ID =
            "110904780556875"


        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local danceTrack = nil
        local dancing = false

        -- Generation digunakan untuk memastikan proses lama
        -- dari !stop / !pushup tidak mengganggu command terbaru.
        local danceGeneration = 0


        ----------------------------------------------------------------
        -- GET CHARACTER
        ----------------------------------------------------------------

        local function getCharacter()

            return LocalPlayer.Character
                or LocalPlayer.CharacterAdded:Wait()

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
                and generation ~= danceGeneration then

                return
            end


            ------------------------------------------------------------
            -- STOP ATEEZ DANCE
            ------------------------------------------------------------

            if danceTrack then

                local oldTrack =
                    danceTrack

                danceTrack = nil

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
                    and generation ~= danceGeneration then

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
                and generation ~= danceGeneration then

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
                generation or danceGeneration

            task.defer(function()

                task.wait(0.1)

                if cleanupGeneration
                    ~= danceGeneration then

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
                "[PushUp] Animasi normal dipulihkan."
            )

        end


        ----------------------------------------------------------------
        -- STOP ATEEZ DANCE
        ----------------------------------------------------------------

        local function stopPushUp()

            ------------------------------------------------------------
            -- INVALIDATE SEMUA PROSES LAMA
            ------------------------------------------------------------

            danceGeneration =
                danceGeneration + 1

            local generation =
                danceGeneration

            dancing = false


            ------------------------------------------------------------
            -- STOP TRACK
            ------------------------------------------------------------

            if danceTrack then

                local oldTrack =
                    danceTrack

                danceTrack = nil

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

        end


        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.pushup =
            stopPushUp


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
        -- PLAY ATEEZ DANCE
        ----------------------------------------------------------------

        local function playPushUp(repetitions)
            repetitions = tonumber(repetitions)

            -- Tanpa angka = jalankan seperti command !pushup biasa.
            if not repetitions then
                repetitions = nil
            else
                repetitions = math.floor(repetitions)

                if repetitions < 1 then
                    return
                end

                -- Batasi angka agar command tidak membuat proses terlalu lama.
                repetitions = math.min(repetitions, 100)
            end

            danceGeneration = danceGeneration + 1

            local generation = danceGeneration

            _G.BotVars.ActiveMode = "pushup"

            stopOtherModes()

            if generation ~= danceGeneration then
                return
            end

            if danceTrack then
                local oldTrack = danceTrack
                danceTrack = nil

                pcall(function()
                    oldTrack:Stop(0.1)
                end)
            end

            -- Untuk command !pushup ANGKA, bot memberi konfirmasi
            -- sebelum animation dimulai.
            if repetitions then
                sendChat("Yes, Sir!")
            end

            local character = getCharacter()

            local humanoid =
                character:FindFirstChildOfClass("Humanoid")

            if not humanoid then
                warn("[PushUp] Humanoid tidak ditemukan.")
                return
            end

            local maxAttempts = 3
            local success = false
            local result = nil

            for attempt = 1, maxAttempts do
                if generation ~= danceGeneration then
                    return
                end

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

                if attempt < maxAttempts then
                    task.wait(0.1)
                end
            end

            if generation ~= danceGeneration then
                if result then
                    pcall(function()
                        result:Stop(0)
                    end)
                end

                return
            end

            if not success or not result then
                warn(
                    "[PushUp] FE Animation gagal dimainkan setelah",
                    maxAttempts,
                    "percobaan.",
                    "| Bot:",
                    LocalPlayer.Name,
                    "| Last Error:",
                    result
                )
                return
            end

            danceTrack = result
            dancing = true

            print(
                "[PushUp] FE Animation berhasil dimainkan:",
                PUSHUP_ANIMATION_ID,
                "| Bot:",
                LocalPlayer.Name
            )

            -- Jika !pushup memakai angka, hitung 1 sampai angka.
            if repetitions then
                task.spawn(function()
                    local track = result
                    local trackGeneration = generation

                    -- Beri sedikit waktu agar semua bot mulai animasi
                    -- sebelum hitungan dimulai.
                    task.wait(0.2)

                    for count = 1, repetitions do
                        if danceGeneration ~= trackGeneration
                            or _G.BotVars.ActiveMode ~= "pushup"
                            or danceTrack ~= track
                            or not dancing then
                            return
                        end

                        print(
                            "[PushUp] Hitungan:",
                            count,
                            "/",
                            repetitions,
                            "| Bot:",
                            LocalPlayer.Name
                        )

                        task.wait(1)
                    end

                    if danceGeneration ~= trackGeneration
                        or _G.BotVars.ActiveMode ~= "pushup"
                        or danceTrack ~= track then
                        return
                    end

                    -- Setelah hitungan selesai, stop animation.
                    danceGeneration = danceGeneration + 1
                    dancing = false
                    danceTrack = nil

                    pcall(function()
                        track:Stop(0.15)
                    end)

                    _G.BotVars.ActiveMode = nil

                    restoreNormalAnimation(
                        danceGeneration
                    )

                    print(
                        "[PushUp] Selesai",
                        repetitions,
                        "hitungan | Bot:",
                        LocalPlayer.Name
                    )
                end)
            else
                -- Mode normal: monitor track sampai berhenti.
                task.spawn(function()
                    local track = result
                    local trackGeneration = generation

                    if not track then
                        return
                    end

                    pcall(function()
                        track.Stopped:Wait()
                    end)

                    if danceTrack == track
                        and dancing
                        and trackGeneration == danceGeneration then
                        danceTrack = nil
                    end
                end)
            end
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
            -- ADMIN CHECK
            ------------------------------------------------------------

            local isAdmin = false

            pcall(function()

                isAdmin =
                    Admin:IsAdmin(sender)

            end)

            if not isAdmin then
                return
            end


            ------------------------------------------------------------
            -- CLEAN MESSAGE
            ------------------------------------------------------------

            local lower =
                message:lower()

            lower =
                lower:gsub("^%s+", "")

            lower =
                lower:gsub("%s+$", "")


            ------------------------------------------------------------
            -- !ATEEZDANCE
            ------------------------------------------------------------

            local pushUpCount =
                lower:match("^!pushup%s+(%d+)$")

            if lower == "!pushup"
                or pushUpCount then

                print(
                    "[PushUp] Command diterima | Bot:",
                    LocalPlayer.Name,
                    "| Admin:",
                    sender.Name,
                    "| Count:",
                    pushUpCount or "normal"
                )

                if pushUpCount then
                    -- Pesan hanya dikirim sekali oleh setiap bot command
                    -- handler; animation kemudian dimulai.
                    playPushUp(tonumber(pushUpCount))
                else
                    playPushUp()
                end

                return

            end


            ------------------------------------------------------------
            -- !UNATEEZDANCE
            ------------------------------------------------------------

            if lower == "!unpushup" then

                print(
                    "[PushUp] UnPushUp | Bot:",
                    LocalPlayer.Name,
                    "| Admin:",
                    sender.Name
                )

                if _G.BotVars.ActiveMode
                    == "pushup" then

                    _G.BotVars.ActiveMode = nil

                end

                stopPushUp()

                return

            end


            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if lower == "!stop" then

                print(
                    "[PushUp] Stop | Bot:",
                    LocalPlayer.Name,
                    "| Admin:",
                    sender.Name
                )

                if _G.BotVars.ActiveMode
                    == "pushup" then

                    _G.BotVars.ActiveMode = nil

                end

                stopPushUp()

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

            connectPlayerChat(
                player
            )

        end


        ----------------------------------------------------------------
        -- PLAYER ADDED
        ----------------------------------------------------------------

        Players.PlayerAdded:Connect(
            function(player)

                connectPlayerChat(
                    player
                )

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

                danceGeneration =
                    danceGeneration + 1

                local generation =
                    danceGeneration

                danceTrack = nil
                dancing = false


                --------------------------------------------------------
                -- JIKA MASIH MODE ATEEZ DANCE
                --------------------------------------------------------

                if _G.BotVars.ActiveMode
                    == "pushup" then

                    task.wait(0.5)


                    ----------------------------------------------------
                    -- PASTIKAN BELUM ADA COMMAND BARU
                    ----------------------------------------------------

                    if generation
                        ~= danceGeneration then

                        return

                    end

                    playPushUp()

                end

            end
        )


        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[PushUp] Loaded untuk:",
            LocalPlayer.Name,
            "| FE Animation:",
            PUSHUP_ANIMATION_ID
        )

    end
}
