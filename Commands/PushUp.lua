return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[Pushup] LocalPlayer tidak ditemukan.")
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
                warn("[Pushup] Gagal load Admin.lua.")
                return
            end
        end


        ----------------------------------------------------------------
        -- PUSHUP ANIMATION ID
        ----------------------------------------------------------------

        local PUSHUP_ANIMATION_ID =
            "93738573538058"


        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local pushupTrack = nil
        local pushingUp = false
        local pushupGeneration = 0


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
                and generation ~= pushupGeneration then

                return
            end


            ------------------------------------------------------------
            -- STOP PUSHUP TRACK
            ------------------------------------------------------------

            if pushupTrack then

                local oldTrack =
                    pushupTrack

                pushupTrack = nil

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

                if generation
                    and generation ~= pushupGeneration then

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
                and generation ~= pushupGeneration then

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
                generation or pushupGeneration

            task.defer(function()

                task.wait(0.1)

                if cleanupGeneration
                    ~= pushupGeneration then

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
                "[Pushup] Animasi normal dipulihkan."
            )

        end


        ----------------------------------------------------------------
        -- STOP PUSHUP
        ----------------------------------------------------------------

        local function stopPushup()

            ------------------------------------------------------------
            -- INVALIDATE SEMUA PROSES LAMA
            ------------------------------------------------------------

            pushupGeneration =
                pushupGeneration + 1

            local generation =
                pushupGeneration

            pushingUp = false


            ------------------------------------------------------------
            -- STOP TRACK
            ------------------------------------------------------------

            if pushupTrack then

                local oldTrack =
                    pushupTrack

                pushupTrack = nil

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
            -- JANGAN HAPUS CommandTarget DI SINI.
            --
            -- CommandTarget hanya dihapus oleh !stop ADMIN.
            ----------------------------------------------------------------

        end


        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.pushup =
            stopPushup


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
        -- PLAY PUSHUP
        ----------------------------------------------------------------

        local function playPushup(targetPlayer)

            ------------------------------------------------------------
            -- NEW GENERATION
            ------------------------------------------------------------

            pushupGeneration =
                pushupGeneration + 1

            local generation =
                pushupGeneration


            ------------------------------------------------------------
            -- SET ACTIVE MODE
            ------------------------------------------------------------

            _G.BotVars.ActiveMode =
                "pushup"


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
                ~= pushupGeneration then

                return

            end


            ------------------------------------------------------------
            -- STOP PREVIOUS PUSHUP TRACK
            ------------------------------------------------------------

            if pushupTrack then

                local oldTrack =
                    pushupTrack

                pushupTrack = nil

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
                    "[Pushup] Humanoid tidak ditemukan."
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
                    ~= pushupGeneration then

                    return

                end


                --------------------------------------------------------
                -- PLAY FE ANIMATION
                --------------------------------------------------------

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

            if generation
                ~= pushupGeneration then

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

                pushupTrack = result
                pushingUp = true


                print(
                    "[Pushup] FE Animation berhasil dimainkan:",
                    PUSHUP_ANIMATION_ID,
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

                    if pushupTrack == track
                        and pushingUp
                        and trackGeneration
                            == pushupGeneration then

                        pushupTrack = nil

                    end

                end)

            else

                warn(
                    "[Pushup] FE Animation gagal dimainkan setelah",
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
                :gsub("^%s+", "")
                :gsub("%s+$", "")


            ----------------------------------------------------------------
            -- !STOP
            --
            -- HANYA ADMIN
            ----------------------------------------------------------------

            if lower == "!stop" then

                if not isAdmin then

                    print(
                        "[Pushup] !stop ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end


                print(
                    "[Pushup] !stop diterima | Admin:",
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
            -- !UNPUSHUP
            --
            -- HANYA ADMIN
            ----------------------------------------------------------------

            if lower == "!unpushup" then

                if not isAdmin then

                    print(
                        "[Pushup] !unpushup ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end


                print(
                    "[Pushup] !unpushup diterima | Admin:",
                    sender.Name
                )


                if _G.BotVars.ActiveMode
                    == "pushup" then

                    _G.BotVars.ActiveMode = nil

                end


                stopPushup()


                return

            end


            ----------------------------------------------------------------
            -- !PUSHUP
            --
            -- ADMIN:
            --     !pushup
            --
            -- COMMAND TARGET:
            --     !pushup
            ----------------------------------------------------------------

            if lower == "!pushup" then

                if not isAdmin
                    and not isCommandTarget then

                    print(
                        "[Pushup] !pushup ditolak:",
                        sender.Name
                    )

                    return

                end


                print(
                    "[Pushup] !pushup diterima | Sender:",
                    sender.Name,
                    "| Admin:",
                    isAdmin,
                    "| CommandTarget:",
                    isCommandTarget
                )


                --------------------------------------------------------
                -- SENDER MENJADI COMMAND TARGET
                --------------------------------------------------------

                _G.BotVars.CommandTarget =
                    sender


                playPushup(
                    sender
                )


                return

            end


            ----------------------------------------------------------------
            -- !PUSHUP PLAYER
            --
            -- HANYA ADMIN
            ----------------------------------------------------------------

            local targetName =
                lower:match(
                    "^!pushup%s+(.+)$"
                )


            if targetName then

                if not isAdmin then

                    print(
                        "[Pushup] !pushup PLAYER ditolak:",
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
                        "[Pushup] Player tidak ditemukan:",
                        targetName
                    )

                    return

                end


                print(
                    "[Pushup] Target dipilih:",
                    target.Name,
                    "| Admin:",
                    sender.Name
                )


                --------------------------------------------------------
                -- SET COMMAND TARGET
                --------------------------------------------------------

                _G.BotVars.CommandTarget =
                    target


                playPushup(
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

                pushupGeneration =
                    pushupGeneration + 1


                local generation =
                    pushupGeneration


                pushupTrack = nil
                pushingUp = false


                --------------------------------------------------------
                -- JIKA MASIH MODE PUSHUP
                --------------------------------------------------------

                if _G.BotVars.ActiveMode
                    == "pushup" then

                    task.wait(0.5)


                    ----------------------------------------------------
                    -- PASTIKAN BELUM ADA COMMAND BARU
                    ----------------------------------------------------

                    if generation
                        ~= pushupGeneration then

                        return

                    end


                    playPushup()

                end

            end
        )


        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[Pushup] Loaded untuk:",
            LocalPlayer.Name,
            "| FE Animation:",
            PUSHUP_ANIMATION_ID
        )

    end
}