-- Rockpaper.lua
-- Command: Semua pemain bisa menjalankan, tapi hanya bot dengan ToggleGames aktif yang mengeksekusi

return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")

        -- Cek ToggleGames sebelum bot mengeksekusi
        if vars.ToggleGameActive ~= true then
            -- ToggleGames mati, bot tidak mengirim pesan
            return
        end

        -- Mengirim chat ke RBXGeneral
        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if channel then
            pcall(function()
                channel:SendAsync("Siap laksanakan!")
            end)
        else
            warn("Channel RBXGeneral tidak ditemukan!")
        end
    end
}
