-- RockPaper.lua
-- Command !rockpaper untuk semua pemain jika ToggleGames aktif

return {
    Execute = function(msg, client)
        local vars = _G.BotVars

        -- 🔹 TextChatService
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
        local messageText = "Siap laksanakan!"
        pcall(function()
            channel:SendAsync(messageText)
        end)

        print("[RockPaper] " .. client.Name .. " mengeksekusi !rockpaper -> " .. messageText)
    end
}
