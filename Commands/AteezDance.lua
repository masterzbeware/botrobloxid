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

        local danceGeneration = 0

        local danceLoopThread = nil

        local connectedPlayers = {}


        ----------------------------------------------------------------
        -- GLOBAL ATEEZ STATE
        ----------------------------------------------------------------

        _G.BotVars.AteezDanceActive =
            _G.BotVars.AteezDanceActive or false


        ----------------------------------------------------------------
        -- GET CHARACTER
        ----------------------------------------------------------------

        local function getCharacter()

            return LocalPlayer.Character
                or LocalPlayer.CharacterAdded:Wait()

        end


        ----------------------------------------------------------------
        -- GET HUMANOID
        ----------------------------------------------------------------

        local function getHumanoid()

            local character =
                LocalPlayer.Character

            if not character then
                return nil
            end


            return character:FindFirstChildOfClass(
                "Humanoid"
            )

        end


        ----------------------------------------------------------------
        -- STOP CURRENT TRACK
        ----------------------------------------------------------------

        local function stopCurrentTrack()

            if danceTrack then

                local oldTrack =
                    danceTrack

                danceTrack = nil

                pcall(function()
                    oldTrack:Stop(0.15)
                end)

            end

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
            -- GENERATION CHECK
            ------------------------------------------------------------

            if generation
                and generation ~= danceGeneration then

                return

            end


            ------------------------------------------------------------
            -- STOP ATEEZ TRACK
            ------------------------------------------------------------

            stopCurrentTrack()


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
            -- RESTART DEFAULT ANIMATE
            ------------------------------------------------------------

            local animateScript =
                character:FindFirstChild("Animate")

            if animateScript
                and animateScript:IsA("LocalScript") then

                pcall(function()
                    animateScript.Enabled = false
                end)

                task.wait()


                if generation
                    and generation ~= danceGeneration then

                    return

                end


                pcall(function()
                    animateScript.Enabled = true
                end)

            end


            ------------------------------------------------------------
            -- RESTORE RUNNING STATE
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


            task.defer(function()

                task.wait(0.1)


                if generation
                    and generation ~= danceGeneration then

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
        -- PLAY SINGLE ATEEZ TRACK
        ----------------------------------------------------------------

        local function playSingleAteezTrack(
            generation
        )

            ------------------------------------------------------------
            -- VALIDATE
            ------------------------------------------------------------

            if not _G.BotVars.AteezDanceActive then
                return nil
            end


            if generation
                and generation ~= danceGeneration then

                return nil

            end


            ------------------------------------------------------------
            -- HUMANOID
            ------------------------------------------------------------

            local humanoid =
                getHumanoid()

            if not humanoid then

                return nil

            end


            ------------------------------------------------------------
            -- STOP OLD TRACK
            ------------------------------------------------------------

            stopCurrentTrack()


            ------------------------------------------------------------
            -- PLAY WITH RETRY
            ------------------------------------------------------------

            local maxAttempts = 3

            local result = nil


            for attempt = 1, maxAttempts do

                --------------------------------------------------------
                -- VALIDATE STATE
                --------------------------------------------------------

                if not _G.BotVars.AteezDanceActive then
                    return nil
                end


                if generation
                    and generation ~= danceGeneration then

                    return nil

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

                    result = track

                    break

                end


                result = track


                --------------------------------------------------------
                -- RETRY DELAY
                --------------------------------------------------------

                if attempt < maxAttempts then

                    task.wait(0.15)

                end

            end


            ------------------------------------------------------------
            -- VALIDATE RESULT
            ------------------------------------------------------------

            if not result then

                return nil

            end


            if not _G.BotVars.AteezDanceActive then

                pcall(function()
                    result:Stop(0)
                end)

                return nil

            end


            if generation
                and generation ~= danceGeneration then

                pcall(function()
                    result:Stop(0)
                end)

                return nil

            end


            ------------------------------------------------------------
            -- STORE TRACK
            ------------------------------------------------------------

            danceTrack = result

            dancing = true


            ------------------------------------------------------------
            -- TRY LOOPED
            ------------------------------------------------------------
            --
            -- Tetap gunakan watchdog sebagai fallback.
            --
            ------------------------------------------------------------

            pcall(function()

                result.Looped = true

            end)


            print(
                "[AteezDance] Animation dimainkan:",
                ATEEZ_DANCE_ANIMATION_ID,
                "| Bot:",
                LocalPlayer.Name
            )


            return result

        end


        ----------------------------------------------------------------
        -- ATEEZ WATCHDOG
        ----------------------------------------------------------------

        local function startDanceWatchdog(
            generation
        )

            ------------------------------------------------------------
            -- PREVENT MULTIPLE WATCHDOG
            ------------------------------------------------------------

            if danceLoopThread then
                return
            end


            danceLoopThread =
                task.spawn(function()

                    while true do

                        ------------------------------------------------
                        -- CHECK ACTIVE
                        ------------------------------------------------

                        if not _G.BotVars.AteezDanceActive then

                            break

                        end


                        ------------------------------------------------
                        -- CHECK GENERATION
                        ------------------------------------------------

                        if generation
                            ~= danceGeneration then

                            break

                        end


                        ------------------------------------------------
                        -- CHECK CHARACTER
                        ------------------------------------------------

                        local humanoid =
                            getHumanoid()


                        if not humanoid then

                            task.wait(0.5)

                            continue

                        end


                        ------------------------------------------------
                        -- CHECK CURRENT TRACK
                        ------------------------------------------------

                        local currentTrack =
                            danceTrack


                        local needsRestart = false


                        if not currentTrack then

                            needsRestart = true

                        else

                            local isPlaying = false


                            pcall(function()

                                isPlaying =
                                    currentTrack.IsPlaying

                            end)


                            if not isPlaying then

                                needsRestart = true

                            end

                        end


                        ------------------------------------------------
                        -- RESTART IF NEEDED
                        ------------------------------------------------

                        if needsRestart then

                            if _G.BotVars.AteezDanceActive
                                and generation
                                    == danceGeneration then

                                playSingleAteezTrack(
                                    generation
                                )

                            end

                        end


                        ------------------------------------------------
                        -- WATCHDOG INTERVAL
                        ------------------------------------------------

                        task.wait(0.25)

                    end


                    ----------------------------------------------------
                    -- THREAD FINISHED
                    ----------------------------------------------------

                    if danceLoopThread
                        == coroutine.running() then

                        danceLoopThread = nil

                    end

                end)

        end


        ----------------------------------------------------------------
        -- STOP ATEEZ DANCE
        ----------------------------------------------------------------

        local function stopAteezDance()

            ------------------------------------------------------------
            -- INVALIDATE OLD PROCESSES
            ------------------------------------------------------------

            danceGeneration =
                danceGeneration + 1


            local generation =
                danceGeneration


            ------------------------------------------------------------
            -- GLOBAL STATE OFF
            ------------------------------------------------------------

            _G.BotVars.AteezDanceActive =
                false


            dancing = false


            ------------------------------------------------------------
            -- STOP TRACK
            ------------------------------------------------------------

            stopCurrentTrack()


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

        _G.BotVars.ModeControllers.ateezdance =
            stopAteezDance


        ----------------------------------------------------------------
        -- START ATEEZ DANCE
        ----------------------------------------------------------------

        local function startAteezDance()

            ------------------------------------------------------------
            -- INVALIDATE OLD GENERATION
            ------------------------------------------------------------

            danceGeneration =
                danceGeneration + 1


            local generation =
                danceGeneration


            ------------------------------------------------------------
            -- ACTIVE
            ------------------------------------------------------------

            _G.BotVars.AteezDanceActive =
                true


            dancing = true


            ------------------------------------------------------------
            -- PLAY FIRST TRACK
            ------------------------------------------------------------

            local track =
                playSingleAteezTrack(
                    generation
                )


            if not track then

                dancing = false

                warn(
                    "[AteezDance] Gagal memainkan animation."
                )

                return

            end


            ------------------------------------------------------------
            -- START WATCHDOG
            ------------------------------------------------------------

            startDanceWatchdog(
                generation
            )


            print(
                "[AteezDance] Persistent Dance aktif."
            )

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
                    "| Follow:",
                    tostring(
                        _G.BotVars.ActiveMode == "follow"
                    )
                )


                startAteezDance()


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


                stopAteezDance()


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


                stopAteezDance()


                return

            end

        end


        ----------------------------------------------------------------
        -- CHAT HANDLER
        ----------------------------------------------------------------

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
                -- WAIT FOR CHARACTER
                --------------------------------------------------------

                task.wait(1)


                --------------------------------------------------------
                -- RESTART DANCE AFTER RESPAWN
                --------------------------------------------------------

                if not _G.BotVars.AteezDanceActive then
                    return
                end


                if generation
                    ~= danceGeneration then

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


                task.wait(0.5)


                --------------------------------------------------------
                -- PLAY AGAIN
                --------------------------------------------------------

                if _G.BotVars.AteezDanceActive
                    and generation
                        == danceGeneration then

                    playSingleAteezTrack(
                        generation
                    )


                    startDanceWatchdog(
                        generation
                    )

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
            "| Persistent Loop: ENABLED",
            "| Follow compatibility: ENABLED"
        )

    end
}