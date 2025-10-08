-- Say.lua
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")

        -- Ambil channel RBXGeneral
        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if not channel then
            warn("Channel RBXGeneral tidak ditemukan!")
            return
        end

        -- Ambil teks setelah perintah !say
        local content = msg.Content or ""
        local sayText = content:match("^!say%s+(.+)$")

        if sayText and sayText ~= "" then
            pcall(function()
                channel:SendAsync(sayText)
            end)
        end
    end
}
