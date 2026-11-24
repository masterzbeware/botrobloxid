return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")
        local TextChatService = game:GetService("TextChatService")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[Flex] LocalPlayer tidak ditemukan.")
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

                warn("[Flex] Gagal load Admin.lua.")
                return

            end
        end


        ----------------------------------------------------------------
        -- NATURAL LANGUAGE (TANPA PREFIX)
        --
        -- Parser berasal dari Perfix.lua (_G.BotVars.NLP).
        -- Perfix.lua belum memiliki intent flex, jadi modul ini
        -- mendaftarkan intent-nya sendiri ke NLP.Intents.
        --
        -- Pamer otot di sekitar pengirim (Admin atau CommandTarget):
        --   pamer otot / Pamer otot! / Tunjukkan otot! / Pose otot!
        --   tunjukan otot (salah ketik satu huruf k juga dikenali)
        --
        -- Pamer otot untuk pemain lain (HANYA Admin):
        --   pamer otot trevkaro
        --   (bot juga mengirim chat: Siap pamer otot, <displayname>!)
        --
        -- Berhenti (HANYA Admin):
        --   berhenti / stop / bubar / unflex / siap grak / tegak grak
        --
        -- siap grak / tegak grak juga boleh oleh CommandTarget
        -- (pemain yang sedang diikuti bot), dan hanya menghentikan
        -- animasi pamer otot.
        ----------------------------------------------------------------

        local NLP = _G.BotVars.NLP

        if not NLP then

            warn(
                "[Flex] NLP tidak ditemukan. "
                .. "Pastikan Perfix.lua dimuat lebih dulu."
            )

        else

            NLP.Intents.flex =
                NLP.Intents.flex
                or {
                    Words = {
                        -- Kata "otot" lemah (bernilai 1): baru berarti
                        -- jika dipasangkan dengan kata kerja lewat
                        -- Phrases di bawah.
                        otot = 1,

                        -- Kata pendamping (bernilai 0): dikenali supaya
                        -- tidak dianggap nama pemain, tapi tidak memicu
                        -- perintah sendirian.
                        pamer = 0,
                        tunjukkan = 0,
                        tunjukan = 0,
                        pose = 0,
                    },

                    -- Frasa perintah (poin tambahan), sehingga hanya
                    -- "pamer otot" / "tunjukkan otot" / "pose otot"
                    -- yang memicu perintah.
                    Phrases = {
                        ["pamer otot"] = 1,
                        ["tunjukkan otot"] = 1,
                        ["tunjukan otot"] = 1,
                        ["pose otot"] = 1,
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

            NLP.Intents.unflex =
                NLP.Intents.unflex
                or {
                    Threshold = 3,
                    Priority = 1,
                    StrictRemainder = true,

                    Words = {
                        unflex = 3,
                    },
                }

        end


        ----------------------------------------------------------------
        -- FE ANIMATION ID
        ----------------------------------------------------------------

        local FLEX_ANIMATION_ID =
            "106199665153546"


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
            -- STOP FLEX TRACK
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
                "[Flex] Animasi normal dipulihkan."
            )

        end


        ----------------------------------------------------------------
        -- STOP FLEX
        ----------------------------------------------------------------

        local function stopFlex()

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
            -- Supaya setelah Flex:
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

        _G.BotVars.ModeControllers.flex =
            stopFlex


        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "flex"
                    and type(stopFunction) == "function" then

                    pcall(function()
                        stopFunction()
                    end)

                end

            end

        end


        ----------------------------------------------------------------
        -- PLAY FLEX
        ----------------------------------------------------------------

        local function playFlex(targetPlayer)

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
                "flex"


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
            -- STOP PREVIOUS FLEX
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
                    "[Flex] Humanoid tidak ditemukan."
                )

                return

            end


            ------------------------------------------------------------
            -- PLAY FE ANIMATION WITH RETRY
            ------------------------------------------------------------

            ------------------------------------------------------------
            -- BERHENTI BERGERAK DULU
            --
            -- Emote hanya bisa dimainkan saat Humanoid berdiri diam.
            -- Bot yang baru selesai mengikuti masih berlari, jadi
            -- percobaan pertama sering gagal. Karena itu bot dihentikan
            -- dulu dan percobaan diperpanjang.
            ------------------------------------------------------------

            pcall(function()

                local root =
                    character:FindFirstChild(
                        "HumanoidRootPart"
                    )

                if root then
                    humanoid:MoveTo(root.Position)
                end

            end)

            local maxAttempts = 15
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

                -- PlayEmoteAndGetAnimTrackById mengembalikan DUA nilai:
                -- (berhasil, AnimationTrack). Keduanya harus ditangkap,
                -- kalau tidak, track yang tersimpan hanya "true".
                local ok, emoteResult, emoteTrack =
                    pcall(function()

                        return humanoid:
                            PlayEmoteAndGetAnimTrackById(
                                tonumber(FLEX_ANIMATION_ID)
                                or FLEX_ANIMATION_ID
                            )

                    end)

                local track = nil

                if ok then

                    if typeof(emoteResult) == "Instance" then

                        track = emoteResult

                    elseif emoteResult == true
                        and typeof(emoteTrack) == "Instance" then

                        track = emoteTrack

                    end

                end

                if track then

                    success = true
                    result = track

                    break

                end

                result = emoteResult


                --------------------------------------------------------
                -- RETRY
                --------------------------------------------------------

                if attempt < maxAttempts then

                    task.wait(0.1)

                end

            end


            ----------------------------------------------------------------
            -- CADANGAN: MAINKAN LANGSUNG LEWAT ANIMATOR
            --
            -- Jika emote tetap ditolak, animasi dimainkan langsung
            -- dengan prioritas Action.
            ----------------------------------------------------------------

            if not success
                and generation == danceGeneration then

                local animator =
                    humanoid:FindFirstChildOfClass(
                        "Animator"
                    )

                if animator then

                    local loadOk, loadedTrack =
                        pcall(function()

                            local animation =
                                Instance.new("Animation")

                            animation.AnimationId =
                                "rbxassetid://"
                                .. tostring(FLEX_ANIMATION_ID)

                            local newTrack =
                                animator:LoadAnimation(
                                    animation
                                )

                            newTrack.Priority =
                                Enum.AnimationPriority.Action

                            newTrack.Looped = false

                            newTrack:Play(0.1)

                            return newTrack

                        end)

                    if loadOk and loadedTrack then

                        success = true
                        result = loadedTrack

                    else

                        result = loadedTrack

                    end

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
                    "[Flex] FE Animation berhasil dimainkan:",
                    FLEX_ANIMATION_ID,
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
                    "[Flex] FE Animation gagal dimainkan setelah",
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
            -- animasi pamer otot. CommandTarget dan mode lain
            -- (follow, formasi) tidak dihentikan.
            ----------------------------------------------------------------

            if intent == "carrystop"
                and not isAdmin
                and isCommandTarget then

                if dancing
                    or _G.BotVars.ActiveMode == "flex" then

                    print(
                        "[Flex] Tegak grak | CommandTarget:",
                        sender.Name
                    )

                    if _G.BotVars.ActiveMode == "flex" then

                        _G.BotVars.ActiveMode = nil

                    end

                    stopFlex()

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
                        "[Flex] stop ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end


                print(
                    "[Flex] Stop | Admin:",
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
            -- UNFLEX
            --
            -- HANYA ADMIN
            ----------------------------------------------------------------

            if intent == "unflex" then

                if not isAdmin then

                    print(
                        "[Flex] unflex ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end


                print(
                    "[Flex] UnFlex | Admin:",
                    sender.Name
                )


                if _G.BotVars.ActiveMode
                    == "flex" then

                    _G.BotVars.ActiveMode = nil

                end


                stopFlex()

                return

            end


            ----------------------------------------------------------------
            -- PAMER OTOT (tanpa nama)
            --
            -- ADMIN:
            --     pamer otot
            --     -> Target = Admin
            --
            -- COMMAND TARGET:
            --     pamer otot
            --     -> Target = dirinya sendiri
            --
            -- PLAYER BIASA:
            --     ditolak
            ----------------------------------------------------------------

            if intent == "flex" and #args == 0 then

                if not isAdmin
                    and not isCommandTarget then

                    print(
                        "[Flex] pamer otot ditolak:",
                        sender.Name
                    )

                    return

                end


                print(
                    "[Flex] Command diterima | Sender:",
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


                playFlex(sender)

                return

            end


            ----------------------------------------------------------------
            -- PAMER OTOT <nama pemain>
            --
            -- HANYA ADMIN
            ----------------------------------------------------------------

            local targetName = nil

            if intent == "flex" and #args > 0 then

                targetName =
                    NLP.ResolveTarget(
                        args,
                        findPlayerByName
                    )

            end

            if targetName then

                if not isAdmin then

                    print(
                        "[Flex] Target command ditolak:",
                        sender.Name,
                        "bukan Admin."
                    )

                    return

                end


                local target =
                    findPlayerByName(targetName)

                if not target then

                    warn(
                        "[Flex] Player tidak ditemukan:",
                        targetName
                    )

                    return

                end


                print(
                    "[Flex] Target dipilih:",
                    target.Name,
                    "| Admin:",
                    sender.Name
                )


                _G.BotVars.CommandTarget =
                    target


                -- Siap pamer otot, <displayname>!
                sendChat(
                    "Siap pamer otot, "
                    .. target.DisplayName
                    .. "!"
                )

                playFlex(target)

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
                -- JIKA MASIH MODE FLEX
                --------------------------------------------------------

                if _G.BotVars.ActiveMode
                    == "flex" then

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
                    -- PLAY FLEX LAGI
                    ----------------------------------------------------

                    playFlex(target)

                end

            end
        )


        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[Flex] Loaded untuk:",
            LocalPlayer.Name,
            "| FE Animation:",
            FLEX_ANIMATION_ID
        )

    end
}
