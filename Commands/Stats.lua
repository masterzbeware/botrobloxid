-- Stats.lua
-- Command !stats untuk menampilkan statistik pemain dengan cooldown

return {
    Execute = function(msg, client)
        local vars = _G.BotVars

        vars.StatsCooldowns = vars.StatsCooldowns or {}
        local playerCooldowns = vars.StatsCooldowns

        local currentTime = tick()
        local lastUsedPlayer = playerCooldowns[client.UserId] or 0
        if currentTime - lastUsedPlayer < 10 then
            print("[Stats] Tunggu " .. math.ceil(10 - (currentTime - lastUsedPlayer)) .. " detik lagi untuk " .. client.Name)
            return
        end

        vars.StatsGlobalCooldown = vars.StatsGlobalCooldown or 0
        if currentTime - vars.StatsGlobalCooldown < 5 then
            print("[Stats] Tunggu " .. math.ceil(5 - (currentTime - vars.StatsGlobalCooldown)) .. " detik lagi untuk semua pemain")
            return
        end

        -- Update cooldown
        playerCooldowns[client.UserId] = currentTime
        vars.StatsGlobalCooldown = currentTime

        vars.Stats = vars.Stats or {}
        local userStats = vars.Stats[client.UserId] or {}
        local rockPaperCount = userStats.RockPaperCount or 0
        local cekKhodamCount = userStats.CekKhodamCount or 0

        local messageText = string.format(
            "📊 Statistik %s:\n- RockPaper dimainkan: %d kali\n- CekKhodam dimainkan: %d kali",
            client.Name, rockPaperCount, cekKhodamCount
        )

        local TextChatService = game:GetService("TextChatService")
        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if not channel then warn("Channel RBXGeneral tidak ditemukan!") return end

        pcall(function() channel:SendAsync(messageText) end)
        print("[Stats] " .. messageText)
    end
}
