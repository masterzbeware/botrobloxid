return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[Worship] LocalPlayer tidak ditemukan.")
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

                warn("[Worship] Gagal load Admin.lua.")
                return

            end
        end


        ----------------------------------------------------------------
        -- FE ANIMATION ID
        ----------------------------------------------------------------

        local WORSHIP_ANIMATION_ID =
            "138036067355205"


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
            -- STOP WORSHIP TRACK
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
                character:FindFirstChild(
                    "Animate"
                )


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
            -- FORCE RUNNING
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
                generation
                or danceGeneration


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
                "[Worship] Animasi normal dipulihkan."
            )

        end


        ----------------------------------------------------------------
        -- STOP WORSHIP
        ----------------------------------------------------------------

        local function stopWorship()

            ------------------------------------------------------------
            -- INVALIDATE PROSES LAMA
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


            ----------------------------------------------------------------
            -- PENTING:
            --
            -- JANGAN:
            -- _G.BotVars.CommandTarget = nil
            --
            -- CommandTarget hanya dihapus oleh !stop ADMIN.
            ----------------------------------------------------------------

        end


        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.worship =
            stopWorship


        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "worship"
                    and type(stopFunction) == "function" then

                    pcall(function()

                        stopFunction()

                    end)

                end

            end

        end


        ----------------------------------------------------------------
        -- PLAY WORSHIP
        ----------------------------------------------------------------

        local function playWorship(targetPlayer)

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
                "worship"


            ------------------------------------------------------------
            -- SET COMMAND TARGET
            --
            -- Jika target diberikan oleh Admin:
            -- target menjadi CommandTarget.
            --
            -- Jika dipanggil tanpa target:
            -- caller sudah menjadi CommandTarget dari handler.
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
                ~= danceGeneration then

                return

            end


            ------------------------------------------------------------
            -- STOP PREVIOUS TRACK
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
                    "[Worship] Humanoid tidak ditemukan."
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

                if generation
                    ~= danceGeneration then

                    return

                end


                --------------------------------------------------------
                -- PLAY FE ANIMATION
                --------------------------------------------------------

                local ok, track =
                    pcall(function()

                        return humanoid:
                            PlayEmoteAndGetAnimTrackById(
                                WORSHIP_ANIMATION_ID
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
            -- VALIDATE GENERATION
            ------------------------------------------------------------

            if generation
                ~= danceGeneration then

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
                    "[Worship] FE Animation berhasil dimainkan:",
                    WORSHIP_ANIMATION_ID,
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


                    ----------------------------------------------------
                    -- CLEAN TRACK ONLY IF STILL VALID
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
                    "[Worship] FE Animation gagal dimainkan setelah",
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
        -- FIND PLAYER
        ----------------------------------------------------------------

        local function findPlayerByName(name)

            if not name
                or name == "" then

                return nil

            end


            name =
                name:lower()


            ------------------------------------------------------------
            -- EXACT USERNAME / DISPLAY NAME
            ------------------------------------------------------------

            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if player.Name:lower() == name
                    or player.DisplayName:lower() == name then

                    return player

                end

            end


            ------------------------------------------------------------
            -- PREFIX USERNAME
            ------------------------------------------------------------

            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if player.Name:lower():sub(
                    1,
                    #name
                ) == name then

                    return player

                end

            end


            return nil

        end


        ----------------------------------------------------------------
        -- COMMAND HANDLER
        ----------------------------------------------------------------

        local function handleCommand(
            message,
            sender
        )

            if not message
                or not sender then

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
            -- CURRENT COMMAND TARGET
            ------------------------------------------------------------

            local commandTarget =
                _G.BotVars.CommandTarget


            local isCommandTarget =
                (
                    commandTarget
                    == sender
                )


            ------------------------------------------------------------
            -- CLEAN MESSAGE
            ------------------------------------------------------------

            local lower =
                message
                :lower()
                :gsub(
                    "^%s+",
                    ""
                )
                :gsub(
                    "%s+$",
                    ""
                )


            ----------------------------------------------------------------
            -- !STOP
            --
            -- HANYA ADMIN
            ----------------------------------------------------------------

            if lower == "!stop" then

                if not isAdmin then

                    print(
                        "[Worship] !stop ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end


                print(
                    "[Worship] !stop diterima | Admin:",
                    sender.Name
                )


                --------------------------------------------------------
                -- CLEAR GLOBAL STATE
                --------------------------------------------------------

                _G.BotVars.ActiveMode = nil

                _G.BotVars.CommandTarget = nil


                --------------------------------------------------------
                -- STOP SEMUA MODE
                --------------------------------------------------------

                for _, stopFunction in pairs(
                    _G.BotVars.ModeControllers
                ) do

                    if type(stopFunction)
                        == "function" then

                        pcall(function()

                            stopFunction()

                        end)

                    end

                end


                return

            end


            ----------------------------------------------------------------
            -- !UNWORSHIP
            --
            -- HANYA ADMIN
            ----------------------------------------------------------------

            if lower == "!unworship" then

                if not isAdmin then

                    print(
                        "[Worship] !unworship ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end


                print(
                    "[Worship] !unworship diterima | Admin:",
                    sender.Name
                )


                if _G.BotVars.ActiveMode
                    == "worship" then

                    _G.BotVars.ActiveMode = nil

                end


                stopWorship()


                return

            end


            ----------------------------------------------------------------
            -- !WORSHIP
            --
            -- ADMIN:
            --     !worship
            --
            -- COMMAND TARGET:
            --     !worship
            ----------------------------------------------------------------

            if lower == "!worship" then

                if not isAdmin
                    and not isCommandTarget then

                    print(
                        "[Worship] !worship ditolak:",
                        sender.Name
                    )

                    return

                end


                print(
                    "[Worship] !worship diterima | Sender:",
                    sender.Name,
                    "| Admin:",
                    isAdmin,
                    "| CommandTarget:",
                    isCommandTarget
                )


                --------------------------------------------------------
                -- TARGET = SENDER
                --------------------------------------------------------

                _G.BotVars.CommandTarget =
                    sender


                playWorship(
                    sender
                )


                return

            end


            ----------------------------------------------------------------
            -- !WORSHIP PLAYER
            --
            -- HANYA ADMIN
            ----------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!worship%s+(.+)$"
                )


            if targetName then

                if not isAdmin then

                    print(
                        "[Worship] !worship PLAYER ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end


                local target =
                    findPlayerByName(
                        targetName
                    )


                if not target then

                    warn(
                        "[Worship] Player tidak ditemukan:",
                        targetName
                    )

                    return

                end


                print(
                    "[Worship] Target dipilih:",
                    target.Name,
                    "| Admin:",
                    sender.Name
                )


                --------------------------------------------------------
                -- SET COMMAND TARGET
                --------------------------------------------------------

                _G.BotVars.CommandTarget =
                    target


                playWorship(
                    target
                )


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
                -- JIKA MASIH MODE WORSHIP
                --------------------------------------------------------

                if _G.BotVars.ActiveMode
                    == "worship" then

                    task.wait(0.5)


                    if generation
                        ~= danceGeneration then

                        return

                    end


                    playWorship()

                end

            end
        )


        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[Worship] Loaded untuk:",
            LocalPlayer.Name,
            "| FE Animation:",
            WORSHIP_ANIMATION_ID
        )

    end
}