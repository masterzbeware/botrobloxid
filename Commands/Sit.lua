return {
    Execute = function()

        ----------------------------------------------------------------
        -- SERVICES
        ----------------------------------------------------------------

        local Players = game:GetService("Players")

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[Sit] LocalPlayer tidak ditemukan.")
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
                warn("[Sit] Gagal load Admin.lua.")
                return
            end
        end


        ----------------------------------------------------------------
        -- SIT EMOTE IDS
        ----------------------------------------------------------------
        -- Setiap Bot yang menerima !sit akan memilih 1 emote secara
        -- random dari daftar ini dan menjalankannya.

        local SIT_EMOTE_IDS = {
            "115688938961933",
            "87296962125027",
            "91423783304464",
            "93126583360867"
        }


        ----------------------------------------------------------------
        -- VARIABLES
        ----------------------------------------------------------------

        local sitTrack = nil
        local sitting = false

        -- Token untuk mencegah proses cleanup dari !stop lama
        -- mengganggu !sit yang baru.
        local sitGeneration = 0


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

            if generation and generation ~= sitGeneration then
                return
            end


            ------------------------------------------------------------
            -- STOP SIT EMOTE
            ------------------------------------------------------------

            if sitTrack then

                pcall(function()
                    sitTrack:Stop(0.15)
                end)

                sitTrack = nil

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

                pcall(function()
                    animateScript.Enabled = true
                end)

            end


            ------------------------------------------------------------
            -- FORCE HUMANOID BACK TO RUNNING
            ------------------------------------------------------------

            pcall(function()

                humanoid:ChangeState(
                    Enum.HumanoidStateType.Running
                )

            end)


            task.defer(function()

                task.wait(0.1)

                if generation
                    and generation ~= sitGeneration then
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


            print("[Sit] Animasi normal dipulihkan.")

        end


        ----------------------------------------------------------------
        -- STOP SIT
        ----------------------------------------------------------------

        local function stopSit()

            sitGeneration = sitGeneration + 1
            local generation = sitGeneration

            sitting = false
            restoreNormalAnimation(generation)

        end


        ----------------------------------------------------------------
        -- REGISTER CONTROLLER
        ----------------------------------------------------------------

        _G.BotVars.ModeControllers.sit =
            stopSit


        ----------------------------------------------------------------
        -- STOP OTHER MODES
        ----------------------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "sit"
                    and type(stopFunction) == "function" then

                    pcall(function()
                        stopFunction()
                    end)

                end

            end

        end


        ----------------------------------------------------------------
        -- RANDOM EMOTE
        ----------------------------------------------------------------

        local function getRandomSitEmote()

            return SIT_EMOTE_IDS[
                math.random(1, #SIT_EMOTE_IDS)
            ]

        end


        ----------------------------------------------------------------
        -- PLAY SIT EMOTE
        ----------------------------------------------------------------

        local function playSit()

            ------------------------------------------------------------
            -- NEW GENERATION
            ------------------------------------------------------------

            sitGeneration = sitGeneration + 1
            local generation = sitGeneration


            ------------------------------------------------------------
            -- SET ACTIVE MODE
            ------------------------------------------------------------

            _G.BotVars.ActiveMode = "sit"


            ------------------------------------------------------------
            -- STOP MODE LAIN
            ------------------------------------------------------------

            stopOtherModes()


            ------------------------------------------------------------
            -- STOP PREVIOUS SIT TRACK ONLY
            ------------------------------------------------------------

            if sitTrack then

                pcall(function()
                    sitTrack:Stop(0.1)
                end)

                sitTrack = nil

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
                    "[Sit] Humanoid tidak ditemukan untuk:",
                    LocalPlayer.Name
                )

                return

            end


            ------------------------------------------------------------
            -- RANDOM EMOTE
            ------------------------------------------------------------

            local firstIndex =
                math.random(1, #SIT_EMOTE_IDS)


            ------------------------------------------------------------
            -- PLAY WITH RETRY
            ------------------------------------------------------------
            -- Beberapa client bisa gagal sesaat saat emote baru
            -- dipanggil setelah !stop. Coba ulang beberapa kali.

            local maxAttempts = #SIT_EMOTE_IDS
            local success = false
            local result = nil
            local usedEmoteId = nil

            for attempt = 1, maxAttempts do

                if generation ~= sitGeneration then
                    return
                end

                local index =
                    ((firstIndex + attempt - 2)
                        % #SIT_EMOTE_IDS) + 1

                local sitEmoteId =
                    SIT_EMOTE_IDS[index]

                local ok, track =
                    pcall(function()

                        return humanoid:PlayEmoteAndGetAnimTrackById(
                            sitEmoteId
                        )

                    end)

                if ok and track then

                    success = true
                    result = track
                    usedEmoteId = sitEmoteId
                    break

                end

                result = track

                -- Beri waktu kecil agar Animator selesai
                -- membersihkan track sebelumnya.
                task.wait(0.08)

            end


            ------------------------------------------------------------
            -- VALIDATE GENERATION
            ------------------------------------------------------------

            if generation ~= sitGeneration then

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

                sitTrack = result
                sitting = true

                print(
                    "[Sit] EMOTE AKTIF | Bot:",
                    LocalPlayer.Name,
                    "| ID:",
                    usedEmoteId
                )


                --------------------------------------------------------
                -- MONITOR TRACK
                --------------------------------------------------------

                task.spawn(function()

                    local track =
                        result

                    pcall(function()
                        track.Stopped:Wait()
                    end)

                    if sitTrack == track
                        and sitting
                        and generation == sitGeneration then

                        sitTrack = nil

                    end

                end)

            else

                warn(
                    "[Sit] Semua percobaan emote gagal | Bot:",
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
            -- !SIT
            ------------------------------------------------------------

            if lower == "!sit" then

                print(
                    "[Sit] Command diterima | Bot:",
                    LocalPlayer.Name,
                    "| Admin:",
                    sender.Name
                )

                -- Tidak ada pengecekan Bot ID di sini.
                -- Setiap bot yang menjalankan module ini akan
                -- menjalankan emote masing-masing.

                playSit()

                return

            end


            ------------------------------------------------------------
            -- !UNSIT
            ------------------------------------------------------------

            if lower == "!unsit" then

                print(
                    "[Sit] Unsit | Bot:",
                    LocalPlayer.Name,
                    "| Admin:",
                    sender.Name
                )

                if _G.BotVars.ActiveMode
                    == "sit" then

                    _G.BotVars.ActiveMode = nil

                end

                stopSit()

                return

            end


            ------------------------------------------------------------
            -- !STOP
            ------------------------------------------------------------

            if lower == "!stop" then

                print(
                    "[Sit] Stop | Bot:",
                    LocalPlayer.Name,
                    "| Admin:",
                    sender.Name
                )

                if _G.BotVars.ActiveMode
                    == "sit" then

                    _G.BotVars.ActiveMode = nil

                end

                stopSit()

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

                sitTrack = nil

                sitGeneration = sitGeneration + 1

                --------------------------------------------------------
                -- JIKA MASIH MODE SIT
                --------------------------------------------------------

                if _G.BotVars.ActiveMode
                    == "sit" then

                    task.wait(0.5)

                    playSit()

                end

            end
        )


        ----------------------------------------------------------------
        -- READY
        ----------------------------------------------------------------

        print(
            "[Sit] Loaded untuk:",
            LocalPlayer.Name,
            "| Semua bot eligible untuk !sit",
            "| Random emotes:",
            #SIT_EMOTE_IDS
        )

    end
}
