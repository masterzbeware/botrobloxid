-- Pushup.lua (ketika dieksekusi kirim chat "Siap laksanakan!")
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")

        -- Kirim chat ke RBXGeneral
        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if channel then
            pcall(function()
                channel:SendAsync("Siap Komandan!")
            end)
        else
            warn("Channel RBXGeneral tidak ditemukan!")
        end
    end
}
