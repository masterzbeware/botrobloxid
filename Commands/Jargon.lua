-- Jargon.lua
return {
    Execute = function(msg, client)
        local TextChatService = game:GetService("TextChatService")
        local channel = TextChatService.TextChannels and TextChatService.TextChannels:FindFirstChild("RBXGeneral")

        -- Hanya merespons pesan "!jargon"
        if msg:lower() == "!jargon" and channel then
            pcall(function()
                channel:SendAsync("JAYA JAYA JAYA")
            end)
        end
    end
}
