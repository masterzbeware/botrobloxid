-- RockPaper.lua
-- Command !rockpaper dengan cooldown per pemain dan global + tracking untuk stats

return {
    Execute = function(msg, client)
        local vars = _G.BotVars

        -- 🔹 Setup table cooldown per pemain
        vars.RockPaperCooldowns = vars.RockPaperCooldowns or {}
        local playerCooldowns = vars.RockPaperCooldowns

        local lastUsedPlayer = playerCooldowns[client.UserId] or 0
        local currentTime = tick()
        if currentTime - lastUsedPlayer < 10 then
            print("[RockPaper] Tunggu " .. math.ceil(10 - (currentTime - lastUsedPlayer)) .. " detik lagi untuk " .. client.Name)
            return
        end

        -- 🔹 Setup global cooldown
        vars.RockPaperGlobalCooldown = vars.RockPaperGlobalCooldown or 0
        if currentTime - vars.RockPaperGlobalCooldown < 5 then
            print("[RockPaper] Tunggu " .. math.ceil(10 - (currentTime - vars.RockPaperGlobalCooldown)) .. " detik lagi untuk semua pemain")
            return
        end

        -- 🔹 Update cooldown
        playerCooldowns[client.UserId] = currentTime
        vars.RockPaperGlobalCooldown = currentTime

        -- 🔹 Update jumlah main untuk stats
        vars.Stats = vars.Stats or {}
        vars.Stats[client.UserId] = vars.Stats[client.UserId] or {}
        vars.Stats[client.UserId].RockPaperCount = (vars.Stats[client.UserId].RockPaperCount or 0) + 1

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
        local messageText = client.Name .. " memulai RockPaper! | Saya memilih: " .. choice
        pcall(function()
            channel:SendAsync(messageText)
        end)

        print("[RockPaper] " .. messageText)
    end
}
