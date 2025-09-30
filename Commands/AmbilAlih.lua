-- AmbilAlih.lua
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")

        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if channel then
            -- Hanya respon kalau chat persis "pasukan saya ambil alih"
            if msg:lower() == "pasukan saya ambil alih" then
                pcall(function()
                    channel:SendAsync("Siap laksanakan!")
                end)
            end
        else
            warn("Channel RBXGeneral tidak ditemukan!")
        end
    end
}
