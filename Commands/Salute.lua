return {
    Execute = function()

        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        --------------------------------------------------
        -- SEND /E SALUTE
        --------------------------------------------------

        local function sendSalute()

            local message = "/e salute"

            -- TextChatService
            if TextChatService
                and TextChatService.TextChannels then

                local channel =
                    TextChatService.TextChannels:FindFirstChild(
                        "RBXGeneral"
                    )

                if channel then

                    local success = pcall(function()
                        channel:SendAsync(message)
                    end)

                    if success then
                        return
                    end

                end

            end

            -- Fallback
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

        --------------------------------------------------
        -- EXECUTE
        --------------------------------------------------

        sendSalute()

    end
}