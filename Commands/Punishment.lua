-- Punishment.lua
return {
    Execute = function(msg, client)
        local TextChatService = game:GetService("TextChatService")
        local channel = TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral

        -- Pastikan hanya merespons "!pushup"
        if msg == "!pushup" and channel then
            pcall(function()
                -- Kirim chat
                channel:SendAsync("JAYA JAYA JAYA")

                -- Optional: mainkan animasi push up via RemoteFunction
                local success, err = pcall(function()
                    local animationHandler = game:GetService("ReplicatedStorage")
                        :WaitForChild("Connections")
                        :WaitForChild("dataProviders")
                        :WaitForChild("animationHandler")
                    animationHandler:InvokeServer("playAnimation", "Push Up")
                end)
                if not success then
                    warn("Gagal memicu animasi Push Up: " .. tostring(err))
                end
            end)
        end
    end
}
