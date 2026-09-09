return {
    Execute = function()

        --------------------------------------------------
        -- SERVICES
        --------------------------------------------------

        local TextChatService = game:GetService("TextChatService")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")

        --------------------------------------------------
        -- SEND /E SALUTE
        --------------------------------------------------

        local function sendSalute()

            local message = "/e salute"

            --------------------------------------------------
            -- TEXT CHAT SERVICE
            --------------------------------------------------

            local success = false

            pcall(function()

                local textChannels = TextChatService:FindFirstChild("TextChannels")

                if not textChannels then
                    return
                end

                local channel =
                    textChannels:FindFirstChild("RBXGeneral")

                if not channel then
                    return
                end

                channel:SendAsync(message)

                success = true

            end)

            if success then
                return true
            end

            --------------------------------------------------
            -- FALLBACK OLD CHAT
            --------------------------------------------------

            pcall(function()

                local chatEvents =
                    ReplicatedStorage:FindFirstChild(
                        "DefaultChatSystemChatEvents"
                    )

                if not chatEvents then
                    return
                end

                local sayMessageRequest =
                    chatEvents:FindFirstChild(
                        "SayMessageRequest"
                    )

                if not sayMessageRequest then
                    return
                end

                sayMessageRequest:FireServer(
                    message,
                    "All"
                )

                success = true

            end)

            return success

        end

        --------------------------------------------------
        -- EXECUTE
        --------------------------------------------------

        sendSalute()

    end
}