-- Bubarbarisan.lua
-- Command !bubarbarisan: Bot mengirim chat "Siap, bubar barisan komandan!"

return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}

        local TextChatService = game:GetService("TextChatService")
        local channel

        if TextChatService.TextChannels then
            channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        end

        if channel then
            pcall(function()
                channel:SendAsync("Siap, bubar barisan komandan!")
            end)
        else
            warn("Channel RBXGeneral tidak ditemukan!")
        end
    end
}
