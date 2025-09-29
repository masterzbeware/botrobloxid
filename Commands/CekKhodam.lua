-- CekKhodam.lua
-- Command untuk menampilkan khodam random

return {
    Execute = function(msg, client)
        local vars = _G.BotVars

        -- 🔹 Cek ToggleGames
        if not vars.ToggleGames then
            print("[CekKhodam] ToggleGames tidak aktif, command tidak dijalankan.")
            return
        end

        -- 🔹 Setup cooldowns
        vars.CekKhodamCooldowns = vars.CekKhodamCooldowns or {}
        vars.CekKhodamGlobalCooldown = vars.CekKhodamGlobalCooldown or 0

        local playerCooldowns = vars.CekKhodamCooldowns
        local currentTime = tick()

        -- 🔹 Global cooldown 10 detik
        if currentTime - vars.CekKhodamGlobalCooldown < 10 then
            print("[CekKhodam] Tunggu " .. math.ceil(10 - (currentTime - vars.CekKhodamGlobalCooldown)) .. " detik lagi untuk semua pemain.")
            return
        end

        -- 🔹 Per player cooldown 25 detik
        local lastUsed = playerCooldowns[client.UserId] or 0
        if currentTime - lastUsed < 25 then
            print("[CekKhodam] Tunggu " .. math.ceil(25 - (currentTime - lastUsed)) .. " detik lagi untuk " .. client.Name)
            return
        end

        playerCooldowns[client.UserId] = currentTime
        vars.CekKhodamGlobalCooldown = currentTime

        -- 🔹 List khodam
        local khodams = {
            "Pocong Botak",
            "Tuyul Gendut",
            "Kuntilanak Selfie",
            "Jin Kentut Api",
            "Genderuwo Imut",
            "Pocong Nyeker",
            "Tuyul Pencinta Cilok",
            "Kuyang Kesasar",
            "Pocong Joget Koplo",
            "Jin Botak Licin"
        }

        -- 🔹 Pilih random
        local selected = khodams[math.random(1, #khodams)]

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

        local messageText = client.Name .. " melakukan !cekkhodam! Khodam yang muncul: " .. selected
        pcall(function()
            channel:SendAsync(messageText)
        end)
        print("[CekKhodam] " .. messageText)
    end
}
