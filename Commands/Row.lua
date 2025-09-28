local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local function handleRow(msg)
    if msg:match("^!row") then
        _G.rowActive = not _G.rowActive
        _G.followAllowed = false
        _G.shieldActive = false
    end
end

local function setupClient(player)
    if player.Name ~= "FiestaGuardVip" then return end
    _G.client = player
    if TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral then
        TextChatService.TextChannels.RBXGeneral.OnIncomingMessage = function(message)
            local sender = Players:GetPlayerByUserId(message.TextSource.UserId)
            if sender and sender == _G.client then handleRow(message.Text) end
        end
    else
        player.Chatted:Connect(handleRow)
    end
end

for _, player in ipairs(Players:GetPlayers()) do setupClient(player) end
Players.PlayerAdded:Connect(setupClient)
