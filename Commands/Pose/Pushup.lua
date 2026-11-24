return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")
        local TextChatService = game:GetService("TextChatService")

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
        -- NATURAL LANGUAGE (TANPA PREFIX)
        --
        -- Parser berasal dari Perfix.lua (_G.BotVars.NLP).
        -- Perfix.lua belum memiliki intent pushup, jadi modul ini
        -- mendaftarkan intent-nya sendiri ke NLP.Intents.
        --
        -- Pushup di sekitar pengirim (Admin atau CommandTarget):
        --   pushup / Pushup, mulai! / pushup mulai / pushup, mulai!
        --
        -- Pushup untuk pemain lain (HANYA Admin):
        --   pushup trevkaro
        --   (bot juga mengirim chat: Siap pushup, <displayname>!)
        --
        -- Berhenti (HANYA Admin):
        --   berhenti / stop / bubar / unpushup / siap grak / tegak grak
        --
        -- siap grak / tegak grak juga boleh oleh CommandTarget
        -- (pemain yang sedang diikuti bot), dan hanya menghentikan
        -- animasi pushup.
        ----------------------------------------------------------------

        local NLP = _G.BotVars.NLP

        if not NLP then

            warn(
                "[Pushup] NLP tidak ditemukan. "
                .. "Pastikan Perfix.lua dimuat lebih dulu."
            )

        else

            NLP.Intents.pushup =
                NLP.Intents.pushup
                or {
                    Words = {
                        -- Kata perintah (kuat, cukup satu kata)
                        pushup = 2,

                        -- Kata pendamping (bernilai 0): dikenali supaya
                        -- "pushup, mulai!" tidak dianggap nama pemain,
                        -- tapi tidak memicu perintah sendirian.
                        mulai = 0,
                    },
                }

            -- Siap grak / tegak grak: dianggap perintah berhenti.
            -- Definisi sama dengan Carry.lua dan Salute.lua (carrystop),
            -- supaya tidak bentrok siapa pun yang dimuat lebih dulu.
            NLP.Intents.carrystop =
                NLP.Intents.carrystop
                or {
                    Threshold = 2,
                    Priority = -1,
                    StrictRemainder = true,

                    Words = {
                        grak = 2,
                        tegak = 0,
                    },
                }

            NLP.Intents.unpushup =
                NLP.Intents.unpushup
                or {
                    Threshold = 3,
                    Priority = 1,
                    StrictRemainder = true,

                    Words = {
                        unpushup = 3,
                    },
                }

        end


        ----------------------------------------------------------------
        -- FE ANIMATION ID
        ----------------------------------------------------------------

        local PUSHUP_ANIMATION_ID =
            "137977803647560"


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
            -- STOP PUSHUP TRACK
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
            -- Supaya setelah Pushup:
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

            danceGeneration =
                danceGeneration + 1

            local generation =
                danceGeneration


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
                ~= danceGeneration then

                return

            end


            ------------------------------------------------------------
            -- STOP PREVIOUS PUSHUP
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
                    "[Pushup] FE Animation berhasil dimainkan:",
                    PUSHUP_ANIMATION_ID,
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
        -- SEND CHAT
        ----------------------------------------------------------------

        local function sendChat(message)

            local success = false

            if TextChatService
                and TextChatService.TextChannels then

                local channel =
                    TextChatService.TextChannels:FindFirstChild(
                        "RBXGeneral"
                    )

                if channel then

                    success = pcall(function()
                        channel:SendAsync(message)
                    end)

                end

            end

            if not success then

                pcall(function()

                    local chatEvents =
                        game:GetService("ReplicatedStorage"):FindFirstChild(
                            "DefaultChatSystemChatEvents"
                        )

                    local sayMessageRequest =
                        chatEvents
                        and chatEvents:FindFirstChild(
                            "SayMessageRequest"
                        )

                    if sayMessageRequest then

                        sayMessageRequest:FireServer(
                            message,
                            "All"
                        )

                    end

                end)

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
            -- TEGAK GRAK / SIAP GRAK oleh CommandTarget (bukan admin)
            --
            -- Pemain yang sedang diikuti bot cukup menghentikan
            -- animasi pushup. CommandTarget dan mode lain
            -- (follow, formasi) tidak dihentikan.
            ----------------------------------------------------------------

            if intent == "carrystop"
                and not isAdmin
                and isCommandTarget then

                if dancing
                    or _G.BotVars.ActiveMode == "pushup" then

                    print(
                        "[Pushup] Tegak grak | CommandTarget:",
                        sender.Name
                    )

                    if _G.BotVars.ActiveMode == "pushup" then

                        _G.BotVars.ActiveMode = nil

                    end

                    stopPushup()

                end

                return

            end


            ----------------------------------------------------------------
            -- STOP (berhenti / stop / bubar)
            --
            -- HANYA ADMIN
            ----------------------------------------------------------------

            if intent == "stop"
                or intent == "carrystop" then

                if not isAdmin then

                    print(
                        "[Pushup] stop ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end


                print(
                    "[Pushup] Stop | Admin:",
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
            -- UNPUSHUP
            --
            -- HANYA ADMIN
            ----------------------------------------------------------------

            if intent == "unpushup" then

                if not isAdmin then

                    print(
                        "[Pushup] unpushup ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end


                print(
                    "[Pushup] UnPushup | Admin:",
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
            -- PUSHUP (tanpa nama)
            --
            -- ADMIN:
            --     pushup
            --     -> Target = Admin
            --
            -- COMMAND TARGET:
            --     pushup
            --     -> Target = dirinya sendiri
            --
            -- PLAYER BIASA:
            --     ditolak
            ----------------------------------------------------------------

            if intent == "pushup" and #args == 0 then

                if not isAdmin
                    and not isCommandTarget then

                    print(
                        "[Pushup] pushup ditolak:",
                        sender.Name
                    )

                    return

                end


                print(
                    "[Pushup] Command diterima | Sender:",
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


                playPushup(sender)

                return

            end


            ----------------------------------------------------------------
            -- PUSHUP <nama pemain>
            --
            -- HANYA ADMIN
            ----------------------------------------------------------------

            local targetName = nil

            if intent == "pushup" and #args > 0 then

                targetName =
                    NLP.ResolveTarget(
                        args,
                        findPlayerByName
                    )

            end

            if targetName then

                if not isAdmin then

                    print(
                        "[Pushup] Target command ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end


                local target =
                    findPlayerByName(targetName)

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


                _G.BotVars.CommandTarget =
                    target


                -- Siap pushup, <displayname>!
                sendChat(
                    "Siap pushup, "
                    .. target.DisplayName
                    .. "!"
                )

                playPushup(target)

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
                -- JIKA MASIH MODE PUSHUP
                --------------------------------------------------------

                if _G.BotVars.ActiveMode
                    == "pushup" then

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
                    -- PLAY PUSHUP LAGI
                    ----------------------------------------------------

                    playPushup(target)

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
