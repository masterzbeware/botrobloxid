return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[AteezDance] LocalPlayer tidak ditemukan.")
            return
        end


        ----------------------------------------------------------------
        -- GLOBAL SYSTEM
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

                warn("[AteezDance] Gagal load Admin.lua.")
                return

            end

        end


        ----------------------------------------------------------------
        -- FE ANIMATION ID
        ----------------------------------------------------------------

        local ATEEZ_DANCE_ANIMATION_ID =
            "111003986858991"


        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local danceTrack = nil

        local dancing = false

        -- Generation digunakan untuk membatalkan proses dance lama.
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
            -- STOP ATEEZ DANCE TRACK
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
            -- FORCE HUMANOID RUNNING
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
                "[AteezDance] Animasi normal dipulihkan."
            )

        end


        ----------------------------------------------------------------
        -- STOP ATEEZ DANCE ONLY
        ----------------------------------------------------------------

        local function stopAteezDance()

            ------------------------------------------------------------
            -- INVALIDATE OLD PROCESSES
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
            -- RESTORE NORMAL ANIMATION
            ------------------------------------------------------------

            restoreNormalAnimation(
                generation
            )


            print(
                "[AteezDance] Dance dihentikan."
            )

        end


        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------
        --
        -- IMPORTANT:
        -- Controller ini HANYA mengontrol Ateez Dance.
        --
        -- Jangan mengubah ActiveMode karena Follow.lua menggunakan
        -- ActiveMode == "follow" sebagai indikator bahwa Follow aktif.
        --
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.ateezdance =
            stopAteezDance


        ----------------------------------------------------------------
        -- PLAY ATEEZ DANCE
        ----------------------------------------------------------------

        local function playAteezDance()

            ------------------------------------------------------------
            -- NEW GENERATION
            ------------------------------------------------------------

            danceGeneration =
                danceGeneration + 1

            local generation =
                danceGeneration


            ------------------------------------------------------------
            -- JANGAN UBAH ActiveMode
            ------------------------------------------------------------
            --
            -- Jika Follow sedang aktif:
            --
            --     _G.BotVars.ActiveMode == "follow"
            --
            -- Biarkan nilai tersebut tetap "follow".
            --
            -- Dengan begitu Heartbeat Follow.lua tetap berjalan.
            --
            ------------------------------------------------------------


            ------------------------------------------------------------
            -- STOP PREVIOUS DANCE TRACK
            ------------------------------------------------------------

            if danceTrack then

                local oldTrack =
                    danceTrack

                danceTrack = nil

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
                    "[AteezDance] Humanoid tidak ditemukan."
                )

                return

            end


            ------------------------------------------------------------
            -- PLAY FE ANIMATION WITH RETRY
            ------------------------------------------------------------

            local maxAttempts = 3

            local success = false

            local result = nil


            for attempt = 1, maxAttempts do

                --------------------------------------------------------
                -- COMMAND SUDAH BERGANTI
                --------------------------------------------------------

                if generation ~= danceGeneration then
                    return
                end


                --------------------------------------------------------
                -- PLAY FE ANIMATION
                --------------------------------------------------------

                local ok, track =
                    pcall(function()

                        return humanoid:
                            PlayEmoteAndGetAnimTrackById(
                                ATEEZ_DANCE_ANIMATION_ID
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


            ------------------------------------------------------------
            -- VALIDATE GENERATION AFTER RETRY
            ------------------------------------------------------------

            if generation ~= danceGeneration then

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

                danceTrack = result

                dancing = true


                print(
                    "[AteezDance] FE Animation berhasil dimainkan:",
                    ATEEZ_DANCE_ANIMATION_ID,
                    "| Bot:",
                    LocalPlayer.Name,
                    "| Follow:",
                    tostring(
                        _G.BotVars.ActiveMode == "follow"
                    )
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
                    -- ONLY CLEAN CURRENT TRACK
                    ----------------------------------------------------

                    if danceTrack == track
                        and dancing
                        and trackGeneration
                            == danceGeneration then

                        danceTrack = nil

                        dancing = false

                    end

                end)

            else

                warn(
                    "[AteezDance] FE Animation gagal dimainkan setelah",
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

            if lower == "!ateezdance" then

                print(
                    "[AteezDance] Command diterima | Bot:",
                    LocalPlayer.Name,
                    "| Admin:",
                    sender.Name,
                    "| ActiveMode sebelum:",
                    tostring(
                        _G.BotVars.ActiveMode
                    )
                )


                --------------------------------------------------------
                -- IMPORTANT
                --------------------------------------------------------
                --
                -- Tidak memanggil stopOtherModes().
                --
                -- Tidak mengubah ActiveMode.
                --
                -- Jadi apabila Follow aktif:
                --
                -- ActiveMode tetap "follow"
                --
                --------------------------------------------------------

                playAteezDance()


                print(
                    "[AteezDance] Dance aktif | ActiveMode:",
                    tostring(
                        _G.BotVars.ActiveMode
                    )
                )


                return

            end


            ------------------------------------------------------------
            -- !UNATEEZDANCE
            ------------------------------------------------------------

            if lower == "!unateezdance" then

                print(
                    "[AteezDance] UnAteezDance | Bot:",
                    LocalPlayer.Name,
                    "| Admin:",
                    sender.Name
                )


                --------------------------------------------------------
                -- HANYA STOP DANCE
                --------------------------------------------------------

                stopAteezDance()


                --------------------------------------------------------
                -- JANGAN SENTUH ActiveMode
                --------------------------------------------------------
                --
                -- Jika Follow aktif:
                --
                -- ActiveMode tetap "follow"
                --
                --------------------------------------------------------


                return

            end


            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if lower == "!stop" then

                print(
                    "[AteezDance] Stop | Bot:",
                    LocalPlayer.Name,
                    "| Admin:",
                    sender.Name
                )


                --------------------------------------------------------
                -- STOP DANCE SAJA
                --
                -- Follow.lua akan menerima !stop secara terpisah
                -- dan menghentikan Follow-nya sendiri.
                --
                --------------------------------------------------------

                stopAteezDance()


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
                -- INVALIDATE OLD TRACK
                --------------------------------------------------------

                danceGeneration =
                    danceGeneration + 1


                local generation =
                    danceGeneration


                danceTrack = nil

                dancing = false


                --------------------------------------------------------
                -- JIKA DANCE MASIH AKTIF
                --------------------------------------------------------
                --
                -- Kita tidak menggunakan ActiveMode lagi.
                --
                -- Jadi status dance disimpan melalui flag dancing
                -- sebelum respawn.
                --
                --------------------------------------------------------

                task.wait(0.5)


                --------------------------------------------------------
                -- JANGAN MEMAKSA DANCE JIKA SUDAH DI-STOP
                --------------------------------------------------------

                if generation
                    ~= danceGeneration then

                    return

                end

            end
        )


        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[AteezDance] Loaded untuk:",
            LocalPlayer.Name,
            "| FE Animation:",
            ATEEZ_DANCE_ANIMATION_ID,
            "| Follow compatibility: ENABLED"
        )

    end
}