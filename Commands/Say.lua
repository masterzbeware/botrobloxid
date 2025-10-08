-- Say.lua
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")

        -- Ambil channel yang tersedia
        local channels = TextChatService:WaitForChild("TextChannels")
        local channel = channels:FindFirstChild("RBXGeneral") or channels:FindFirstChildOfClass("TextChannel")

        if not channel then
            warn("Channel chat tidak ditemukan!")
            return
        end

        -- Ambil teks setelah perintah !say
        local content = msg.Content or msg
        local sayText = content:match("^!say%s+(.+)$")
        if not sayText or sayText == "" then return end

        -- ✅ Kirim pesan sebagai system message (aman dari server)
        pcall(function()
            channel:DisplaySystemMessage(sayText)
        end)
    end
}
