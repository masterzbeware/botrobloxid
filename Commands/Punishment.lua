local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")

local function onMessage(msg, sender)
    if msg:lower() == "!pushup" then
        local channel = TextChatService.TextChannels:WaitForChild("RBXGeneral", 10)
        if channel then
            pcall(function()
                channel:SendAsync("Siap laksanakan!")
            end)
        end
    end
end

-- Listener sementara untuk test
Players.PlayerAdded:Connect(function(plr)
    plr.Chatted:Connect(function(msg)
        onMessage(msg, plr)
    end)
end)

-- Test untuk player lokal
Players.LocalPlayer.Chatted:Connect(function(msg)
    onMessage(msg, Players.LocalPlayer)
end)
