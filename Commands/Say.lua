-- Say.lua
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")

        -- Coba ambil teks dari beberapa kemungkinan properti
        local content = msg.Text or msg.Message or msg.Body or ""
        content = tostring(content)

        -- Pastikan isi benar-benar mengandung perintah
        if not string.find(content, "!say") then
            warn("Pesan tidak mengandung perintah !say:", content)
            return
        end

        -- Pisahkan teks setelah perintah !say
        local args = string.split(content, " ")
        table.remove(args, 1) -- hapus kata pertama "!say"
        local textToSend = table.concat(args, " "):gsub("^%s+", "") -- hapus spasi di depan

        -- Jika tidak ada teks tambahan
        if textToSend == "" then
            textToSend = "Kamu harus menulis sesuatu setelah !say!"
        end

        -- Kirim ke RBXGeneral (atau channel lain jika mau)
        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if channel then
            pcall(function()
                channel:SendAsync(textToSend)
            end)
        else
            warn("Channel RBXGeneral tidak ditemukan!")
        end
    end
}
