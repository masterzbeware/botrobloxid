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
        warn("[Salute] LocalPlayer tidak ditemukan")
        return
    end

    --------------------------------------------------
    -- SEND CHAT
    --------------------------------------------------

    local function sendChat(message)

        local channel =
            TextChatService.TextChannels:FindFirstChild(
                "RBXGeneral"
            )

        if not channel then

            warn("[Salute] RBXGeneral tidak ditemukan")

            return

        end

        local success, err = pcall(function()

            channel:SendAsync(message)

        end)

        if not success then

            warn(
                "[Salute] Gagal mengirim chat:",
                err
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
        -- DEBUG
        --------------------------------------------------

        print(
            "[Salute] Chat:",
            message,
            "| Sender:",
            sender.Name,
            "| UserId:",
            sender.UserId
        )

        --------------------------------------------------
        -- ADMIN CHECK
        --------------------------------------------------

        if not Admin:IsAdmin(sender) then

            print(
                "[Salute] Bukan admin:",
                sender.Name
            )

            return

        end

        --------------------------------------------------
        -- SALUTE COMMAND
        --------------------------------------------------

        if message:lower():match("^%s*!salute%s*$") then

            print(
                "[Salute] Command !salute diterima dari:",
                sender.Name
            )

            sendChat("Salute, Sir!")

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
                Players:GetPlayerByUserId(userId)

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
    -- FALLBACK PLAYER.CHATTED
    --------------------------------------------------

    for _, player in ipairs(
        Players:GetPlayers()
    ) do

        player.Chatted:Connect(
            function(message)

                handleCommand(
                    message,
                    player
                )

            end
        )

    end

    --------------------------------------------------
    -- PLAYER ADDED
    --------------------------------------------------

    Players.PlayerAdded:Connect(
        function(player)

            player.Chatted:Connect(
                function(message)

                    handleCommand(
                        message,
                        player
                    )

                end
            )

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
