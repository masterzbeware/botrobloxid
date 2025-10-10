-- Coinflip.lua
-- Semua pemain bisa menjalankan !coinflip
-- Bot harus ToggleGames aktif
-- Delay global 6 detik (untuk semua pemain)
-- Random hasil: Kepala atau Ekor

local lastFlip = 0 -- Global timestamp

return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}

        local TextChatService = game:GetService("TextChatService")
        local channel

        if TextChatService.TextChannels then
            channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        end

        -- Cek apakah mini-game aktif
        if vars.ToggleGames ~= true then
            return
        end

        -- Cek cooldown global (6 detik)
        local now = os.time()
        if now - lastFlip < 6 then
            return
        end
        lastFlip = now

        -- Pilih hasil acak
        local hasil
        if math.random(1, 2) == 1 then
            hasil = "Kepala"
        else
            hasil = "Ekor"
        end

        -- Kirim hasil ke chat
        if channel then
            pcall(function()
                channel:SendAsync(client.Name .. " melempar koin... hasilnya: " .. hasil .. "!")
            end)
        else
            warn("Channel RBXGeneral tidak ditemukan!")
        end
    end
}
