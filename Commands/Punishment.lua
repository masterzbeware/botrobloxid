-- Punishment.lua
return {
    Execute = function(msg, client)
        local TextChatService = game:GetService("TextChatService")
        local channel = TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral

        -- Hanya merespons "!pushup"
        if msg == "!pushup" and channel then
            pcall(function()
                channel:SendAsync("JAYA JAYA JAYA")
            end)
        end
    end
}
