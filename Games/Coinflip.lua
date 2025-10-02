-- Coinflip.lua
-- Command: !coinflip
-- Semua pemain bisa menjalankan
-- Hanya bot dengan ToggleGames aktif yang mengeksekusi
-- Delay global 6 detik (untuk semua pemain)
-- Random hasil: Kepala atau Ekor

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
            return
        end
        lastFlip = now

        -- 🔮 Pilih random
        local hasil = math.random(1, 2) == 1 and "Kepala" or "Ekor"

        -- 💬 Kirim pesan
        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if channel then
            pcall(function()
                channel:SendAsync(client.Name .. " melempar koin... hasilnya: " .. hasil .. "!")
            end)
        else
            warn("Channel RBXGeneral tidak ditemukan!")
        end
    end
}
