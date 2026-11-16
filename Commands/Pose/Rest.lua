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
        -- NATURAL LANGUAGE (TANPA PREFIX)
        --
        -- Parser berasal dari Perfix.lua (_G.BotVars.NLP).
        -- Perfix.lua belum memiliki intent rest, jadi modul ini
        -- mendaftarkan intent-nya sendiri ke NLP.Intents.
        --
        -- Istirahat di sekitar pengirim (Admin atau CommandTarget):
        --   istirahat / beristirahat / istirahat di tempat
        --
        -- Istirahat untuk pemain lain (HANYA Admin):
        --   istirahat trevkaro
        --
        -- Berhenti (HANYA Admin):
        --   berhenti / stop / bubar / unistirahat
        ----------------------------------------------------------------

        local NLP = _G.BotVars.NLP

        if not NLP then

            warn(
                "[Rest] NLP tidak ditemukan. "
                .. "Pastikan Perfix.lua dimuat lebih dulu."
            )

        else

            NLP.Intents.rest =
                NLP.Intents.rest
                or {
                    Words = {
                        -- Kata perintah (kuat, cukup satu kata)
                        istirahat = 2,
                        beristirahat = 2,

                        -- Kata pendamping (bernilai 0): dikenali supaya
                        -- "istirahat ditempat" tidak dianggap nama pemain,
                        -- tapi tidak memicu perintah sendirian.
                        ditempat = 0,
                    },
                }

            NLP.Intents.unrest =
                NLP.Intents.unrest
                or {
                    Threshold = 3,
                    Priority = 1,
                    StrictRemainder = true,

                    Words = {
                        unistirahat = 3,
                        unrest = 3,
                    },
                }

        end


        ----------------------------------------------------------------
        -- FE ANIMATION ID
        ----------------------------------------------------------------

        local REST_ANIMATION_ID =
            "75628064640924"


        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local restTrack = nil
        local resting = false

        local restGeneration = 0


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
            -- STOP REST TRACK
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
            -- FORCE HUMANOID BACK TO RUNNING
            ------------------------------------------------------------

            if generation
                and generation ~= restGeneration then

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
                generation or restGeneration

            task.defer(function()

                task.wait(0.1)

                if cleanupGeneration
                    ~= restGeneration then

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
            -- INVALIDATE SEMUA PROSES LAMA
            ------------------------------------------------------------

            restGeneration =
                restGeneration + 1

            local generation =
                restGeneration

            resting = false


            ------------------------------------------------------------
            -- STOP TRACK
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
            -- RESTORE ANIMATION
            ------------------------------------------------------------

            restoreNormalAnimation(
                generation
            )

            ------------------------------------------------------------
            -- PENTING:
            -- JANGAN CLEAR CommandTarget DI SINI
            --
            -- Supaya setelah Rest:
            -- Target masih bisa follow
            -- Target masih bisa frontline
            -- Target masih bisa circle
            -- Target masih bisa fourline
            -- dll.
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
        -- PLAY REST
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
            -- STOP MODE LAIN
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
            -- STOP PREVIOUS REST
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
                    "[Rest] Humanoid tidak ditemukan."
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
                    ~= restGeneration then

                    return

                end


                --------------------------------------------------------
                -- PLAY FE ANIMATION
                --------------------------------------------------------

                local ok, track =
                    pcall(function()

                        return humanoid:
                            PlayEmoteAndGetAnimTrackById(
                                REST_ANIMATION_ID
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
                ~= restGeneration then

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

                restTrack = result
                resting = true

                print(
                    "[Rest] FE Animation berhasil dimainkan:",
                    REST_ANIMATION_ID,
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

                    if restTrack == track
                        and resting
                        and trackGeneration
                            == restGeneration then

                        restTrack = nil

                    end

                end)

            else

                warn(
                    "[Rest] FE Animation gagal dimainkan setelah",
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
            -- ANALISA PESAN (BAHASA NATURAL)
            ------------------------------------------------------------

            local intent, args

            if NLP then

                intent, args = NLP.Classify(
                    message,
                    NLP.Intents
                )

            end

            if not intent then
                return
            end


            ----------------------------------------------------------------
            -- STOP (berhenti / stop / bubar)
            --
            -- HANYA ADMIN
            ----------------------------------------------------------------

            if intent == "stop" then

                if not isAdmin then

                    print(
                        "[Rest] stop ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end


                print(
                    "[Rest] Stop | Admin:",
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
            -- UNREST (unistirahat)
            --
            -- HANYA ADMIN
            ----------------------------------------------------------------

            if intent == "unrest" then

                if not isAdmin then

                    print(
                        "[Rest] unistirahat ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end


                print(
                    "[Rest] UnRest | Admin:",
                    sender.Name
                )


                if _G.BotVars.ActiveMode
                    == "rest" then

                    _G.BotVars.ActiveMode = nil

                end


                stopRest()

                return

            end


            ----------------------------------------------------------------
            -- ISTIRAHAT (tanpa nama)
            --
            -- ADMIN:
            --     istirahat
            --     -> Target = Admin
            --
            -- COMMAND TARGET:
            --     istirahat
            --     -> Target = dirinya sendiri
            --
            -- PLAYER BIASA:
            --     ditolak
            ----------------------------------------------------------------

            if intent == "rest" and #args == 0 then

                if not isAdmin
                    and not isCommandTarget then

                    print(
                        "[Rest] istirahat ditolak:",
                        sender.Name
                    )

                    return

                end


                print(
                    "[Rest] Command diterima | Sender:",
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


                playRest(sender)

                return

            end


            ----------------------------------------------------------------
            -- ISTIRAHAT <nama pemain>
            --
            -- HANYA ADMIN
            ----------------------------------------------------------------

            local targetName = nil

            if intent == "rest" and #args > 0 then

                targetName =
                    NLP.ResolveTarget(
                        args,
                        findPlayerByName
                    )

            end

            if targetName then

                if not isAdmin then

                    print(
                        "[Rest] Target command ditolak:",
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

                restGeneration =
                    restGeneration + 1

                local generation =
                    restGeneration

                restTrack = nil
                resting = false


                --------------------------------------------------------
                -- JIKA MASIH MODE REST
                --------------------------------------------------------

                if _G.BotVars.ActiveMode
                    == "rest" then

                    task.wait(0.5)


                    ----------------------------------------------------
                    -- PASTIKAN BELUM ADA COMMAND BARU
                    ----------------------------------------------------

                    if generation
                        ~= restGeneration then

                        return

                    end


                    ----------------------------------------------------
                    -- AMBIL TARGET LAMA
                    ----------------------------------------------------

                    local target =
                        _G.BotVars.CommandTarget


                    ----------------------------------------------------
                    -- PLAY REST LAGI
                    ----------------------------------------------------

                    playRest(target)

                end

            end
        )


        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[Rest] Loaded untuk:",
            LocalPlayer.Name,
            "| FE Animation:",
            REST_ANIMATION_ID
        )

    end
}
