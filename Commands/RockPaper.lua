-- RockPaper.lua
return {
    Execute = function(msg, client)
        local vars = _G.BotVars
        local TextChatService = game:GetService("TextChatService")
        local channel
        if TextChatService.TextChannels then
            channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        end

        if not channel then
            warn("Channel RBXGeneral tidak ditemukan!")
            return
        end

        -- 🔹 Pilihan random
        local choices = { "Batu", "Kertas", "Gunting" }
        local choice = choices[math.random(1, #choices)]

        -- 🔹 Kirim chat otomatis
        local messageText = client.Name .. " memulai RockPaper! Bot memilih: " .. choice
        pcall(function()
            channel:SendAsync(messageText)
        end)

        print("[RockPaper] " .. messageText)
    end
}
