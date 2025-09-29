-- RockPaper.lua
return {
    Execute = function(msg, client)
        local vars = _G.BotVars

        -- 🔹 Delay 20 detik per pemain
        local playerCooldowns = vars.RockPaperCooldowns or {}
        vars.RockPaperCooldowns = playerCooldowns

        local lastUsed = playerCooldowns[client.UserId] or 0
        local currentTime = tick()
        if currentTime - lastUsed < 20 then
            print("[RockPaper] Tunggu " .. math.ceil(20 - (currentTime - lastUsed)) .. " detik lagi untuk " .. client.Name)
            return
        end

        playerCooldowns[client.UserId] = currentTime

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

        -- 🔹 Pilihan random
        local choices = { "Batu", "Kertas", "Gunting" }
        local choice = choices[math.random(1, #choices)]

        -- 🔹 Kirim chat otomatis
        local messageText = client.Name .. " memulai RockPaper! Bot memilih: " .. choice
        pcall(function()
            channel:SendAsync(messageText)
        end)
        print("[RockPaper] " .. messageText)

        -- 🔹 Set flag RockPaperMode agar Shield/Sync/Row tidak bisa digunakan
        vars.RockPaperModeActive = true
        print("[RockPaper] RockPaper Mode aktif. Shield, Sync, dan Row sementara dinonaktifkan.")

        -- 🔹 Reset mode setelah 5 detik
        task.delay(5, function()
            vars.RockPaperModeActive = false
            print("[RockPaper] RockPaper Mode selesai. Shield, Sync, Row kembali aktif.")
        end)
    end
}
