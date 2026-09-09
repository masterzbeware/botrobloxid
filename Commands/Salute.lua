return {
Execute = function()
    --------------------------------------------------
    -- SERVICES
    --------------------------------------------------

    local Players = game:GetService("Players")
    local TextChatService = game:GetService("TextChatService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local LocalPlayer = Players.LocalPlayer

    if not LocalPlayer then
        return
    end

    --------------------------------------------------
    -- LOAD ADMIN
    --------------------------------------------------

    local Admin = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/masterzbeware/botrobloxid/main/Administrator/Admin.lua"
    ))()

    --------------------------------------------------
    -- SEND CHAT
    --------------------------------------------------

    local function sendChat(message)

        local success = false

        --------------------------------------------------
        -- TEXT CHAT
        --------------------------------------------------

        if TextChatService
            and TextChatService.TextChannels then

            local channel =
                TextChatService.TextChannels:FindFirstChild(
                    "RBXGeneral"
                )

            if channel then

                pcall(function()
                    channel:SendAsync(message)
                end)

                success = true

            end

        end

        --------------------------------------------------
        -- FALLBACK CHAT
        --------------------------------------------------

        if not success then

            pcall(function()

                local chatEvents =
                    ReplicatedStorage:FindFirstChild(
                        "DefaultChatSystemChatEvents"
                    )

                if chatEvents then

                    local sayMessageRequest =
                        chatEvents:FindFirstChild(
                            "SayMessageRequest"
                        )

                    if sayMessageRequest then

                        sayMessageRequest:FireServer(
                            message,
                            "All"
                        )

                    end

                end

            end)

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
        -- HANYA ADMIN
        --------------------------------------------------

        if not Admin:IsAdmin(sender) then
            return
        end

        --------------------------------------------------
        -- !SALUTE
        --------------------------------------------------

        if message:lower() == "!salute" then

            sendChat("Salute, Sir!")

        end

    end

    --------------------------------------------------
    -- TEXT CHAT
    --------------------------------------------------

    if TextChatService
        and TextChatService.TextChannels then

        local channel =
            TextChatService.TextChannels:FindFirstChild(
                "RBXGeneral"
            )

        if channel then

            channel.OnIncomingMessage =
                function(message)

                    local userId =
                        message.TextSource
                        and message.TextSource.UserId

                    local sender =
                        userId
                        and Players:GetPlayerByUserId(
                            userId
                        )

                    if sender then

                        handleCommand(
                            message.Text,
                            sender
                        )

                    end

                end

        end

    end

    --------------------------------------------------
    -- FALLBACK CHAT
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

end
}
