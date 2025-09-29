-- CekKhodam.lua
-- Command !cekkhodam dengan cooldown per pemain & global + tracking stats

return {
    Execute = function(msg, client)
        local vars = _G.BotVars

        vars.CekKhodamCooldowns = vars.CekKhodamCooldowns or {}
        local playerCooldowns = vars.CekKhodamCooldowns

        local currentTime = tick()
        local lastUsedPlayer = playerCooldowns[client.UserId] or 0
        if currentTime - lastUsedPlayer < 20 then
            print("[CekKhodam] Tunggu " .. math.ceil(20 - (currentTime - lastUsedPlayer)) .. " detik lagi untuk " .. client.Name)
            return
        end

        vars.CekKhodamGlobalCooldown = vars.CekKhodamGlobalCooldown or 0
        if currentTime - vars.CekKhodamGlobalCooldown < 15 then
            print("[CekKhodam] Tunggu " .. math.ceil(15 - (currentTime - vars.CekKhodamGlobalCooldown)) .. " detik lagi untuk semua pemain")
            return
        end

        -- Update cooldown
        playerCooldowns[client.UserId] = currentTime
        vars.CekKhodamGlobalCooldown = currentTime

        -- Update stats
        vars.Stats = vars.Stats or {}
        vars.Stats[client.UserId] = vars.Stats[client.UserId] or {}
        vars.Stats[client.UserId].CekKhodamCount = (vars.Stats[client.UserId].CekKhodamCount or 0) + 1

        -- Pilihan khodam random
        local khodams = {
            "Pocong Botak", "Cacing Gendut", "Kuntilanak Selfie", "Jin Kentut Api",
            "Genderuwo Imut", "Pocong Nyeker", "Cilok Basi", "Kuyang Kesasar",
            "Pocong Koplo", "Jin Botak Licin"
        }
        local choice = khodams[math.random(1, #khodams)]

        local TextChatService = game:GetService("TextChatService")
        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if not channel then warn("Channel RBXGeneral tidak ditemukan!") return end

        local messageText = client.Name .. " melakukan cek khodam! Hasil: " .. choice
        pcall(function() channel:SendAsync(messageText) end)
        print("[CekKhodam] " .. messageText)
    end
}
