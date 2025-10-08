-- Say.lua
return {
    Execute = function(msg, client)
        local vars = _G.BotVars or {}
        local TextChatService = vars.TextChatService or game:GetService("TextChatService")

        -- Pastikan channel siap
        local channels = TextChatService:WaitForChild("TextChannels")
        local channel = channels:FindFirstChild("RBXGeneral") or channels:FindFirstChildOfClass("TextChannel")

        if not channel then
            warn("Channel chat tidak ditemukan!")
            return
        end

        local content = msg.Content or ""
        local sayText = content:match("^!say%s+(.+)$")
        if not sayText or sayText == "" then return end

        -- Gunakan DisplaySystemMessage agar bisa dari server juga
        pcall(function()
            channel:DisplaySystemMessage(sayText)
        end)
    end
}
