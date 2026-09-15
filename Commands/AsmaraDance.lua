return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[AsmaraDance] LocalPlayer tidak ditemukan.")
            return
        end


        ----------------------------------------------------------------
        -- GLOBAL MODE SYSTEM
        ----------------------------------------------------------------

        _G.BotVars = _G.BotVars or {}
        _G.BotVars.ModeControllers = _G.BotVars.ModeControllers or {}


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

                warn("[AsmaraDance] Gagal load Admin.lua.")
                return

            end
        end


        ----------------------------------------------------------------
        -- ANIMATION ID
        ----------------------------------------------------------------

        local ASMARA_DANCE_ANIMATION_ID = "102234069757813"


        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local danceTrack = nil
        local dancing = false
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

            local character = LocalPlayer.Character

            if not character then
                return
            end

            local humanoid = character:FindFirstChildOfClass("Humanoid")

            if not humanoid then
                return
            end

            if generation
                and generation ~= danceGeneration then

                return

            end


            ------------------------------------------------------------
            -- STOP ASMARA DANCE
            ------------------------------------------------------------

            if danceTrack then

                local oldTrack = danceTrack
                danceTrack = nil

                pcall(function()
                    oldTrack:Stop(0.15)
                end)

            end


            ------------------------------------------------------------
            -- STOP ACTION TRACKS
            ------------------------------------------------------------

            local animator =
                humanoid:FindFirstChildOfClass("Animator")

            if animator then

                for _, track in ipairs(
                    animator:GetPlayingAnimationTracks()
                ) do

                    if track.Priority == Enum.AnimationPriority.Action
                        or track.Priority == Enum.AnimationPriority.Action2
                        or track.Priority == Enum.AnimationPriority.Action3
                        or track.Priority == Enum.AnimationPriority.Action4 then

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

                if generation
                    and generation ~= danceGeneration then

                    return

                end

                pcall(function()
                    animateScript.Enabled = true
                end)

            end


            ------------------------------------------------------------
            -- FORCE RUNNING STATE
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

                if cleanupGeneration ~= danceGeneration then
                    return
                end

                if humanoid and humanoid.Parent then

                    pcall(function()

                        humanoid:ChangeState(
                            Enum.HumanoidStateType.Running
                        )

                    end)

                end

            end)


            print("[AsmaraDance] Animasi normal dipulihkan.")

        end


        ----------------------------------------------------------------
        -- STOP ASMARA DANCE
        ----------------------------------------------------------------

        local function stopAsmaraDance()

            danceGeneration =
                danceGeneration + 1

            local generation =
                danceGeneration

            dancing = false


            ------------------------------------------------------------
            -- STOP CURRENT TRACK
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

        end


        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.asmaradance =
            stopAsmaraDance


        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "asmaradance"
                    and type(stopFunction) == "function" then

                    pcall(function()
                        stopFunction()
                    end)

                end

            end

        end


        ----------------------------------------------------------------
        -- PLAY ASMARA DANCE
        ----------------------------------------------------------------

        local function playAsmaraDance()

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
                "asmaradance"


            ------------------------------------------------------------
            -- STOP OTHER MODES
            ------------------------------------------------------------

            stopOtherModes()


            ------------------------------------------------------------
            -- VALIDATE
            ------------------------------------------------------------

            if generation ~= danceGeneration then
                return
            end


            ------------------------------------------------------------
            -- STOP OLD TRACK
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
                character:FindFirstChildOfClass("Humanoid")

            if not humanoid then

                warn(
                    "[AsmaraDance] Humanoid tidak ditemukan."
                )

                return

            end


            ------------------------------------------------------------
            -- GET ANIMATOR
            ------------------------------------------------------------

            local animator =
                humanoid:FindFirstChildOfClass("Animator")

            if not animator then

                animator =
                    Instance.new("Animator")

                animator.Parent =
                    humanoid

            end


            ------------------------------------------------------------
            -- PLAY ANIMATION
            ------------------------------------------------------------

            local success = false
            local result = nil
            local lastError = nil


            ------------------------------------------------------------
            -- METHOD 1
            -- PlayEmoteAndGetAnimTrackById
            ------------------------------------------------------------

            for attempt = 1, 3 do

                if generation ~= danceGeneration then
                    return
                end

                local ok, trackOrError =
                    pcall(function()

                        return humanoid:PlayEmoteAndGetAnimTrackById(
                            ASMARA_DANCE_ANIMATION_ID
                        )

                    end)

                if ok and trackOrError then

                    success = true
                    result = trackOrError

                    print(
                        "[AsmaraDance] Berhasil menggunakan PlayEmoteAndGetAnimTrackById."
                    )

                    break

                else

                    lastError = trackOrError

                    warn(
                        "[AsmaraDance] Percobaan",
                        attempt,
                        "gagal:",
                        trackOrError
                    )

                end

                if attempt < 3 then
                    task.wait(0.2)
                end

            end


            ------------------------------------------------------------
            -- METHOD 2
            -- Animator:LoadAnimation
            ------------------------------------------------------------

            if not success then

                if generation ~= danceGeneration then
                    return
                end

                print(
                    "[AsmaraDance] Mencoba metode Animator:LoadAnimation..."
                )


                local animation =
                    Instance.new("Animation")

                animation.AnimationId =
                    "rbxassetid://" .. ASMARA_DANCE_ANIMATION_ID


                local ok, trackOrError =
                    pcall(function()

                        local track =
                            animator:LoadAnimation(animation)

                        track.Priority =
                            Enum.AnimationPriority.Action

                        track.Looped = true

                        track:Play(
                            0.15,
                            1,
                            1
                        )

                        return track

                    end)


                if ok and trackOrError then

                    success = true
                    result = trackOrError

                    print(
                        "[AsmaraDance] Berhasil menggunakan Animator:LoadAnimation."
                    )

                else

                    lastError =
                        trackOrError

                    warn(
                        "[AsmaraDance] Animator:LoadAnimation juga gagal:",
                        trackOrError
                    )

                end

            end


            ------------------------------------------------------------
            -- VALIDATE GENERATION
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
            -- SUCCESS
            ------------------------------------------------------------

            if success and result then

                danceTrack =
                    result

                dancing =
                    true


                print(
                    "[AsmaraDance] FE Animation berhasil dimainkan:",
                    ASMARA_DANCE_ANIMATION_ID,
                    "| Bot:",
                    LocalPlayer.Name
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


                    if danceTrack == track
                        and dancing
                        and trackGeneration == danceGeneration then

                        danceTrack =
                            nil

                    end

                end)


            else

                warn(
                    "[AsmaraDance] Animation gagal dimainkan.",
                    "| ID:",
                    ASMARA_DANCE_ANIMATION_ID,
                    "| Bot:",
                    LocalPlayer.Name,
                    "| Last Error:",
                    lastError
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

            local isAdmin =
                false

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
            -- !ASMARADANCE
            ------------------------------------------------------------

            if lower == "!asmaradance" then

                print(
                    "[AsmaraDance] Command diterima | Bot:",
                    LocalPlayer.Name,
                    "| Admin:",
                    sender.Name
                )

                playAsmaraDance()

                return

            end


            ------------------------------------------------------------
            -- !UNASMARADANCE
            ------------------------------------------------------------

            if lower == "!unasmaradance" then

                print(
                    "[AsmaraDance] UnAsmaraDance | Bot:",
                    LocalPlayer.Name,
                    "| Admin:",
                    sender.Name
                )

                if _G.BotVars.ActiveMode
                    == "asmaradance" then

                    _G.BotVars.ActiveMode =
                        nil

                end

                stopAsmaraDance()

                return

            end


            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if lower == "!stop" then

                print(
                    "[AsmaraDance] Stop | Bot:",
                    LocalPlayer.Name,
                    "| Admin:",
                    sender.Name
                )

                if _G.BotVars.ActiveMode
                    == "asmaradance" then

                    _G.BotVars.ActiveMode =
                        nil

                end

                stopAsmaraDance()

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

                connectedPlayers[player] =
                    nil

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

                danceTrack =
                    nil

                dancing =
                    false


                --------------------------------------------------------
                -- IF STILL ASMARA MODE
                --------------------------------------------------------

                if _G.BotVars.ActiveMode
                    == "asmaradance" then

                    task.wait(0.5)


                    if generation
                        ~= danceGeneration then

                        return

                    end


                    playAsmaraDance()

                end

            end
        )


        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[AsmaraDance] Loaded untuk:",
            LocalPlayer.Name,
            "| Animation ID:",
            ASMARA_DANCE_ANIMATION_ID
        )

    end
}