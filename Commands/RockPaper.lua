-- RockPaper.lua
return {
    Execute = function(msg, client)
        local vars = _G.BotVars

        -- 🔹 Cek toggle RockPaper
        if vars.RockPaperEnabled == false then
            print("[RockPaper] Fitur RockPaper sedang OFF, tidak mengeksekusi command.")
            return
        end

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
    end
}
