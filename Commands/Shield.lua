local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local function handleShield(msg)
    if msg:match("^!shield") then
        _G.shieldActive = not _G.shieldActive
        _G.followAllowed = false
        _G.rowActive = false
    end
end

local function setupClient(player)
    if player.Name ~= "FiestaGuardVip" then return end
    _G.client = player
    if TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral then
        TextChatService.TextChannels.RBXGeneral.OnIncomingMessage = function(message)
            local sender = Players:GetPlayerByUserId(message.TextSource.UserId)
            if sender and sender == _G.client then handleShield(message.Text) end
        end
    else
        player.Chatted:Connect(handleShield)
    end
end

for _, player in ipairs(Players:GetPlayers()) do setupClient(player) end
Players.PlayerAdded:Connect(setupClient)
