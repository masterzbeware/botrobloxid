-- Punishment.lua
-- Modul untuk command !pushup

return {
    Execute = function(msg, client)
        -- Ambil TextChatService dari global bot vars
        local TextChatService = _G.BotVars.TextChatService
        local channel = TextChatService and TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral

        -- Respon hanya untuk !pushup
        if msg:lower() == "!pushup" and channel then
            pcall(function()
                channel:SendAsync("JAYA JAYA JAYA")
            end)
        end
    end
}
