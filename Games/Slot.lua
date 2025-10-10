-- Slot.lua
-- Semua pemain bisa menjalankan !slot
-- Bot harus ToggleGames aktif
-- Delay global 6 detik (untuk semua pemain)
-- Mesin slot sederhana dengan emoji

local lastSlot = 0 -- Global timestamp

return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}

        local TextChatService = game:GetService("TextChatService")
        local channel

        if TextChatService.TextChannels then
            channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        end

        -- Pastikan fitur mini-game aktif
        if vars.ToggleGames ~= true then
            return
        end

        -- Cek cooldown global (6 detik)
        local now = os.time()
        if now - lastSlot < 6 then
            return
        end
        lastSlot = now

        -- Daftar simbol slot
        local symbols = { "🍒", "🍋", "⭐", "🍀", "🔔", "💎" }

        -- Ambil 3 simbol acak
        local s1 = symbols[math.random(1, #symbols)]
        local s2 = symbols[math.random(1, #symbols)]
        local s3 = symbols[math.random(1, #symbols)]

        -- Tentukan hasil
        local hasil
        if s1 == s2 and s2 == s3 then
            hasil = "JACKPOT! Semua simbol sama!"
        elseif s1 == s2 or s2 == s3 or s1 == s3 then
            hasil = "Lumayan! Dua simbol sama!"
        else
            hasil = "Kalah! Coba lagi!"
        end

        -- Kirim hasil ke RBXGeneral
        if channel then
            pcall(function()
                channel:SendAsync(client.Name .. " memutar mesin slot...")
                task.wait(2)
                channel:SendAsync("| " .. s1 .. " | " .. s2 .. " | " .. s3 .. " |")
                task.wait(1)
                channel:SendAsync("Hasil: " .. hasil)
            end)
        else
            warn("Channel RBXGeneral tidak ditemukan!")
        end
    end
}
