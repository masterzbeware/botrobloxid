-- Stats.lua
-- Command !stats untuk menampilkan UserId dan AccountAge
-- Bisa cek pemain lain dengan !stats {username}

return {
    Execute = function(msg, client)
        local Players = game:GetService("Players")
        local vars = _G.BotVars

        -- Ambil target dari command
        local targetName = msg:match("^!stats%s+(%S+)")
        if not targetName then
            targetName = client.Name -- default ke diri sendiri
        end

        -- Cari pemain
        local targetPlayer = Players:FindFirstChild(targetName)
        if not targetPlayer then
            print("[Stats] Player '" .. targetName .. "' tidak ditemukan!")
            return
        end

        -- Ambil info ID dan AccountAge
        local userId = targetPlayer.UserId
        local accountAge = targetPlayer.AccountAge -- dalam hari

        -- Buat message
        local messageText = string.format(
            "📊 Statistik %s:\n- User ID: %d\n- Account Age (days): %d",
            targetPlayer.Name, userId, accountAge
        )

        -- Kirim chat
        local TextChatService = game:GetService("TextChatService")
        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if not channel then warn("Channel RBXGeneral tidak ditemukan!") return end

        pcall(function() channel:SendAsync(messageText) end)
        print("[Stats] " .. messageText)
    end
}
