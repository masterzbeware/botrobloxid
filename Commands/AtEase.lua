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

        local EMOTE_ID = "115880435130348"

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

            local success, result = pcall(function()

                return humanoid:PlayEmoteAndGetAnimTrackById(
                    EMOTE_ID
                )

            end)

            if not success then

                warn(
                    "[AtEase] Gagal memainkan emote:",
                    result
                )

                return
            end

            if result then

                print(
                    "[AtEase] Emote berhasil dimainkan:",
                    EMOTE_ID
                )

            else

                warn(
                    "[AtEase] Emote tidak dapat dimainkan:",
                    EMOTE_ID
                )

            end

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

            --------------------------------------------------
            -- !ATEASE
            --------------------------------------------------

            if message:lower():match("^%s*!atease%s*$") then

                print(
                    "[AtEase] Command !AtEase diterima dari:",
                    sender.Name
                )

                playEmote()

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
        -- READY
        --------------------------------------------------

        print(
            "[AtEase] AtEase.lua aktif!"
        )

    end
}