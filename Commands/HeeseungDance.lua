return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[HeeseungDance] LocalPlayer tidak ditemukan.")
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

                warn("[HeeseungDance] Gagal load Admin.lua.")
                return

            end
        end


        ----------------------------------------------------------------
        -- FE ANIMATION ID
        ----------------------------------------------------------------

        local HEESEUNG_DANCE_ANIMATION_ID =
            "102398076892201"


        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local danceTrack = nil
        local dancing = false

        -- Generation digunakan untuk memastikan proses lama
        -- dari !stop / !heeseungdance tidak mengganggu command terbaru.
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
                "[HeeseungDance] Animasi normal dipulihkan."
            )

        end


        ----------------------------------------------------------------
        -- STOP ATEEZ DANCE
        ----------------------------------------------------------------

        local function stopHeeseungDance()

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

        _G.BotVars.ModeControllers.heeseungdance =
            stopHeeseungDance


        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "heeseungdance"
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

        local function playHeeseungDance()

            ------------------------------------------------------------
            -- NEW GENERATION
            ------------------------------------------------------------

            danceGeneration =
                danceGeneration + 1

            local generation =
                danceGeneration


            ------------------------------------------------------------
            -- SET ACTIVE MODE
            ------------------------------------------------------------

            _G.BotVars.ActiveMode =
                "heeseungdance"


            ------------------------------------------------------------
            -- STOP MODE LAIN
            ------------------------------------------------------------

            stopOtherModes()


            ------------------------------------------------------------
            -- VALIDATE GENERATION
            ------------------------------------------------------------

            if generation ~= danceGeneration then
                return
            end


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
                    "[HeeseungDance] Humanoid tidak ditemukan."
                )

                return

            end


            ------------------------------------------------------------
            -- PLAY FE ANIMATION WITH RETRY
            ------------------------------------------------------------
            -- Menggunakan Humanoid:PlayEmoteAndGetAnimTrackById()
            -- sehingga animasi dijalankan sebagai FE animation.

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
                                HEESEUNG_DANCE_ANIMATION_ID
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
                    "[HeeseungDance] FE Animation berhasil dimainkan:",
                    HEESEUNG_DANCE_ANIMATION_ID,
                    "| Bot:",
                    LocalPlayer.Name
                )


                --------------------------------------------------------
                -- MONITOR TRACK
                --------------------------------------------------------

                task.spawn(function()

                    local track = result
                    local trackGeneration = generation

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

                    if danceTrack == track
                        and dancing
                        and trackGeneration
                            == danceGeneration then

                        danceTrack = nil

                    end

                end)

            else

                warn(
                    "[HeeseungDance] FE Animation gagal dimainkan setelah",
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

            if lower == "!heeseungdance" then

                print(
                    "[HeeseungDance] Command diterima | Bot:",
                    LocalPlayer.Name,
                    "| Admin:",
                    sender.Name
                )

                playHeeseungDance()

                return

            end


            ------------------------------------------------------------
            -- !UNATEEZDANCE
            ------------------------------------------------------------

            if lower == "!unheeseungdance" then

                print(
                    "[HeeseungDance] UnHeeseungDance | Bot:",
                    LocalPlayer.Name,
                    "| Admin:",
                    sender.Name
                )

                if _G.BotVars.ActiveMode
                    == "heeseungdance" then

                    _G.BotVars.ActiveMode = nil

                end

                stopHeeseungDance()

                return

            end


            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if lower == "!stop" then

                print(
                    "[HeeseungDance] Stop | Bot:",
                    LocalPlayer.Name,
                    "| Admin:",
                    sender.Name
                )

                if _G.BotVars.ActiveMode
                    == "heeseungdance" then

                    _G.BotVars.ActiveMode = nil

                end

                stopHeeseungDance()

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
                    == "heeseungdance" then

                    task.wait(0.5)


                    ----------------------------------------------------
                    -- PASTIKAN BELUM ADA COMMAND BARU
                    ----------------------------------------------------

                    if generation
                        ~= danceGeneration then

                        return

                    end

                    playHeeseungDance()

                end

            end
        )


        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[HeeseungDance] Loaded untuk:",
            LocalPlayer.Name,
            "| FE Animation:",
            HEESEUNG_DANCE_ANIMATION_ID
        )

    end
}
