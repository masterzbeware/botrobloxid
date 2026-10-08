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
        -- FE ANIMATION ID
        ----------------------------------------------------------------

        local SALUTE_ANIMATION_ID =
            "97204032436479"


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
            -- STOP SALUTE TRACK
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
                "[Salute] Animasi normal dipulihkan."
            )

        end


        ----------------------------------------------------------------
        -- STOP SALUTE
        ----------------------------------------------------------------

        local function stopSalute()

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

            ------------------------------------------------------------
            -- PENTING:
            -- JANGAN CLEAR CommandTarget DI SINI
            --
            -- Supaya setelah Salute:
            -- Target masih bisa !follow
            -- Target masih bisa !frontline
            -- Target masih bisa !circle
            -- Target masih bisa !fourline
            -- dll.
            ------------------------------------------------------------

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
        -- PLAY SALUTE
        ----------------------------------------------------------------

        local function playSalute(targetPlayer)

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
                "salute"


            ------------------------------------------------------------
            -- SET COMMAND TARGET
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
            -- STOP PREVIOUS SALUTE
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
                    "[Salute] Humanoid tidak ditemukan."
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
                                SALUTE_ANIMATION_ID
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


            ----------------------------------------------------------------
            -- VALIDATE GENERATION AFTER RETRY
            ----------------------------------------------------------------

            if generation
                ~= danceGeneration then

                if result then

                    pcall(function()
                        result:Stop(0)
                    end)

                end

                return

            end


            ----------------------------------------------------------------
            -- RESULT
            ----------------------------------------------------------------

            if success and result then

                danceTrack = result
                dancing = true

                print(
                    "[Salute] FE Animation berhasil dimainkan:",
                    SALUTE_ANIMATION_ID,
                    "| Bot:",
                    LocalPlayer.Name,
                    "| Target:",
                    _G.BotVars.CommandTarget
                        and _G.BotVars.CommandTarget.Name
                        or "None"
                )


                --------------------------------------------------------
                -- MONITOR TRACK
                --------------------------------------------------------

                task.spawn(function()

                    local track = result

                    local trackGeneration =
                        generation

                    if not track then
                        return
                    end

                    pcall(function()
                        track.Stopped:Wait()
                    end)


                    ----------------------------------------------------
                    -- CLEANUP ONLY IF STILL SAME TRACK
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
                    "[Salute] FE Animation gagal dimainkan setelah",
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
                lower:gsub("^%s+", "")

            lower =
                lower:gsub("%s+$", "")


            ----------------------------------------------------------------
            -- !STOP
            --
            -- HANYA ADMIN
            ----------------------------------------------------------------

            if lower == "!stop" then

                if not isAdmin then

                    print(
                        "[Salute] !stop ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end


                print(
                    "[Salute] Stop | Admin:",
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
            -- !UNSALUTE
            --
            -- HANYA ADMIN
            ----------------------------------------------------------------

            if lower == "!unsalute" then

                if not isAdmin then

                    print(
                        "[Salute] !unsalute ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end


                print(
                    "[Salute] UnSalute | Admin:",
                    sender.Name
                )


                if _G.BotVars.ActiveMode
                    == "salute" then

                    _G.BotVars.ActiveMode = nil

                end


                stopSalute()

                return

            end


            ----------------------------------------------------------------
            -- !SALUTE
            --
            -- ADMIN:
            --     !salute
            --     -> Target = Admin
            --
            -- COMMAND TARGET:
            --     !salute
            --     -> Target = dirinya sendiri
            --
            -- PLAYER BIASA:
            --     ditolak
            ----------------------------------------------------------------

            if lower == "!salute" then

                if not isAdmin
                    and not isCommandTarget then

                    print(
                        "[Salute] !salute ditolak:",
                        sender.Name
                    )

                    return

                end


                print(
                    "[Salute] Command diterima | Sender:",
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


                playSalute(sender)

                return

            end


            ----------------------------------------------------------------
            -- !SALUTE PLAYER
            --
            -- HANYA ADMIN
            ----------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!salute%s+(.+)$"
                )

            if targetName then

                if not isAdmin then

                    print(
                        "[Salute] Target command ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end


                local target =
                    findPlayerByName(targetName)

                if not target then

                    warn(
                        "[Salute] Player tidak ditemukan:",
                        targetName
                    )

                    return

                end


                print(
                    "[Salute] Target dipilih:",
                    target.Name,
                    "| Admin:",
                    sender.Name
                )


                _G.BotVars.CommandTarget =
                    target


                playSalute(target)

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

            connectPlayerChat(player)

        end


        ----------------------------------------------------------------
        -- PLAYER ADDED
        ----------------------------------------------------------------

        Players.PlayerAdded:Connect(
            function(player)

                connectPlayerChat(player)

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
                -- JIKA MASIH MODE SALUTE
                --------------------------------------------------------

                if _G.BotVars.ActiveMode
                    == "salute" then

                    task.wait(0.5)


                    ----------------------------------------------------
                    -- PASTIKAN BELUM ADA COMMAND BARU
                    ----------------------------------------------------

                    if generation
                        ~= danceGeneration then

                        return

                    end


                    ----------------------------------------------------
                    -- AMBIL TARGET LAMA
                    ----------------------------------------------------

                    local target =
                        _G.BotVars.CommandTarget


                    ----------------------------------------------------
                    -- PLAY SALUTE LAGI
                    ----------------------------------------------------

                    playSalute(target)

                end

            end
        )


        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[Salute] Loaded untuk:",
            LocalPlayer.Name,
            "| FE Animation:",
            SALUTE_ANIMATION_ID
        )

    end
}