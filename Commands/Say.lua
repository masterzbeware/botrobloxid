-- Pushup.lua
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")

        -- Ambil teks dari pesan setelah perintah !pushup
        -- Misalnya pesan: "!pushup ayo latihan" → hasil: "ayo latihan"
        local content = msg.Text or ""
        local args = string.split(content, " ")
        table.remove(args, 1) -- hapus kata pertama "!pushup"
        local textToSend = table.concat(args, " ")

        -- Jika tidak ada teks tambahan, pakai default
        if textToSend == "" then
            textToSend = "Siap laksanakan!"
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
