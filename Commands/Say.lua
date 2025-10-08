-- Say.lua
-- Ketika client mengetik !say {teks}, bot akan kirim teks tersebut ke RBXGeneral

return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")

        -- Ambil isi pesan dari berbagai kemungkinan properti
        local content = msg.Content or msg.Text or msg.Message or ""
        content = string.trim and string.trim(content) or content:match("^%s*(.-)%s*$") -- hapus spasi ekstra

        -- Ambil teks setelah "!say "
        local sayText = content:match("^!say%s+(.+)$")

        if not sayText or sayText == "" then
            warn("Tidak ada teks yang dimasukkan untuk !say | content:", content)
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
