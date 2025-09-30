-- AmbilAlih.lua
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")

        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if not channel then
            warn("Channel RBXGeneral tidak ditemukan!")
            return
        end

        -- Chat pertama
        pcall(function()
            channel:SendAsync("Siap laksanakan!")
        end)

        -- Delay 5 detik lalu chat kedua
        task.delay(5, function()
            pcall(function()
                channel:SendAsync("Kami siap menerima perintah dari komandan")
            end)
        end)
    end
}
