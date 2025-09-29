-- Stats.lua
-- Command !stats untuk menampilkan statistik pemain dengan cooldown

return {
    Execute = function(msg, client)
        local vars = _G.BotVars

        -- 🔹 Setup cooldown per pemain
        vars.StatsCooldowns = vars.StatsCooldowns or {}
        local playerCooldowns = vars.StatsCooldowns

        local lastUsedPlayer = playerCooldowns[client.UserId] or 0
        local currentTime = tick()
        if currentTime - lastUsedPlayer < 10 then
            print("[Stats] Tunggu " .. math.ceil(10 - (currentTime - lastUsedPlayer)) .. " detik lagi untuk " .. client.Name)
            return
        end

        -- 🔹 Setup global cooldown
        vars.StatsGlobalCooldown = vars.StatsGlobalCooldown or 0
        if currentTime - vars.StatsGlobalCooldown < 5 then
            print("[Stats] Tunggu " .. math.ceil(5 - (currentTime - vars.StatsGlobalCooldown)) .. " detik lagi untuk semua pemain")
            return
        end

        -- 🔹 Update cooldown
        playerCooldowns[client.UserId] = currentTime
        vars.StatsGlobalCooldown = currentTime

        -- 🔹 Ambil statistik pemain
        vars.Stats = vars.Stats or {}
        local userStats = vars.Stats[client.UserId] or {}
        local rockPaperCount = userStats.RockPaperCount or 0
        local cekKhodamCount = userStats.CekKhodamCount or 0

        -- 🔹 Format pesan
        local messageText = string.format(
            "📊 Statistik %s:\n- RockPaper dimainkan: %d kali\n- CekKhodam dimainkan: %d kali",
            client.Name, rockPaperCount, cekKhodamCount
        )

        -- 🔹 Kirim ke TextChatService
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
