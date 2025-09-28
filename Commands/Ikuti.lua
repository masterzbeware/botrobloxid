local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local localPlayer = Players.LocalPlayer

local function handleIkuti(msg)
    if msg:match("^!ikuti") then
        _G.followAllowed = true
        _G.shieldActive = false
        _G.rowActive = false
        _G.currentFormasiTarget = _G.client
    end
end

local function setupClient(player)
    if player.Name ~= "FiestaGuardVip" then return end
    _G.client = player

    if TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral then
        TextChatService.TextChannels.RBXGeneral.OnIncomingMessage = function(message)
            local sender = Players:GetPlayerByUserId(message.TextSource.UserId)
            if sender and sender == _G.client then handleIkuti(message.Text) end
        end
    else
        player.Chatted:Connect(handleIkuti)
    end
end

for _, player in ipairs(Players:GetPlayers()) do setupClient(player) end
Players.PlayerAdded:Connect(setupClient)
