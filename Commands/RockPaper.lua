-- RockPaper.lua
return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        local player = vars.LocalPlayer

        -- 🔹 Pastikan TextChatService siap
        local TextChatService = game:GetService("TextChatService")
        local channel
        if TextChatService.TextChannels then
            channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        end

        if not channel then
            warn("Channel RBXGeneral tidak ditemukan!")
            return
        end

        -- 🔹 Kirim chat otomatis
        pcall(function()
            channel:SendAsync("Halo ini testing")
        end)

        print("[COMMAND] RockPaper executed by:", client.Name)
    end
}
