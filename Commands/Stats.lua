-- Stats.lua
-- Command !stats untuk menampilkan statistik pemain

return {
    Execute = function(msg, client)
        local vars = _G.BotVars

        vars.Stats = vars.Stats or {}  -- pastikan tabel Stats ada
        local userStats = vars.Stats[client.UserId] or {}

        local rockPaperCount = userStats.RockPaperCount or 0
        local cekKhodamCount = userStats.CekKhodamCount or 0

        -- Tampilkan pesan ke chat
        local messageText = string.format(
            "📊 Statistik %s:\n- RockPaper dimainkan: %d kali\n- CekKhodam dimainkan: %d kali",
            client.Name, rockPaperCount, cekKhodamCount
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
