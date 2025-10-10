return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local TextChatService = game:GetService("TextChatService")
        local channel

        if TextChatService.TextChannels then
            channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        end

        local content = msg.Text or msg.Message or msg.Body or msg.Content or tostring(msg) or ""
        local args = string.split(content, " ")

        if args[1] ~= "!say" then
            return
        end

        table.remove(args, 1)
        local textToSend = table.concat(args, " "):gsub("^%s+", "")

        if textToSend == "" then
            textToSend = "Kamu harus menulis sesuatu setelah !say!"
        end

        if channel then
            pcall(function()
                channel:SendAsync(textToSend)
            end)
        else
            warn("Channel RBXGeneral tidak ditemukan!")
        end
    end
}
