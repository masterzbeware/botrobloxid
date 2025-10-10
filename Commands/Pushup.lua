return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local TextChatService = game:GetService("TextChatService")
        local channel

        if TextChatService.TextChannels then
            channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        end

        vars.PushupActive = true

        local function sendChat(text)
            if channel then
                pcall(function()
                    channel:SendAsync(text)
                end)
            end
        end

        local jumlah = tonumber(msg:match("!pushup%s+(%d+)")) or 3

        vars.PushupConnection = task.spawn(function()
            sendChat("Siap laksanakan!")
            task.wait(2)
            if not vars.PushupActive then return end

            pcall(function()
                local args = { "playAnimation", "Push Up" }
                game:GetService("ReplicatedStorage")
                    :WaitForChild("Connections")
                    :WaitForChild("dataProviders")
                    :WaitForChild("animationHandler")
                    :InvokeServer(unpack(args))
            end)

            for i = 1, jumlah do
                task.wait(5)
                if not vars.PushupActive then break end

                if i == jumlah then
                    sendChat(tostring(i) .. " push up, Komandan!")
                else
                    sendChat(tostring(i) .. " push up!")
                end
            end

            pcall(function()
                local args = { "stopAnimation", "Push Up" }
                game:GetService("ReplicatedStorage")
                    :WaitForChild("Connections")
                    :WaitForChild("dataProviders")
                    :WaitForChild("animationHandler")
                    :InvokeServer(unpack(args))
            end)

            vars.PushupActive = false
            vars.PushupConnection = nil
        end)
    end
}
