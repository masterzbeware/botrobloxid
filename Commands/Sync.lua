local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local function handleSync(msg)
    local targetName = msg:match("^!sync%s+(.+)")
    if targetName then
        local found = nil
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.DisplayName:lower() == targetName:lower() or plr.Name:lower() == targetName:lower() then
                found = plr
                break
            end
        end
        if found and ReplicatedStorage:FindFirstChild("Events") and ReplicatedStorage.Events:FindFirstChild("RequestSync") then
            ReplicatedStorage.Events.RequestSync:FireServer(found)
        end
    end
end

local function setupClient(player)
    if player.Name ~= "FiestaGuardVip" then return end
    _G.client = player
    if TextChatService.TextChannels and TextChatService.TextChannels.RBXGeneral then
        TextChatService.TextChannels.RBXGeneral.OnIncomingMessage = function(message)
            local sender = Players:GetPlayerByUserId(message.TextSource.UserId)
            if sender and sender == _G.client then handleSync(message.Text) end
        end
    else
        player.Chatted:Connect(handleSync)
    end
end

for _, player in ipairs(Players:GetPlayers()) do setupClient(player) end
Players.PlayerAdded:Connect(setupClient)
