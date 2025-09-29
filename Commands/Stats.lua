-- Stats.lua
-- Command !stats untuk menampilkan statistik pemain

return {
    Execute = function(msg, client)
        local vars = _G.BotVars

        -- Setup table stats per pemain
        vars.PlayerStats = vars.PlayerStats or {}
        local stats = vars.PlayerStats[client.UserId] or { RockPaper = 0, CekKhodam = 0 }
        vars.PlayerStats[client.UserId] = stats

        -- Jika memanggil sendiri, tampilkan stats mereka
        local messageText = string.format(
            "📊 Statistik %s:\n- RockPaper dimainkan: %d kali\n- CekKhodam dimainkan: %d kali",
            client.Name, stats.RockPaper, stats.CekKhodam
        )

        -- Kirim ke TextChatService
        local TextChatService = game:GetService("TextChatService")
        local channel
        if TextChatService.TextChannels then
            channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        end

        if not channel then
            warn("Channel RBXGeneral tidak ditemukan!")
            return
        end

        pcall(function()
            channel:SendAsync(messageText)
        end)
        print("[Stats] " .. messageText)
    end
}
