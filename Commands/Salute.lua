return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[Salute] LocalPlayer tidak ditemukan.")
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

                warn("[Salute] Gagal load Admin.lua.")
                return

            end
        end


        ----------------------------------------------------------------
        -- EMOTE ID
        ----------------------------------------------------------------

        local SALUTE_EMOTE_ID =
            "108307316311180"


        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local saluteTrack = nil
        local saluting = false

        -- Generation digunakan untuk memastikan proses lama
        -- dari !stop / !salute tidak mengganggu command terbaru.
        local saluteGeneration = 0


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
        -- generation bersifat optional.
        -- Jika generation sudah berubah, proses cleanup lama
        -- langsung dibatalkan.

        local function restoreNormalAnimation(generation)

            if generation
                and generation ~= saluteGeneration then

                return

            end


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
            -- CHECK GENERATION
            ------------------------------------------------------------

            if generation
                and generation ~= saluteGeneration then

                return

            end


            ------------------------------------------------------------
            -- STOP SALUTE EMOTE
            ------------------------------------------------------------

            if saluteTrack then

                local oldTrack =
                    saluteTrack

                saluteTrack = nil

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
            -- CHECK GENERATION BEFORE TOUCHING ANIMATE
            ------------------------------------------------------------

            if generation
                and generation ~= saluteGeneration then

                return

            end


            ------------------------------------------------------------
            -- RESTART DEFAULT ANIMATE SCRIPT
            ------------------------------------------------------------

            local animateScript =
                character:FindFirstChild(
                    "Animate"
                )

            if animateScript
                and animateScript:IsA("LocalScript") then

                pcall(function()
                    animateScript.Enabled = false
                end)


                --------------------------------------------------------
                -- WAIT SINGKAT UNTUK MEMBERI WAKTU ANIMATE RESET
                --------------------------------------------------------

                task.wait()


                --------------------------------------------------------
                -- JIKA SUDAH ADA COMMAND BARU,
                -- JANGAN LANJUTKAN CLEANUP LAMA
                --------------------------------------------------------

                if generation
                    and generation ~= saluteGeneration then

                    return

                end


                pcall(function()
                    animateScript.Enabled = true
                end)

            end


            ------------------------------------------------------------
            -- CHECK GENERATION
            ------------------------------------------------------------

            if generation
                and generation ~= saluteGeneration then

                return

            end


            ------------------------------------------------------------
            -- FORCE HUMANOID BACK TO RUNNING
            ------------------------------------------------------------

            pcall(function()

                humanoid:ChangeState(
                    Enum.HumanoidStateType.Running
                )

            end)


            ------------------------------------------------------------
            -- DELAYED RUNNING STATE
            ------------------------------------------------------------

            local cleanupGeneration =
                generation or saluteGeneration

            task.defer(function()

                task.wait(0.1)


                --------------------------------------------------------
                -- JIKA SUDAH ADA COMMAND BARU,
                -- CLEANUP INI SUDAH TIDAK BERLAKU
                --------------------------------------------------------

                if cleanupGeneration
                    ~= saluteGeneration then

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
                "[Salute] Animasi normal dipulihkan."
            )

        end


        ----------------------------------------------------------------
        -- STOP SALUTE
        ----------------------------------------------------------------

        local function stopSalute()

            ------------------------------------------------------------
            -- INVALIDATE SEMUA PROSES SALUTE LAMA
            ------------------------------------------------------------

            saluteGeneration =
                saluteGeneration + 1

            local generation =
                saluteGeneration


            saluting = false


            ------------------------------------------------------------
            -- STOP TRACK
            ------------------------------------------------------------

            if saluteTrack then

                local oldTrack =
                    saluteTrack

                saluteTrack = nil

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

        _G.BotVars.ModeControllers.salute =
            stopSalute


        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "salute"
                    and type(stopFunction) == "function" then

                    pcall(function()
                        stopFunction()
                    end)

                end

            end

        end


        ----------------------------------------------------------------
        -- PLAY SALUTE EMOTE
        ----------------------------------------------------------------

        local function playSalute()

            ------------------------------------------------------------
            -- NEW GENERATION
            ------------------------------------------------------------

            saluteGeneration =
                saluteGeneration + 1

            local generation =
                saluteGeneration


            ------------------------------------------------------------
            -- SET ACTIVE MODE
            ------------------------------------------------------------

            _G.BotVars.ActiveMode =
                "salute"


            ------------------------------------------------------------
            -- STOP MODE LAIN
            ------------------------------------------------------------

            stopOtherModes()


            ------------------------------------------------------------
            -- VALIDATE GENERATION
            ------------------------------------------------------------

            if generation ~= saluteGeneration then
                return
            end


            ------------------------------------------------------------
            -- STOP PREVIOUS SALUTE TRACK
            ------------------------------------------------------------

            if saluteTrack then

                local oldTrack =
                    saluteTrack

                saluteTrack = nil

                pcall(function()
                    oldTrack:Stop(0.1)
                end)

            end


            ------------------------------------------------------------
            -- GET CHARACTER
            ------------------------------------------------------------

            local character =
                getCharacter()


            local humanoid =
                character:FindFirstChildOfClass(
                    "Humanoid"
                )

            if not humanoid then

                warn(
                    "[Salute] Humanoid tidak ditemukan."
                )

                return

            end


            ------------------------------------------------------------
            -- PLAY EMOTE WITH RETRY
            ------------------------------------------------------------
            -- Setelah !stop, Animator kadang masih melakukan cleanup.
            -- Karena itu emote dicoba beberapa kali dengan jeda kecil.

            local maxAttempts = 3

            local success = false
            local result = nil


            for attempt = 1, maxAttempts do

                --------------------------------------------------------
                -- COMMAND SUDAH BERGANTI
                --------------------------------------------------------

                if generation ~= saluteGeneration then
                    return
                end


                --------------------------------------------------------
                -- PLAY EMOTE
                --------------------------------------------------------

                local ok, track =
                    pcall(function()

                        return humanoid:
                            PlayEmoteAndGetAnimTrackById(
                                SALUTE_EMOTE_ID
                            )

                    end)


                if ok and track then

                    success = true
                    result = track

                    break

                end


                result = track


                --------------------------------------------------------
                -- JIKA GAGAL, BERI WAKTU UNTUK ANIMATOR
                --------------------------------------------------------

                if attempt < maxAttempts then

                    task.wait(0.1)

                end

            end


            ------------------------------------------------------------
            -- VALIDATE GENERATION SETELAH RETRY
            ------------------------------------------------------------

            if generation ~= saluteGeneration then

                if result then

                    pcall(function()
                        result:Stop(0)
                    end)

                end

                return

            end


            ------------------------------------------------------------
            -- RESULT
            ------------------------------------------------------------

            if success and result then

                saluteTrack = result
                saluting = true


                print(
                    "[Salute] Emote berhasil dimainkan:",
                    SALUTE_EMOTE_ID,
                    "| Attempt:",
                    "success"
                )


                --------------------------------------------------------
                -- MONITOR TRACK
                --------------------------------------------------------

                task.spawn(function()

                    local track =
                        result

                    local trackGeneration =
                        generation


                    if not track then
                        return
                    end


                    pcall(function()
                        track.Stopped:Wait()
                    end)


                    ----------------------------------------------------
                    -- HANYA BOLEH MEMBERSIHKAN TRACK
                    -- JIKA MASIH TRACK + GENERATION YANG SAMA
                    ----------------------------------------------------

                    if saluteTrack == track
                        and saluting
                        and trackGeneration
                            == saluteGeneration then

                        saluteTrack = nil

                    end

                end)


            else

                warn(
                    "[Salute] Emote gagal dimainkan setelah",
                    maxAttempts,
                    "percobaan.",
                    "| Bot:",
                    LocalPlayer.Name,
                    "| Last Error:",
                    result
                )

            end

        end


        ----------------------------------------------------------------
        -- COMMAND HANDLER
        ----------------------------------------------------------------

        local function handleCommand(
            message,
            sender
        )

            if not message then
                return
            end


            if not sender then
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
                lower:gsub(
                    "^%s+",
                    ""
                )


            lower =
                lower:gsub(
                    "%s+$",
                    ""
                )


            ------------------------------------------------------------
            -- !SALUTE
            ------------------------------------------------------------

            if lower == "!salute" then

                print(
                    "[Salute] Command diterima dari:",
                    sender.Name
                )


                playSalute()


                return

            end


            ------------------------------------------------------------
            -- !UNSALUTE
            ------------------------------------------------------------

            if lower == "!unsalute" then

                print(
                    "[Salute] Unsalute command dari:",
                    sender.Name
                )


                --------------------------------------------------------
                -- HANYA UBAH ACTIVE MODE JIKA SALUTE MEMANG AKTIF
                --------------------------------------------------------

                if _G.BotVars.ActiveMode
                    == "salute" then

                    _G.BotVars.ActiveMode = nil

                    stopSalute()

                end


                return

            end


            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if lower == "!stop" then

                print(
                    "[Salute] Stop command dari:",
                    sender.Name
                )


                --------------------------------------------------------
                -- PENTING:
                -- Salute HANYA melakukan cleanup jika Salute
                -- memang merupakan ActiveMode.
                --
                -- Jika misalnya mode aktif adalah:
                --
                -- follow
                -- rest
                -- frontline
                --
                -- module Salute tidak akan ikut mereset Animator.
                --------------------------------------------------------

                if _G.BotVars.ActiveMode
                    == "salute" then

                    _G.BotVars.ActiveMode = nil

                    stopSalute()

                end


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

                saluteGeneration =
                    saluteGeneration + 1

                local generation =
                    saluteGeneration


                saluteTrack = nil
                saluting = false


                --------------------------------------------------------
                -- JIKA MASIH MODE SALUTE
                --------------------------------------------------------

                if _G.BotVars.ActiveMode
                    == "salute" then

                    task.wait(0.5)


                    ----------------------------------------------------
                    -- PASTIKAN BELUM ADA COMMAND BARU
                    ----------------------------------------------------

                    if generation
                        ~= saluteGeneration then

                        return

                    end


                    playSalute()

                end

            end
        )


        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[Salute] Loaded untuk:",
            LocalPlayer.Name,
            "| Emote:",
            SALUTE_EMOTE_ID
        )

    end
}