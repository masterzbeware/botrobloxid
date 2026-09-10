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
        -- STOP EMOTE
        --------------------------------------------------

        local function stopEmote()

            if currentTrack then

                pcall(function()

                    if currentTrack.IsPlaying then
                        currentTrack:Stop(0.15)
                    end

                    currentTrack:Destroy()

                end)

                currentTrack = nil

                print("[Salute] Emote dihentikan")

            end

        end

        --------------------------------------------------
        -- REGISTER CONTROLLER
        --------------------------------------------------

        _G.BotVars.ModeControllers.salute = stopEmote

        --------------------------------------------------
        -- STOP SEMUA MODE LAIN
        --------------------------------------------------

        local function stopOtherModes()

            for name, stopFunction in pairs(
                _G.BotVars.ModeControllers
            ) do

                if name ~= "salute"
                    and type(stopFunction) == "function" then

                    pcall(stopFunction)

                end

            end

        end

        --------------------------------------------------
        -- PLAY EMOTE
        --------------------------------------------------

        local function playEmote()

            local character =
                LocalPlayer.Character

            if not character then
                warn("[Salute] Character tidak ditemukan")
                return
            end

            local humanoid =
                character:FindFirstChildOfClass(
                    "Humanoid"
                )

            if not humanoid then
                warn("[Salute] Humanoid tidak ditemukan")
                return
            end

            --------------------------------------------------
            -- STOP MODE LAIN
            --------------------------------------------------

            stopOtherModes()

            --------------------------------------------------
            -- ACTIVE MODE
            --------------------------------------------------

            _G.BotVars.ActiveMode = "salute"

            --------------------------------------------------
            -- STOP SALUTE LAMA
            --------------------------------------------------

            stopEmote()

            --------------------------------------------------
            -- PLAY
            --------------------------------------------------

            local success, track = pcall(function()

                return humanoid:
                    PlayEmoteAndGetAnimTrackById(
                        EMOTE_ID
                    )

            end)

            if not success then

                warn(
                    "[Salute] Gagal memainkan emote:",
                    track
                )

                _G.BotVars.ActiveMode = nil

                return
            end

            if not track then

                warn(
                    "[Salute] Emote tidak dapat dimainkan:",
                    EMOTE_ID
                )

                _G.BotVars.ActiveMode = nil

                return
            end

            --------------------------------------------------
            -- SAVE TRACK
            --------------------------------------------------

            currentTrack = track

            print(
                "[Salute] Emote berhasil dimainkan:",
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

            if not sender then
                return
            end

            --------------------------------------------------
            -- ADMIN CHECK
            --------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end

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
                    _G.BotVars.ModeControllers
                ) do

                    if type(stopFunction) == "function" then

                        pcall(stopFunction)

                    end

                end

                _G.BotVars.ActiveMode = nil

                return
            end

        end

        --------------------------------------------------
        -- TEXT CHAT
        --------------------------------------------------

        TextChatService.MessageReceived:Connect(
            function(message)

                if not message.TextSource then
                    return
                end

                local userId =
                    message.TextSource.UserId

                local sender =
                    Players:GetPlayerByUserId(
                        userId
                    )

                if not sender then
                    return
                end

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

                currentTrack = nil

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
