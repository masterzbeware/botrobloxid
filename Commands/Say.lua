-- Say.lua
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")

        -- Ambil isi pesan
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

        -- Bot ikut kirim chat (seolah bot yang bicara)
        local generalChannel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if generalChannel then
            pcall(function()
                generalChannel:SendAsync(textToSend)
            end)
        else
            warn("Channel RBXGeneral tidak ditemukan!")
        end
    end
}
