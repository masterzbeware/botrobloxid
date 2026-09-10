```lua
return {
    Execute = function()

        --------------------------------------------------
        -- SERVICES
        --------------------------------------------------

        local Players = game:GetService("Players")
        local TextChatService = game:GetService("TextChatService")

        --------------------------------------------------
        -- LOCAL PLAYER
        --------------------------------------------------

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[Salute] LocalPlayer tidak ditemukan")
            return
        end

        --------------------------------------------------
        -- GLOBAL MODE SYSTEM
        --------------------------------------------------

        _G.BotVars = _G.BotVars or {}

        _G.BotVars.ModeControllers =
            _G.BotVars.ModeControllers or {}

        local vars = _G.BotVars

        --------------------------------------------------
        -- LOAD ADMIN
        --------------------------------------------------

        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        --------------------------------------------------
        -- EMOTE ID
        --------------------------------------------------

        local EMOTE_ID = "135931155753335"

        --------------------------------------------------
        -- CURRENT EMOTE TRACK
        --------------------------------------------------

        local currentTrack = nil

        --------------------------------------------------
        -- STATE
        --------------------------------------------------

        local saluteActive = false

        --------------------------------------------------
        -- STOP EMOTE
        --------------------------------------------------

        local function stopEmote()

            --------------------------------------------------
            -- DISABLE SALUTE STATE
            --------------------------------------------------

            saluteActive = false

            --------------------------------------------------
            -- GET CHARACTER
            --------------------------------------------------

            local character =
                LocalPlayer.Character

            --------------------------------------------------
            -- STOP CURRENT EMOTE
            --------------------------------------------------

            if currentTrack then

                pcall(function()

                    if currentTrack.IsPlaying then
                        currentTrack:Stop(0)
                    end

                end)

                currentTrack = nil

            end

            --------------------------------------------------
            -- CHARACTER TIDAK ADA
            --------------------------------------------------

            if not character then

                if vars.ActiveMode == "salute" then
                    vars.ActiveMode = nil
                end

                return

            end

            --------------------------------------------------
            -- GET HUMANOID
            --------------------------------------------------

            local humanoid =
                character:FindFirstChildOfClass(
                    "Humanoid"
                )

            if not humanoid then

                if vars.ActiveMode == "salute" then
                    vars.ActiveMode = nil
                end

                return

            end

            --------------------------------------------------
            -- GET ANIMATOR
            --------------------------------------------------

            local animator =
                humanoid:FindFirstChildOfClass(
                    "Animator"
                )

            --------------------------------------------------
            -- GET DEFAULT ANIMATE
            --------------------------------------------------

            local animate =
                character:FindFirstChild("Animate")

            --------------------------------------------------
            -- DISABLE DEFAULT ANIMATE
            --------------------------------------------------

            if animate then
                animate.Disabled = true
            end

            --------------------------------------------------
            -- STOP SEMUA TRACK
            --
            -- Animate sudah disabled terlebih dahulu
            -- supaya animation default tidak langsung
            -- berjalan kembali saat proses reset.
            --------------------------------------------------

            if animator then

                for _, track in ipairs(
                    animator:GetPlayingAnimationTracks()
                ) do

                    pcall(function()
                        track:Stop(0)
                    end)

                end

            end

            --------------------------------------------------
            -- ENABLE DEFAULT ANIMATE
            --------------------------------------------------

            if animate then
                animate.Disabled = false
            end

            --------------------------------------------------
            -- CLEAR ACTIVE MODE
            --
            -- Hanya clear jika Salute memang mode aktif.
            -- Jangan menghapus "sync" atau mode lain.
            --------------------------------------------------

            if vars.ActiveMode == "salute" then
                vars.ActiveMode = nil
            end

            --------------------------------------------------
            -- WAIT SEBENTAR
            --------------------------------------------------

            task.wait(0.05)

            print(
                "[Salute] Emote dihentikan dan pose di-reset"
            )

        end

        --------------------------------------------------
        -- REGISTER GLOBAL CONTROLLER
        --------------------------------------------------

        vars.ModeControllers.salute =
            stopEmote

        --------------------------------------------------
        -- STOP SEMUA MODE LAIN
        --------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                vars.ModeControllers
            ) do

                if name ~= "salute"
                    and type(stopFunction) == "function" then

                    pcall(stopFunction)

                end

            end

        end

        --------------------------------------------------
        -- PLAY EMOTE INTERNAL
        --------------------------------------------------
        --
        -- Fungsi ini hanya memainkan Salute.
        --
        -- PENTING:
        -- Fungsi ini TIDAK memanggil stopOtherModes().
        --
        -- Digunakan saat respawn supaya Salute dapat
        -- kembali bermain tanpa mematikan Sync.
        --
        --------------------------------------------------

        local function playEmoteInternal()

            --------------------------------------------------
            -- GET CHARACTER
            --------------------------------------------------

            local character =
                LocalPlayer.Character

            if not character then

                warn(
                    "[Salute] Character tidak ditemukan"
                )

                return false

            end

            --------------------------------------------------
            -- GET HUMANOID
            --------------------------------------------------

            local humanoid =
                character:FindFirstChildOfClass(
                    "Humanoid"
                )

            if not humanoid then

                warn(
                    "[Salute] Humanoid tidak ditemukan"
                )

                return false

            end

            --------------------------------------------------
            -- PLAY EMOTE
            --------------------------------------------------

            local success, track =
                pcall(function()

                    return humanoid:
                        PlayEmoteAndGetAnimTrackById(
                            EMOTE_ID
                        )

                end)

            --------------------------------------------------
            -- PLAY FAILED
            --------------------------------------------------

            if not success then

                warn(
                    "[Salute] Gagal memainkan emote:",
                    track
                )

                return false

            end

            --------------------------------------------------
            -- TRACK TIDAK DITEMUKAN
            --------------------------------------------------

            if not track then

                warn(
                    "[Salute] Emote tidak dapat dimainkan:",
                    EMOTE_ID
                )

                return false

            end

            --------------------------------------------------
            -- SAVE TRACK
            --------------------------------------------------

            currentTrack = track

            --------------------------------------------------
            -- SUCCESS
            --------------------------------------------------

            print(
                "[Salute] Emote berhasil dimainkan:",
                EMOTE_ID
            )

            return true

        end

        --------------------------------------------------
        -- PLAY EMOTE
        --------------------------------------------------

        local function playEmote()

            --------------------------------------------------
            -- GET CHARACTER
            --------------------------------------------------

            local character =
                LocalPlayer.Character

            if not character then

                warn(
                    "[Salute] Character tidak ditemukan"
                )

                return

            end

            --------------------------------------------------
            -- GET HUMANOID
            --------------------------------------------------

            local humanoid =
                character:FindFirstChildOfClass(
                    "Humanoid"
                )

            if not humanoid then

                warn(
                    "[Salute] Humanoid tidak ditemukan"
                )

                return

            end

            --------------------------------------------------
            -- STOP MODE LAIN
            --
            -- Hanya dilakukan ketika user benar-benar
            -- menjalankan !salute.
            --
            --------------------------------------------------

            stopOtherModes()

            --------------------------------------------------
            -- STOP SALUTE YANG SEDANG BERJALAN
            --------------------------------------------------

            stopEmote()

            --------------------------------------------------
            -- SET ACTIVE STATE
            --------------------------------------------------

            saluteActive = true

            --------------------------------------------------
            -- SET ACTIVE MODE
            --
            -- Dilakukan setelah stopEmote()
            -- supaya tidak langsung di-clear.
            --------------------------------------------------

            vars.ActiveMode = "salute"

            --------------------------------------------------
            -- PLAY EMOTE
            --------------------------------------------------

            local success =
                playEmoteInternal()

            --------------------------------------------------
            -- PLAY FAILED
            --------------------------------------------------

            if not success then

                saluteActive = false

                if vars.ActiveMode == "salute" then
                    vars.ActiveMode = nil
                end

                return

            end

        end

        --------------------------------------------------
        -- COMMAND HANDLER
        --------------------------------------------------

        local function handleCommand(
            message,
            sender
        )

            --------------------------------------------------
            -- SENDER CHECK
            --------------------------------------------------

            if not sender then
                return
            end

            --------------------------------------------------
            -- ADMIN CHECK
            --------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end

            --------------------------------------------------
            -- NORMALIZE COMMAND
            --------------------------------------------------

            local command =
                message:lower():match(
                    "^%s*(.-)%s*$"
                )

            --------------------------------------------------
            -- !SALUTE
            --------------------------------------------------

            if command == "!salute" then

                print(
                    "[Salute] Command !Salute diterima dari:",
                    sender.Name
                )

                playEmote()

                return

            end

            --------------------------------------------------
            -- !STOP
            --------------------------------------------------

            if command == "!stop" then

                print(
                    "[Salute] Command !Stop diterima dari:",
                    sender.Name
                )

                --------------------------------------------------
                -- STOP SEMUA MODE
                --------------------------------------------------

                for _, stopFunction in pairs(
                    vars.ModeControllers
                ) do

                    if type(stopFunction) == "function" then

                        pcall(function()
                            stopFunction()
                        end)

                    end

                end

                --------------------------------------------------
                -- CLEAR ACTIVE MODE
                --------------------------------------------------

                vars.ActiveMode = nil

                print(
                    "[Salute] Semua mode dihentikan"
                )

                return

            end

        end

        --------------------------------------------------
        -- TEXT CHAT
        --------------------------------------------------

        TextChatService.MessageReceived:Connect(
            function(message)

                --------------------------------------------------
                -- TEXT SOURCE CHECK
                --------------------------------------------------

                if not message.TextSource then
                    return
                end

                --------------------------------------------------
                -- GET USER ID
                --------------------------------------------------

                local userId =
                    message.TextSource.UserId

                --------------------------------------------------
                -- GET PLAYER
                --------------------------------------------------

                local sender =
                    Players:GetPlayerByUserId(
                        userId
                    )

                if not sender then
                    return
                end

                --------------------------------------------------
                -- HANDLE COMMAND
                --------------------------------------------------

                handleCommand(
                    message.Text,
                    sender
                )

            end
        )

        --------------------------------------------------
        -- CHARACTER RESPAWN
        --------------------------------------------------

        LocalPlayer.CharacterAdded:Connect(
            function()

                --------------------------------------------------
                -- SIMPAN STATUS SALUTE
                --
                -- saluteActive sengaja tidak menggunakan
                -- vars.ActiveMode karena Sync dapat mengubah
                -- ActiveMode menjadi "sync".
                --
                --------------------------------------------------

                local shouldResumeSalute =
                    saluteActive

                --------------------------------------------------
                -- CLEAR OLD TRACK
                --------------------------------------------------

                currentTrack = nil

                --------------------------------------------------
                -- WAIT CHARACTER READY
                --------------------------------------------------

                task.wait(1)

                --------------------------------------------------
                -- GET NEW CHARACTER
                --------------------------------------------------

                local character =
                    LocalPlayer.Character

                if not character then
                    return
                end

                --------------------------------------------------
                -- ENABLE DEFAULT ANIMATE
                --------------------------------------------------

                local animate =
                    character:FindFirstChild("Animate")

                if animate then
                    animate.Disabled = false
                end

                --------------------------------------------------
                -- RESUME SALUTE
                --------------------------------------------------
                --
                -- Jangan menggunakan:
                --
                -- playEmote()
                --
                -- karena playEmote() memanggil
                -- stopOtherModes() dan bisa mematikan Sync.
                --
                --------------------------------------------------

                if shouldResumeSalute then

                    local success =
                        playEmoteInternal()

                    if not success then

                        saluteActive = false

                        if vars.ActiveMode == "salute" then
                            vars.ActiveMode = nil
                        end

                    end

                end

            end
        )

        --------------------------------------------------
        -- READY
        --------------------------------------------------

        print(
            "[Salute] Salute.lua aktif!"
        )

    end
}