-- Text.lua
-- Mengirim pesan otomatis berulang di channel "RBXGeneral"
-- Kompatibel dengan Stop.lua (loop bisa dihentikan lewat vars.TextLoopActive = false)

return {
    Execute = function(msg, client)
        -- Gunakan variabel global bersama
        _G.BotVars = _G.BotVars or {}
        local vars = _G.BotVars

        local TextChatService = game:GetService("TextChatService")
        local channel

        -- Cek apakah channel "RBXGeneral" tersedia
        if TextChatService.TextChannels then
            channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        end

        if not channel then
            warn("[Text] Channel RBXGeneral tidak ditemukan!")
            return
        end

        -- 🔹 Jika loop sudah aktif, jangan mulai lagi
        if vars.TextLoopActive then
            warn("[Text] Loop text sudah berjalan! Gunakan !stop untuk menghentikan.")
            return
        end

        -- Tandai loop aktif
        vars.TextLoopActive = true
        print("[Text] Loop text otomatis dimulai oleh:", client and client.Name or "Unknown")

        -- 🔹 Daftar pasangan teks (1 set = 2 pesan berurutan)
        local textSets = {
            {
                "Kamu butuh jasa promosi untuk clan/group? kami siap membantu!",
                "Silakan dm kami di dc 'FiestaGuard'"
            },
            {
                "Kamu butuh jasa bodyguard? kami siap membantu!",
                "Silakan dm kami di dc 'FiestaGuard'"
            },
        }

        -- 🔹 Jalankan pengiriman pesan berulang
        task.spawn(function()
            while vars.TextLoopActive and channel do
                -- Pilih set acak
                local selectedSet = textSets[math.random(1, #textSets)]

                -- Kirim pesan satu per satu
                for _, text in ipairs(selectedSet) do
                    if not vars.TextLoopActive then
                        print("[Text] Loop dihentikan sebelum pengiriman pesan berikutnya.")
                        return
                    end

                    pcall(function()
                        channel:SendAsync(text)
                    end)

                    task.wait(10) -- jeda antar pesan
                end

                -- Jeda sebelum memulai set baru
                local delayTime = 23
                for i = 1, delayTime do
                    if not vars.TextLoopActive then
                        print("[Text] Loop text berhenti saat menunggu delay.")
                        return
                    end
                    task.wait(1)
                end
            end

            print("[Text] Loop text otomatis berhenti sepenuhnya.")
        end)
    end
}
