return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[Rest] LocalPlayer tidak ditemukan.")
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
                warn("[Rest] Gagal load Admin.lua.")
                return
            end
        end


        ----------------------------------------------------------------
        -- EMOTE ID
        ----------------------------------------------------------------

        local REST_EMOTE_ID =
            "115880435130348"


        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local restTrack = nil
        local resting = false

        local restGeneration = 0


        ----------------------------------------------------------------
        -- RANDOM SEED
        ----------------------------------------------------------------

        math.randomseed(
            math.floor(os.clock() * 1000000)
                + LocalPlayer.UserId
        )


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
                and generation ~= restGeneration then

                return
            end


            ------------------------------------------------------------
            -- STOP REST EMOTE
            ------------------------------------------------------------

            if restTrack then

                local oldTrack =
                    restTrack

                restTrack = nil

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
                    and generation ~= restGeneration then

                    return
                end


                pcall(function()
                    animateScript.Enabled = true
                end)

            end


            ------------------------------------------------------------
            -- VALIDATE GENERATION
            ------------------------------------------------------------

            if generation
                and generation ~= restGeneration then

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
            -- SMALL DELAY
            ------------------------------------------------------------

            task.defer(function()

                task.wait(0.1)


                if generation
                    and generation ~= restGeneration then

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
                "[Rest] Animasi normal dipulihkan."
            )

        end


        ----------------------------------------------------------------
        -- STOP REST
        ----------------------------------------------------------------

        local function stopRest()

            ------------------------------------------------------------
            -- INVALIDATE OLD PROCESS
            ------------------------------------------------------------

            restGeneration =
                restGeneration + 1

            local generation =
                restGeneration


            ------------------------------------------------------------
            -- DISABLE REST STATE
            ------------------------------------------------------------

            resting = false


            ------------------------------------------------------------
            -- RESTORE NORMAL ANIMATION
            ------------------------------------------------------------

            restoreNormalAnimation(
                generation
            )


            ------------------------------------------------------------
            -- JANGAN CLEAR CommandTarget
            --
            -- CommandTarget hanya dihapus oleh !stop ADMIN.
            ------------------------------------------------------------

        end


        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.rest =
            stopRest


        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "rest"
                    and type(stopFunction) == "function" then

                    pcall(function()
                        stopFunction()
                    end)

                end

            end

        end


        ----------------------------------------------------------------
        -- PLAY REST EMOTE
        ----------------------------------------------------------------

        local function playRest(targetPlayer)

            ------------------------------------------------------------
            -- NEW GENERATION
            ------------------------------------------------------------

            restGeneration =
                restGeneration + 1

            local generation =
                restGeneration


            ------------------------------------------------------------
            -- SET ACTIVE MODE
            ------------------------------------------------------------

            _G.BotVars.ActiveMode =
                "rest"


            ------------------------------------------------------------
            -- SET COMMAND TARGET
            ------------------------------------------------------------

            if targetPlayer then

                _G.BotVars.CommandTarget =
                    targetPlayer

            end


            ------------------------------------------------------------
            -- STOP OTHER MODES
            ------------------------------------------------------------

            stopOtherModes()


            ------------------------------------------------------------
            -- VALIDATE GENERATION
            ------------------------------------------------------------

            if generation
                ~= restGeneration then

                return

            end


            ------------------------------------------------------------
            -- STOP PREVIOUS REST TRACK
            ------------------------------------------------------------

            if restTrack then

                local oldTrack =
                    restTrack

                restTrack = nil

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
                    "[Rest] Humanoid tidak ditemukan untuk:",
                    LocalPlayer.Name
                )

                return

            end


            ------------------------------------------------------------
            -- PLAY EMOTE WITH RETRY
            ------------------------------------------------------------

            local maxAttempts = 3

            local success = false
            local result = nil


            for attempt = 1, maxAttempts do

                --------------------------------------------------------
                -- GENERATION CHECK
                --------------------------------------------------------

                if generation ~= restGeneration then
                    return
                end


                --------------------------------------------------------
                -- TRY PLAY EMOTE
                --------------------------------------------------------

                local ok, track =
                    pcall(function()

                        return humanoid:
                            PlayEmoteAndGetAnimTrackById(
                                REST_EMOTE_ID
                            )

                    end)


                if ok and track then

                    success = true
                    result = track

                    break

                end


                result = track


                --------------------------------------------------------
                -- SMALL DELAY BEFORE RETRY
                --------------------------------------------------------

                if attempt < maxAttempts then
                    task.wait(0.1)
                end

            end


            ------------------------------------------------------------
            -- VALIDATE GENERATION AFTER PLAY
            ------------------------------------------------------------

            if generation
                ~= restGeneration then

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

                restTrack = result
                resting = true


                print(
                    "[Rest] EMOTE AKTIF | Bot:",
                    LocalPlayer.Name,
                    "| ID:",
                    REST_EMOTE_ID,
                    "| Target:",
                    _G.BotVars.CommandTarget
                        and _G.BotVars.CommandTarget.Name
                        or "None"
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
                    -- ONLY CLEAR CURRENT TRACK
                    ----------------------------------------------------

                    if restTrack == track
                        and resting
                        and trackGeneration == restGeneration then

                        restTrack = nil

                    end

                end)


            else

                warn(
                    "[Rest] Semua percobaan emote gagal | Bot:",
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

            if not name or name == "" then
                return nil
            end


            local search =
                name:lower()


            ------------------------------------------------------------
            -- EXACT MATCH
            ------------------------------------------------------------

            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if player.Name:lower()
                    == search then

                    return player

                end

            end


            ------------------------------------------------------------
            -- PREFIX MATCH
            ------------------------------------------------------------

            for _, player in ipairs(
                Players:GetPlayers()
            ) do

                if player.Name:lower():sub(
                    1,
                    #search
                ) == search then

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


            ------------------------------------------------------------
            -- COMMAND TARGET CHECK
            ------------------------------------------------------------

            local isCommandTarget =
                (_G.BotVars.CommandTarget == sender)


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


            ----------------------------------------------------------------
            -- !STOP
            --
            -- HANYA ADMIN
            ----------------------------------------------------------------

            if lower == "!stop" then

                if not isAdmin then

                    print(
                        "[Rest] !stop ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end


                print(
                    "[Rest] !stop diterima | Admin:",
                    sender.Name
                )


                --------------------------------------------------------
                -- CLEAR GLOBAL MODE
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
            -- !UNREST
            --
            -- HANYA ADMIN
            ----------------------------------------------------------------

            if lower == "!unrest" then

                if not isAdmin then

                    print(
                        "[Rest] !unrest ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end


                print(
                    "[Rest] !unrest diterima | Admin:",
                    sender.Name
                )


                if _G.BotVars.ActiveMode
                    == "rest" then

                    _G.BotVars.ActiveMode = nil

                    stopRest()

                end


                return

            end


            ----------------------------------------------------------------
            -- !REST
            --
            -- !rest
            --     Admin / CommandTarget
            --
            -- !rest PLAYER
            --     Admin ONLY
            ----------------------------------------------------------------

            if lower == "!rest" then

                if not isAdmin
                    and not isCommandTarget then

                    print(
                        "[Rest] !rest ditolak:",
                        sender.Name
                    )

                    return

                end


                print(
                    "[Rest] !rest diterima | Sender:",
                    sender.Name,
                    "| Admin:",
                    isAdmin,
                    "| CommandTarget:",
                    isCommandTarget
                )


                --------------------------------------------------------
                -- COMMAND TARGET = SENDER
                --------------------------------------------------------

                _G.BotVars.CommandTarget =
                    sender


                playRest(sender)


                return

            end


            ----------------------------------------------------------------
            -- !REST PLAYER
            --
            -- HANYA ADMIN YANG BOLEH MEMILIH TARGET BARU
            ----------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!rest%s+(.+)$"
                )


            if targetName then

                if not isAdmin then

                    print(
                        "[Rest] !rest PLAYER ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end


                local target =
                    findPlayerByName(targetName)


                if not target then

                    warn(
                        "[Rest] Player tidak ditemukan:",
                        targetName
                    )

                    return

                end


                print(
                    "[Rest] Target dipilih:",
                    target.Name,
                    "| Admin:",
                    sender.Name
                )


                --------------------------------------------------------
                -- SET COMMAND TARGET
                --------------------------------------------------------

                _G.BotVars.CommandTarget =
                    target


                playRest(target)


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

                --------------------------------------------------------
                -- INVALIDATE OLD GENERATION
                --------------------------------------------------------

                restGeneration =
                    restGeneration + 1


                local generation =
                    restGeneration


                --------------------------------------------------------
                -- RESET STATE
                --------------------------------------------------------

                restTrack = nil
                resting = false


                --------------------------------------------------------
                -- WAIT CHARACTER READY
                --------------------------------------------------------

                task.wait(1)


                --------------------------------------------------------
                -- CHECK GENERATION
                --------------------------------------------------------

                if generation ~= restGeneration then
                    return
                end


                --------------------------------------------------------
                -- CHECK ACTIVE MODE
                --------------------------------------------------------

                if _G.BotVars.ActiveMode
                    == "rest" then

                    task.wait(0.5)


                    ----------------------------------------------------
                    -- CHECK AGAIN
                    ----------------------------------------------------

                    if generation ~= restGeneration then
                        return
                    end


                    if _G.BotVars.ActiveMode
                        == "rest" then

                        local target =
                            _G.BotVars.CommandTarget

                        playRest(target)

                    end

                end

            end
        )


        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[Rest] Loaded untuk:",
            LocalPlayer.Name,
            "| Emote:",
            REST_EMOTE_ID
        )

    end
}