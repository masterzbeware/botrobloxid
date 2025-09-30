-- Rockpaper.lua
-- Command: Semua pemain bisa menjalankan
-- Hanya bot dengan ToggleGameActive aktif yang mengeksekusi
-- Compatible dengan StopGames.lua

return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")

        -- Cek ToggleGameActive, jika false, bot tidak menjalankan
        if vars.ToggleGameActive ~= true then
            return
        end

        -- Random pilihan: Batu, Kertas, Gunting
        local options = { "Batu", "Kertas", "Gunting" }
        local choice = options[math.random(1, #options)]

        -- Kirim hasil ke RBXGeneral
        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if channel then
            pcall(function()
                channel:SendAsync(client.Name .. " memilih: " .. choice .. "!")
            end)
        else
            warn("Channel RBXGeneral tidak ditemukan!")
        end
    end
}
