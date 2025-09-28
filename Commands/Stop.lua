-- stop.lua
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local TextChatService = game:GetService("TextChatService")

local function runStopCommand()
    _G.followAllowed = false
    _G.shieldActive = false
    _G.rowActive = false
    _G.currentFormasiTarget = nil
    _G.moving = false
end

local function handleStop(msg)
    if msg:match("^!stop") then
        runStopCommand()
    end
end

local function setupClient(player)
    if player.Name ~= "FiestaGuardVip" then return end
    _G.client = player

    if TextChatService and TextChatService.TextChannels then
        local generalChannel = TextChatService.TextChannels.RBXGeneral
        if generalChannel then
            generalChannel.OnIncomingMessage = function(message)
                local senderUserId = message.TextSource and message.TextSource.UserId
                local sender = senderUserId and Players:GetPlayerByUserId(senderUserId)
                if sender and sender == _G.client then
                    handleStop(message.Text)
                end
            end
        end
    else
        player.Chatted:Connect(handleStop)
    end
end

for _, player in ipairs(Players:GetPlayers()) do setupClient(player) end
Players.PlayerAdded:Connect(setupClient)
