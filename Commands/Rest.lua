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
            warn("[Rest] LocalPlayer tidak ditemukan")
            return
        end

        --------------------------------------------------
        -- GLOBAL MODE SYSTEM
        --------------------------------------------------

        _G.BotVars = _G.BotVars or {}

        _G.BotVars.ModeControllers =
            _G.BotVars.ModeControllers or {}

        --------------------------------------------------
        -- LOAD ADMIN
        --------------------------------------------------

        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        --------------------------------------------------
        -- EMOTE ID
        --------------------------------------------------

        local EMOTE_ID = "75628064640924"

        --------------------------------------------------
        -- CURRENT EMOTE TRACK
        --------------------------------------------------

        local currentTrack = nil

        --------------------------------------------------
        -- STOP EMOTE
        --------------------------------------------------

        local function stopEmote()

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

                if _G.BotVars.ActiveMode == "rest" then
                    _G.BotVars.ActiveMode = nil
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

                if _G.BotVars.ActiveMode == "rest" then
                    _G.BotVars.ActiveMode = nil
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
            --------------------------------------------------

            if _G.BotVars.ActiveMode == "rest" then
                _G.BotVars.ActiveMode = nil
            end

            --------------------------------------------------
            -- WAIT SEBENTAR
            --
            -- Memberikan waktu kepada Animate untuk
            -- membuat kembali animation track default.
            --------------------------------------------------

            task.wait(0.05)

            print(
                "[Rest] Emote dihentikan dan pose di-reset"
            )

        end

        --------------------------------------------------
        -- REGISTER GLOBAL CONTROLLER
        --------------------------------------------------

        _G.BotVars.ModeControllers.rest =
            stopEmote

        --------------------------------------------------
        -- STOP SEMUA MODE LAIN
        --------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "rest"
                    and type(stopFunction) == "function" then

                    pcall(stopFunction)

                end

            end

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
                    "[Rest] Character tidak ditemukan"
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
                    "[Rest] Humanoid tidak ditemukan"
                )

                return

            end

            --------------------------------------------------
            -- STOP MODE LAIN
            --------------------------------------------------

            stopOtherModes()

            --------------------------------------------------
            -- STOP REST YANG SEDANG BERJALAN
            --------------------------------------------------

            stopEmote()

            --------------------------------------------------
            -- SET ACTIVE MODE
            --
            -- Dilakukan setelah stopEmote()
            -- supaya tidak langsung di-clear.
            --------------------------------------------------

            _G.BotVars.ActiveMode = "rest"

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
                    "[Rest] Gagal memainkan emote:",
                    track
                )

                _G.BotVars.ActiveMode = nil

                return

            end

            --------------------------------------------------
            -- TRACK TIDAK DITEMUKAN
            --------------------------------------------------

            if not track then

                warn(
                    "[Rest] Emote tidak dapat dimainkan:",
                    EMOTE_ID
                )

                _G.BotVars.ActiveMode = nil

                return

            end

            --------------------------------------------------
            -- SAVE TRACK
            --------------------------------------------------

            currentTrack = track

            --------------------------------------------------
            -- SUCCESS
            --------------------------------------------------

            print(
                "[Rest] Emote berhasil dimainkan:",
                EMOTE_ID
            )

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
            -- !REST
            --------------------------------------------------

            if command == "!rest" then

                print(
                    "[Rest] Command !Rest diterima dari:",
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
                    "[Rest] Command !Stop diterima dari:",
                    sender.Name
                )

                --------------------------------------------------
                -- STOP SEMUA MODE
                --------------------------------------------------

                for _, stopFunction in pairs(
                    _G.BotVars.ModeControllers
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

                _G.BotVars.ActiveMode = nil

                print(
                    "[Rest] Semua mode dihentikan"
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
                -- CLEAR OLD TRACK
                --------------------------------------------------

                currentTrack = nil

                --------------------------------------------------
                -- CLEAR ACTIVE MODE
                --------------------------------------------------

                if _G.BotVars.ActiveMode == "rest" then
                    _G.BotVars.ActiveMode = nil
                end

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

            end
        )

        --------------------------------------------------
        -- READY
        --------------------------------------------------

        print(
            "[Rest] Rest.lua aktif!"
        )

    end
}