-- AmbilAlih.lua
-- Command !ambilalih: Bot merespons siap laksanakan dan siap menerima perintah

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
                channel:SendAsync("Siap laksanakan!")
            end)

            task.delay(5, function()
                pcall(function()
                    channel:SendAsync("Kami siap menerima perintah dari komandan!")
                end)
            end)
        else
            warn("Channel RBXGeneral tidak ditemukan!")
        end
    end
}
