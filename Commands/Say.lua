-- Say.lua
-- Fitur: ketika client mengetik !say {teks}, bot akan mengirim pesan sesuai teks tersebut
-- Contoh: !say Halo semua -> bot akan kirim "Halo semua"

return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")

        -- Ambil isi pesan dari client
        local content = msg.Content or ""
        local sayText = string.match(content, "^!say%s+(.+)$")

        if not sayText or sayText == "" then
            -- Jika client hanya mengetik "!say" tanpa teks tambahan
            local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if channel then
                pcall(function()
                    channel:SendAsync("⚠️ Harap masukkan teks setelah perintah !say")
                end)
            end
            return
        end

        -- Kirim teks ke RBXGeneral
        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if channel then
            pcall(function()
                channel:SendAsync(sayText)
            end)
        else
            warn("Channel RBXGeneral tidak ditemukan!")
        end
    end
}
