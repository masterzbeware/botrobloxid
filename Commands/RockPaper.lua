-- RockPaper.lua
-- Command !rockpaper dengan cooldown per pemain & global + tracking stats + emoji

return {
    Execute = function(msg, client)
        local vars = _G.BotVars

        vars.RockPaperCooldowns = vars.RockPaperCooldowns or {}
        local playerCooldowns = vars.RockPaperCooldowns

        local currentTime = tick()
        local lastUsedPlayer = playerCooldowns[client.UserId] or 0
        if currentTime - lastUsedPlayer < 10 then
            print("[RockPaper] Tunggu " .. math.ceil(10 - (currentTime - lastUsedPlayer)) .. " detik lagi untuk " .. client.Name)
            return
        end

        vars.RockPaperGlobalCooldown = vars.RockPaperGlobalCooldown or 0
        if currentTime - vars.RockPaperGlobalCooldown < 5 then
            print("[RockPaper] Tunggu " .. math.ceil(5 - (currentTime - vars.RockPaperGlobalCooldown)) .. " detik lagi untuk semua pemain")
            return
        end

        -- Update cooldown
        playerCooldowns[client.UserId] = currentTime
        vars.RockPaperGlobalCooldown = currentTime

        -- Update stats
        vars.Stats = vars.Stats or {}
        vars.Stats[client.UserId] = vars.Stats[client.UserId] or {}
        vars.Stats[client.UserId].RockPaperCount = (vars.Stats[client.UserId].RockPaperCount or 0) + 1

        -- Pilihan random dengan emoji
        local choices = {
            {Name="Batu", Emoji="✊"},
            {Name="Kertas", Emoji="✋"},
            {Name="Gunting", Emoji="✌️"}
        }
        local choice = choices[math.random(1, #choices)]

        -- Kirim chat
        local TextChatService = game:GetService("TextChatService")
        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if not channel then warn("Channel RBXGeneral tidak ditemukan!") return end

        local messageText = string.format("%s memulai RockPaper! Saya memilih: %s %s", client.Name, choice.Name, choice.Emoji)
        pcall(function() channel:SendAsync(messageText) end)
        print("[RockPaper] " .. messageText)
    end
}
