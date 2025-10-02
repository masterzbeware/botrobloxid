-- Coinflip.lua
-- Semua pemain bisa menjalankan !coinflip
-- Bot harus ToggleGames aktif
-- Delay global 6 detik (untuk semua pemain)
-- Random hasil: Kepala 🪙 atau Ekor 🎯

local lastFlip = 0 -- global timestamp

return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")

        -- ✅ Cek ToggleGames (harus true)
        if vars.ToggleGames ~= true then
            return
        end

        -- ⏳ Cek cooldown global 6 detik
        local now = os.time()
        if now - lastFlip < 6 then
            -- opsional: kirim pesan "Tunggu sebentar" ke pemain
            return
        end
        lastFlip = now

        -- 🔮 Pilih random
        local hasil, emoji
        if math.random(1, 2) == 1 then
            hasil = "Heads"
            emoji = "🪙"
        else
            hasil = "Tails"
            emoji = "🪙"
        end

        -- 💬 Kirim pesan
        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if channel then
            pcall(function()
                channel:SendAsync(client.Name .. " melempar koin... hasilnya: " .. hasil .. " " .. emoji .. "!")
            end)
        else
            warn("Channel RBXGeneral tidak ditemukan!")
        end
    end
}
