return {
    Execute = function()

        --------------------------------------------------
        -- SERVICES
        --------------------------------------------------

        local Players = game:GetService("Players")
        local TextChatService = game:GetService("TextChatService")

        --------------------------------------------------
        -- LOAD ADMIN
        --------------------------------------------------

        local Admin = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
        ))()

        --------------------------------------------------
        -- LOCAL PLAYER
        --------------------------------------------------

        local LocalPlayer = Players.LocalPlayer

        if not LocalPlayer then
            warn("[AtEase] LocalPlayer tidak ditemukan")
            return
        end

        --------------------------------------------------
        -- EMOTE ID
        --------------------------------------------------

        local EMOTE_ID = "132843854962577"

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
                    currentTrack:Stop()
                    currentTrack:Destroy()
                end)

                currentTrack = nil

                print("[AtEase] Emote dihentikan")

            end

        end

        --------------------------------------------------
        -- PLAY EMOTE
        --------------------------------------------------

        local function playEmote()

            local character = LocalPlayer.Character

            if not character then
                warn("[AtEase] Character tidak ditemukan")
                return
            end

            local humanoid =
                character:FindFirstChildOfClass("Humanoid")

            if not humanoid then
                warn("[AtEase] Humanoid tidak ditemukan")
                return
            end

            --------------------------------------------------
            -- HENTIKAN EMOTE SEBELUMNYA
            --------------------------------------------------

            stopEmote()

            --------------------------------------------------
            -- PLAY EMOTE
            --------------------------------------------------

            local success, track = pcall(function()

                return humanoid:PlayEmoteAndGetAnimTrackById(
                    EMOTE_ID
                )

            end)

            if not success then

                warn(
                    "[AtEase] Gagal memainkan emote:",
                    track
                )

                return
            end

            if not track then

                warn(
                    "[AtEase] Emote tidak dapat dimainkan:",
                    EMOTE_ID
                )

                return
            end

            --------------------------------------------------
            -- SIMPAN TRACK
            --------------------------------------------------

            currentTrack = track

            print(
                "[AtEase] Emote berhasil dimainkan:",
                EMOTE_ID
            )

        end

        --------------------------------------------------
        -- COMMAND HANDLER
        --------------------------------------------------

        local function handleCommand(message, sender)

            if not sender then
                return
            end

            --------------------------------------------------
            -- ADMIN CHECK
            --------------------------------------------------

            if not Admin:IsAdmin(sender) then
                return
            end

            local command = message:lower():match("^%s*(.-)%s*$")

            --------------------------------------------------
            -- !ATEASE
            --------------------------------------------------

            if command == "!atease" then

                print(
                    "[AtEase] Command !AtEase diterima dari:",
                    sender.Name
                )

                playEmote()

            --------------------------------------------------
            -- !STOP
            --------------------------------------------------

            elseif command == "!stop" then

                print(
                    "[AtEase] Command !Stop diterima dari:",
                    sender.Name
                )

                stopEmote()

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

        LocalPlayer.CharacterAdded:Connect(function()

            currentTrack = nil

        end)

        --------------------------------------------------
        -- READY
        --------------------------------------------------

        print(
            "[AtEase] AtEase.lua aktif!"
        )

    end
}