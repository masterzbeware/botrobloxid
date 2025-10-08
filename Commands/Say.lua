-- Say.lua
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")

        -- Coba ambil teks dari berbagai kemungkinan properti
        local content = ""
        if typeof(msg) == "table" then
            content = msg.Text or msg.Message or msg.Body or msg.Content or ""
        elseif typeof(msg) == "Instance" then
            -- Kadang msg adalah instance TextChatMessage
            content = msg.Text or msg:FindFirstChild("Text") or ""
        end

        content = tostring(content)

        print("DEBUG | Pesan diterima:", content)

        -- Ambil teks setelah !say
        local args = string.split(content, " ")
        if args[1] ~= "!say" then
            warn("Pesan tidak mengandung perintah !say:", content)
            return
        end

        table.remove(args, 1)
        local textToSend = table.concat(args, " "):gsub("^%s+", "")

        if textToSend == "" then
            textToSend = "Kamu harus menulis sesuatu setelah !say!"
        end

        -- Kirim ke RBXGeneral
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
