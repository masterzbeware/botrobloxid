-- Say.lua
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")

        -- Ambil teks dari pesan setelah perintah !say
        local content = msg.Text or ""
        local args = string.split(content, " ")
        table.remove(args, 1) -- hapus kata pertama "!say"
        local textToSend = table.concat(args, " ")

        -- Jika tidak ada teks tambahan, kirim peringatan
        if textToSend == "" then
            textToSend = "Kamu harus menulis sesuatu setelah !say!"
        end

        -- Kirim chat ke RBXGeneral
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
