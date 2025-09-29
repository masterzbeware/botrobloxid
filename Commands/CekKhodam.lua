-- CekKhodam.lua
-- Command !cekkhodam untuk semua pemain

return {
    Execute = function(msg, client)
        local vars = _G.BotVars

        -- Inisialisasi cooldown
        vars.CekKhodamCooldowns = vars.CekKhodamCooldowns or {}
        vars.CekKhodamLastGlobal = vars.CekKhodamLastGlobal or 0

        local playerCooldowns = vars.CekKhodamCooldowns
        local lastUsed = playerCooldowns[client.UserId] or 0
        local currentTime = tick()

        -- Cek cooldown per pemain (25 detik)
        if currentTime - lastUsed < 25 then
            print("[CekKhodam] Tunggu " .. math.ceil(25 - (currentTime - lastUsed)) .. " detik lagi untuk " .. client.Name)
            return
        end

        -- Cek global cooldown untuk semua pemain (10 detik)
        if currentTime - vars.CekKhodamLastGlobal < 10 then
            print("[CekKhodam] Tunggu " .. math.ceil(10 - (currentTime - vars.CekKhodamLastGlobal)) .. " detik sebelum semua pemain bisa pakai lagi")
            return
        end

        -- Set cooldown
        playerCooldowns[client.UserId] = currentTime
        vars.CekKhodamLastGlobal = currentTime

        -- Ambil channel RBXGeneral
        local TextChatService = game:GetService("TextChatService")
        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if not channel then
            warn("Channel RBXGeneral tidak ditemukan!")
            return
        end

        -- List khodam
        local khodams = {
            "Pocong Botak", "Tuyul Gendut", "Kuntilanak Selfie", "Jin Kentut Api",
            "Genderuwo Imut", "Pocong Nyeker", "Tuyul Pencinta Cilok", "Kuyang Kesasar",
            "Pocong Joget Koplo", "Jin Botak Licin"
        }
        local choice = khodams[math.random(1, #khodams)]

        -- Kirim chat otomatis
        local messageText = client.Name .. " melakukan cek khodam! Hasil: " .. choice
        pcall(function()
            channel:SendAsync(messageText)
        end)
        print("[CekKhodam] " .. messageText)
    end
}
